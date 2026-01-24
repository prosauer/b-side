require "base64"
require "json"
require "net/http"

class TidalService
  TIDAL_TOKEN_URL = "https://auth.tidal.com/v1/oauth2/token"
  TIDAL_SEARCH_URL = "https://openapi.tidal.com/v2/search"

  def initialize(client_id: ENV["TIDAL_CLIENT_ID"], client_secret: ENV["TIDAL_CLIENT_SECRET"])
    @client_id = client_id
    @client_secret = client_secret
  end

  def create_playlist(name:, tracks:)
    # TODO: Implement Tidal playlist creation
    # This would use the Tidal API to:
    # 1. Authenticate
    # 2. Create a playlist
    # 3. Add tracks using tidal_id from submissions
    # Returns playlist URL
    nil
  end

  def search_tracks(query:, limit: 8)
    return [] if query.blank? || @client_id.blank? || @client_secret.blank?

    token = access_token
    return [] if token.blank?

    uri = URI(TIDAL_SEARCH_URL)
    uri.query = URI.encode_www_form(query: query, types: "TRACKS", limit: limit)

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    return [] unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body) rescue {}
    parse_tracks(payload)
  rescue StandardError => e
    Rails.logger.warn("Tidal search failed: #{e.message}")
    []
  end

  private

  def access_token
    @access_token ||= begin
      return if @client_id.blank? || @client_secret.blank?

      uri = URI(TIDAL_TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
      request.body = URI.encode_www_form(grant_type: "client_credentials")

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      body = JSON.parse(response.body) rescue {}
      body["access_token"]
    end
  end

  def parse_tracks(payload)
    if payload["data"].is_a?(Array)
      payload["data"].filter_map { |item| parse_v2_track(item) }
    elsif payload.dig("tracks", "items").is_a?(Array)
      payload["tracks"]["items"].filter_map { |item| parse_v1_track(item) }
    else
      []
    end
  end

  def parse_v2_track(item)
    attrs = item["attributes"] || {}
    id = item["id"] || attrs["id"]
    title = attrs["title"] || attrs["name"]
    artist = attrs.dig("artists", 0, "name") || attrs.dig("artist", "name")
    album = attrs.dig("album", "title") || attrs["albumTitle"] || attrs.dig("album", "name")
    image_url = extract_image_url(attrs)
    url = attrs.dig("externalLinks", "tidal", "href") || attrs["url"] || "https://tidal.com/browse/track/#{id}"

    return unless id && title && artist

    {
      id: id.to_s,
      title: title,
      artist: artist,
      album: album,
      image_url: image_url,
      url: url
    }
  end

  def extract_image_url(attrs)
    links = attrs.dig("album", "imageLinks") || attrs["imageLinks"]

    if links.is_a?(Array)
      links.first&.dig("href")
    elsif links.is_a?(Hash)
      links.values.first
    end
  end

  def parse_v1_track(item)
    id = item["id"]
    title = item["title"]
    artist = item.dig("artist", "name")
    album = item.dig("album", "title")
    cover = item.dig("album", "cover")
    image_url = cover ? tidal_cover_url(cover) : nil
    url = "https://tidal.com/browse/track/#{id}"

    return unless id && title && artist

    {
      id: id.to_s,
      title: title,
      artist: artist,
      album: album,
      image_url: image_url,
      url: url
    }
  end

  def tidal_cover_url(cover)
    normalized = cover.tr("-", "/")
    "https://resources.tidal.com/images/#{normalized}/640x640.jpg"
  end
end
