module ApplicationHelper
    def safe_external_url(url)
        uri = URI.parse(url.to_s) rescue nil
        return nil unless uri.is_a?(URI::HTTP) && uri.host.present?
        uri.to_s
    end
end
