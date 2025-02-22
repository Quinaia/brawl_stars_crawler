class BrawlDataFetcher
  BASE_URL = 'https://bsproxy.royaleapi.dev'
  API_TOKEN = ENV['BRAWL_STARTS_API_TOKEN']

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def request(player_id)
    response = @conn.get("/v1/players/#{URI.encode_www_form_component(player_id)}/battlelog") do |req|
      req.headers['Authorization'] = "Bearer #{API_TOKEN}"
    end
    response.success? ? response.body['items'] : []
  end
end
