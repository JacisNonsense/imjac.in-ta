require 'net/http'

module OnDeck
  class TBA
    def self.apikey
      Rails.application.credentials.dig(:tba)
    end

    def self.http
      if @http.nil?
        uri = URI.parse("https://thebluealliance.com")
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
      end
      @http
    end

    def self.api *path
      fullpath = ["api", "v3", path].flatten.join('/')
      req = Net::HTTP::Get.new("/#{fullpath}")
      req['X-TBA-Auth-Key'] = TBA::apikey
      req['User-Agent'] = "jaci_ondeck"
      req['Host'] = "www.thebluealliance.com"

      res = TBA::http.request req
      JSON.parse(res.body)
    end
  end
end