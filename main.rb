require 'faraday'
require 'faraday_middleware'
require 'json'
require 'csv'
require 'uri'
require 'google_drive'
require 'digest/sha1'
require 'pry'
require 'dotenv/load'
require "tempfile"

def request(player_id)
  conn = Faraday.new(url: 'https://bsproxy.royaleapi.dev') do |f|
    f.request :json
    f.response :json
    f.adapter Faraday.default_adapter
  end

  safe_player_id = URI.encode_www_form_component(player_id)
  battlelog_endpoint = "/v1/players/#{safe_player_id}/battlelog"

  response = conn.get(battlelog_endpoint) do |req|
    req.headers['Authorization'] = "Bearer #{ENV['BRAWL_STARTS_API_TOKEN']}"
  end

  response.success? ? response.body['items'] : []
end

def format_response(items, base_player)
  items.map do |item|
    teams = item.dig('battle', 'teams')

    teams.each do |team|
      if team.any? { |p| p['tag'] == base_player }
        item['battle']['ally_team'] = team
      else
        item['battle']['enemy_team'] = team
      end
    end

    item['battle'].delete('teams')
    item
  end
end

def format_team(team)
  team.map { |player| [player['name'], player['tag'], player.dig('brawler', 'name')] }.flatten
end

def format_label(type, offset = 0)
  (1..3).map { |i| ["#{type}#{i}", "tag#{i + offset}", "brawler#{i + offset}"] }.flatten
end

def battle_id(item)
  ally_team_tags = item['battle']['ally_team'].map { |p| p['tag'] }.join('')
  enemy_team_tags = item['battle']['enemy_team'].map { |p| p['tag'] }.join('')

  Digest::SHA1.hexdigest("#{item['battleTime']}#{ally_team_tags}#{enemy_team_tags}")
end

def current_row(item)
  event = item['event']
  battle = item['battle']
  ally_team = battle['ally_team']
  enemy_team = battle['enemy_team']
  battle_id = battle_id(item)

  [
    battle_id(item),
    item['battleTime'],
    battle['mode'],
    event['map'],
    battle['result'],
    format_team(ally_team),
    format_team(enemy_team)
  ].flatten
end

def write_csv(items, worksheet)
  puts "Salvando no Sheets..."

  items.each do |item|
    if (3..worksheet.num_rows).none? { |i| battle_id(item) == worksheet[i, 1] }
      worksheet.insert_rows(
        worksheet.num_rows + 1,
        [current_row(item)]
      )
    end
  end

  worksheet.save
end

def session
  @session ||= begin
    google_credentials = ENV["GOOGLE_API_CREDENTIALS"]
    session = nil

    Tempfile.create(["client_secret", ".json"]) do |temp_file|
      temp_file.write(google_credentials)
      temp_file.rewind

      session = GoogleDrive::Session.from_service_account_key(temp_file.path)
    end

    session
  end
end

def execute
  spreadsheet = session.spreadsheet_by_title('teste brawl')

  spreadsheet.worksheets.each do |worksheet|
    player_1, player_2, player_3 = [worksheet[1, 1], worksheet[1, 2], worksheet[1, 3]]

    find_by = 3 - [player_1, player_2, player_3].count('')

    next if find_by == 0 || find_by == 1

    filtered_items = request(player_1).select do |item|
      item.dig('battle', 'teams').any? do |team|
        if find_by == 2
          team.any? { |p| p['tag'] == player_1 } && team.any? { |p| p['tag'] == player_2 }
        elsif find_by == 3
          team.any? { |p| p['tag'] == player_1 } && team.any? { |p| p['tag'] == player_2 } && team.any? { |p| p['tag'] == player_3 }
        end
      end
    end

    puts "#{filtered_items.size} partidas encontradas!"

    write_csv(format_response(filtered_items, player_1), worksheet)
  end
end

loop do
  execute
end
