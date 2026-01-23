require "json"
require "net/http"
require "uri"

class TidalService
  AUTH_URL = "https://auth.tidal.com/v1/oauth2/token"
  API_BASE_URL = "https://api.tidal.com/v1"
  PLAYLIST_BASE_URL = "https://tidal.com/browse/playlist"

  def initialize
    @client_id = ENV.fetch("TIDAL_CLIENT_ID", nil)
    @client_secret = ENV.fetch("TIDAL_CLIENT_SECRET", nil)
    @user_id = ENV.fetch("TIDAL_USER_ID", nil)
    @country_code = ENV.fetch("TIDAL_COUNTRY_CODE", "US")
    @auth_url = ENV.fetch("TIDAL_AUTH_URL", AUTH_URL)
    @api_base_url = ENV.fetch("TIDAL_API_BASE_URL", API_BASE_URL)
    @playlist_base_url = ENV.fetch("TIDAL_PLAYLIST_BASE_URL", PLAYLIST_BASE_URL)
    @scope = ENV.fetch("TIDAL_SCOPE", nil)
  end

  def create_playlist(name:, tracks:)
    return nil if tracks.empty?

    token = access_token
    return nil unless token

    playlist_id = create_remote_playlist(name, token)
    return nil unless playlist_id

    add_tracks_to_playlist(playlist_id, tracks, token)

    "#{@playlist_base_url}/#{playlist_id}"
  end

  def search_track(song_title:, artist:)
    # TODO: Implement track search
    # Returns tidal_id
    { tidal_id: nil }
  end

  private

  def access_token
    return @access_token if @access_token
    return nil if @client_id.blank? || @client_secret.blank?

    uri = URI.parse(@auth_url)
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request.set_form_data(token_request_payload)

    response = perform_request(uri, request)
    return nil unless response&.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    @access_token = body["access_token"]
  rescue JSON::ParserError => error
    Rails.logger.warn("Tidal auth parse error: #{error.message}")
    nil
  end

  def token_request_payload
    payload = {
      "client_id" => @client_id,
      "client_secret" => @client_secret,
      "grant_type" => "client_credentials"
    }
    payload["scope"] = @scope if @scope.present?
    payload
  end

  def create_remote_playlist(name, token)
    return nil if @user_id.blank?

    uri = build_api_uri("/users/#{@user_id}/playlists", { "countryCode" => @country_code })
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = { "title" => name }.to_json

    response = perform_request(uri, request)
    return nil unless response&.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    body["id"] || body["uuid"]
  rescue JSON::ParserError => error
    Rails.logger.warn("Tidal playlist parse error: #{error.message}")
    nil
  end

  def add_tracks_to_playlist(playlist_id, tracks, token)
    uri = build_api_uri("/playlists/#{playlist_id}/items", {
      "countryCode" => @country_code,
      "trackIds" => tracks.join(",")
    })
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/json"

    response = perform_request(uri, request)
    return true if response&.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("Tidal add tracks failed: #{response&.code} #{response&.body}")
    false
  end

  def build_api_uri(path, params = {})
    uri = URI.join(@api_base_url, path)
    uri.query = URI.encode_www_form(params) if params.present?
    uri
  end

  def perform_request(uri, request)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  rescue StandardError => error
    Rails.logger.warn("Tidal request error: #{error.message}")
    nil
  end
end
