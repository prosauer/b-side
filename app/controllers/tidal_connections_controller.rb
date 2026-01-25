# app/controllers/tidal_connections_controller.rb
require "net/http"
require "uri"
require "json"
require "securerandom"
require "digest"
require "base64"

def pkce_verifier
  SecureRandom.urlsafe_base64(64).delete("=")
end

def pkce_challenge(verifier)
  digest = Digest::SHA256.digest(verifier)
  Base64.urlsafe_encode64(digest).delete("=")
end

class TidalConnectionsController < ApplicationController
  before_action :authenticate_user!

  AUTHORIZE_URL = "https://login.tidal.com/authorize"
  TOKEN_URL     = "https://auth.tidal.com/v1/oauth2/token"

  # Pick scopes you need (playlist creation needs playlists.write; reading user info might need user.read)
  SCOPES = %w[user.read playback playlists.write playlists.read].freeze

  def connect
    client_id = ENV["TIDAL_CLIENT_ID"]
    raise "Missing TIDAL_CLIENT_ID" if client_id.blank?

    redirect_uri = tidal_connections_callback_url

    state = SecureRandom.hex(24)
    code_verifier  = pkce_verifier
    code_challenge = pkce_challenge(code_verifier)

    # store for callback validation/exchange
    session[:tidal_oauth_state] = state
    session[:tidal_code_verifier] = code_verifier

    uri = URI(AUTHORIZE_URL)
    uri.query = URI.encode_www_form(
      response_type: "code",
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: SCOPES.join(" "),
      code_challenge_method: "S256",
      code_challenge: code_challenge,
      state: state
    )

    redirect_to uri.to_s, allow_other_host: true
  end

  def callback
    # handle denial/errors
    if params[:error].present?
      return redirect_to root_path, alert: "TIDAL authorization failed: #{params[:error_description] || params[:error]}"
    end

    expected_state = session.delete(:tidal_oauth_state)
    code_verifier  = session.delete(:tidal_code_verifier)

    if expected_state.blank? || params[:state] != expected_state
      return redirect_to root_path, alert: "TIDAL authorization failed: invalid state"
    end

    code = params[:code].to_s
    return redirect_to root_path, alert: "TIDAL authorization failed: missing code" if code.blank?

    token_payload = exchange_code_for_token!(
      code: code,
      code_verifier: code_verifier,
      redirect_uri: tidal_connections_callback_url
    )
    current_user.tidal_account&.destroy
    current_user.create_tidal_account!(
      access_token: token_payload["access_token"],
      refresh_token: token_payload["refresh_token"],
      expires_at: token_payload["expires_in"] ? Time.current + token_payload["expires_in"].to_i.seconds : nil
    )

    redirect_to root_path, notice: "Connected your TIDAL account!"
  end

  private

  def exchange_code_for_token!(code:, code_verifier:, redirect_uri:)
    client_id = ENV["TIDAL_CLIENT_ID"]
    raise "Missing TIDAL_CLIENT_ID" if client_id.blank?
    raise "Missing code_verifier" if code_verifier.blank?

    uri = URI(TOKEN_URL)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = URI.encode_www_form(
      grant_type: "authorization_code",
      client_id: client_id,
      code: code,
      redirect_uri: redirect_uri,
      code_verifier: code_verifier
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "TIDAL token exchange failed (#{res.code}): #{res.body}"
    end

    JSON.parse(res.body)
  end
end
