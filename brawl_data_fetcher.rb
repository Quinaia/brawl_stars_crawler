class BrawlDataFetcher
  BASE_URL = 'https://bsproxy.royaleapi.dev'
  API_TOKEN = ENV['BRAWL_STARTS_API_TOKEN']

  def request(player_id)
    response = conn.get("/v1/players/#{URI.encode_www_form_component(player_id)}/battlelog") do |req|
      req.headers['Authorization'] = "Bearer #{API_TOKEN}"
    end

    response.success? ? format_response(response) : []
  end

  private

  def format_response(response)
    response.body['items'].select do |item|
      item.dig('battle', 'type') != 'ranked'
    end
  end

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
