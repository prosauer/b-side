# frozen_string_literal: true

require "base64"
require "json"
require "net/http"
require "uri"

class TidalService
  TIDAL_TOKEN_URL = "https://auth.tidal.com/v1/oauth2/token"

  TIDAL_SEARCH_RESULTS_URL = "https://openapi.tidal.com/v2/searchResults"
  TIDAL_TRACKS_URL         = "https://openapi.tidal.com/v2/tracks"

  DEFAULT_COUNTRY_CODE = ENV.fetch("TIDAL_COUNTRY_CODE", "DE")
  MAX_TRACK_IDS_PER_BATCH = 20

  def initialize(client_id: ENV["TIDAL_CLIENT_ID"], client_secret: ENV["TIDAL_CLIENT_SECRET"])
    @client_id = client_id
    @client_secret = client_secret
  end

  def create_playlist(name:, tracks:)
    # TODO: Implement Tidal playlist creation
    nil
  end

  # Search for tracks via v2:
  # 1) GET /v2/searchResults/{query}/relationships/tracks -> track ids
  # 2) GET /v2/tracks with filter[id]=... (repeated) + include=artists,albums
  # 3) Parse artist/album from relationships + included
  def search_tracks(query:, limit: 8, country_code: DEFAULT_COUNTRY_CODE)
    return [] if query.blank? || @client_id.blank? || @client_secret.blank?

    token = access_token
    return [] if token.blank?

    track_ids = fetch_search_track_ids(token, query, limit: limit, country_code: country_code)
    return [] if track_ids.empty?

    results = []
    track_ids.each_slice(MAX_TRACK_IDS_PER_BATCH) do |batch|
      results.concat(fetch_tracks_by_ids(token, batch, country_code: country_code))
      break if results.size >= limit
    end

    results.first(limit)
  rescue StandardError => e
    Rails.logger.warn("Tidal search failed: #{e.class}: #{e.message}")
    []
  end

  private

  # ---------------------------
  # Auth
  # ---------------------------

  def access_token
    @access_token ||= begin
      return if @client_id.blank? || @client_secret.blank?

      uri = URI(TIDAL_TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
      request.body = URI.encode_www_form(grant_type: "client_credentials")

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body) rescue {}
      body["access_token"]
    end
  end

  # ---------------------------
  # HTTP helpers
  # ---------------------------

  def http_get(uri, token)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    # Keep headers minimal; TIDAL/CDN can be picky.
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  end

  # ---------------------------
  # Logging helpers (prevents ASCII-8BIT -> UTF-8 explosions)
  # ---------------------------

  def safe_logger_info(message)
    Rails.logger.info(message)
  rescue StandardError
    nil
  end

  def safe_log(str, max = 400)
    s = str.to_s.dup
    s.force_encoding(Encoding::UTF_8)
    s = s.scrub("�")
    s = s.tr("\n", " ")
    s.length > max ? "#{s[0, max]}..." : s
  rescue StandardError
    "[unloggable body]"
  end

  # ---------------------------
  # Search + fetch
  # ---------------------------

  def fetch_search_track_ids(token, query, limit:, country_code:)
    encoded_query = URI.encode_www_form_component(query).gsub("+", "%20")

    uri = URI("#{TIDAL_SEARCH_RESULTS_URL}/#{encoded_query}/relationships/tracks")
    uri.query = URI.encode_www_form(countryCode: country_code, limit: limit)

    response = http_get(uri, token)
    safe_logger_info("Tidal search(tracks ids) status=#{response.code} body=#{safe_log(response.body)}")

    return [] unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body) rescue {}
    data = payload["data"]
    return [] unless data.is_a?(Array)

    data.filter_map { |ri| ri.is_a?(Hash) ? ri["id"]&.to_s : nil }
  end

  def fetch_tracks_by_ids(token, ids, country_code:)
    return [] if ids.blank?

    uri = URI(TIDAL_TRACKS_URL)

    # IMPORTANT: send filter[id] as repeated params (JSON:API-style), not comma-separated
    params = []
    params << ["countryCode", country_code]
    params << ["include", "artists,albums"]
    ids.each { |id| params << ["filter[id]", id.to_s] }
    uri.query = URI.encode_www_form(params)

    response = http_get(uri, token)
    safe_logger_info("Tidal tracks(batch) status=#{response.code} body=#{safe_log(response.body)}")

    return [] unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body) rescue {}
    parse_v2_tracks_payload(payload)
  end

  # ---------------------------
  # Parsing
  # ---------------------------

  # /v2/tracks returns:
  # { "data": [track...], "included": [artists..., albums...] }
  # Track objects reference included resources via relationships.
  def parse_v2_tracks_payload(payload)
    data = payload["data"]
    return [] unless data.is_a?(Array)

    included_index = build_included_index(payload["included"])

    data.filter_map do |track|
      parse_v2_track(track, included_index)
    end
  end

  def build_included_index(included)
    index = {}
    return index unless included.is_a?(Array)

    included.each do |obj|
      type = obj["type"]
      id   = obj["id"]&.to_s
      next if type.blank? || id.blank?

      index[[type, id]] = obj["attributes"] || {}
    end

    index
  end

  def parse_v2_track(item, included_index = {})
    attrs = item["attributes"] || {}
    id = item["id"] || attrs["id"]
    title = attrs["title"] || attrs["name"]

    artist = resolve_first_related_name(item, "artists", included_index) ||
             attrs.dig("artists", 0, "name") ||
             attrs.dig("artist", "name")

    album_attrs = resolve_first_related_attrs(item, "albums", included_index)
    album = album_attrs&.[]("title") || album_attrs&.[]("name") ||
            attrs.dig("album", "title") || attrs["albumTitle"] || attrs.dig("album", "name")

    image_url = extract_image_url_from_album_attrs(album_attrs) || extract_image_url(attrs)
    url = extract_external_tidal_url(attrs, id)

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

  def resolve_first_related_name(item, rel_name, included_index)
    rel = item.dig("relationships", rel_name, "data")
    return unless rel.is_a?(Array) && rel.first.is_a?(Hash)

    type = rel.first["type"]
    id   = rel.first["id"]&.to_s
    attrs = included_index[[type, id]]
    return unless attrs.is_a?(Hash)

    attrs["name"] || attrs["title"]
  end

  def resolve_first_related_attrs(item, rel_name, included_index)
    rel = item.dig("relationships", rel_name, "data")
    return unless rel.is_a?(Array) && rel.first.is_a?(Hash)

    type = rel.first["type"]
    id   = rel.first["id"]&.to_s
    included_index[[type, id]]
  end

  def extract_external_tidal_url(attrs, id)
    links = attrs["externalLinks"]

    url =
      case links
      when Hash
        links.dig("tidal", "href") ||
          links.dig("TIDAL", "href") ||
          links.dig("tidal", "url") ||
          links.dig("TIDAL", "url")
      when Array
        tidal = links.find do |l|
          l.is_a?(Hash) && (l["type"].to_s.downcase == "tidal" || l["name"].to_s.downcase == "tidal")
        end
        tidal&.dig("href") || tidal&.dig("url")
      end

    url || attrs["url"] || "https://tidal.com/browse/track/#{id}"
  end

  def extract_image_url_from_album_attrs(album_attrs)
    return unless album_attrs.is_a?(Hash)

    # 1) If v2 gives ready-to-use image links
    links = album_attrs["imageLinks"]
    if links.is_a?(Array)
      href = links.first&.dig("href")
      return href if href.present?
    elsif links.is_a?(Hash)
      href = links.values.first
      return href if href.present?
    end

    # 2) Common "cover" id forms (string or nested hash)
    cover =
      album_attrs["cover"] ||
      album_attrs["coverId"] ||
      album_attrs["coverID"] ||
      album_attrs["imageId"] ||
      album_attrs["imageID"] ||
      album_attrs.dig("cover", "id") ||
      album_attrs.dig("cover", "uuid") ||
      album_attrs.dig("image", "id")

    return tidal_cover_url(cover) if cover.present?

    nil
  end

  def tidal_cover_url(cover)
    normalized = cover.to_s.tr("-", "/")
    "https://resources.tidal.com/images/#{normalized}/640x640.jpg"
  end


  def extract_image_url(attrs)
    links = attrs.dig("album", "imageLinks") || attrs["imageLinks"]

    if links.is_a?(Array)
      links.first&.dig("href")
    elsif links.is_a?(Hash)
      links.values.first
    end
  end
end
