class DataFormatter
  def self.format_response(items, base_player)
    items.map do |item|
      teams = item.dig('battle', 'teams')
      teams.each do |team|
        key = team.any? { |p| p['tag'] == base_player } ? 'ally_team' : 'enemy_team'
        item['battle'][key] = team
      end
      item['battle'].delete('teams')
      item
    end
  end

  def self.format_team(team)
    team.flat_map { |player| [player['name'], player['tag'], player.dig('brawler', 'name')] }
  end

  def self.battle_id(item)
    ally_tags = item['battle']['ally_team'].map { |p| p['tag'] }.join
    enemy_tags = item['battle']['enemy_team'].map { |p| p['tag'] }.join
    Digest::SHA1.hexdigest("#{item['battleTime']}#{ally_tags}#{enemy_tags}")
  end

  def self.current_row(item)
    battle = item['battle']
    [
      battle_id(item),
      item['battleTime'],
      battle['mode'],
      item.dig('event', 'map'),
      battle['result'],
      format_team(battle['ally_team']),
      format_team(battle['enemy_team'])
    ].flatten
  end
end
