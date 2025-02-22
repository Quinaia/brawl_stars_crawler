class GoogleSheetManager
  CREDENTIALS = ENV['GOOGLE_API_CREDENTIALS']
  SPREADSHEET_TITLE = 'teste brawl'

  def write_csv(items, worksheet)
    items.each do |item|
      next if (3..worksheet.num_rows).any? { |i| DataFormatter.battle_id(item) == worksheet[i, 1] }

      worksheet.insert_rows(worksheet.num_rows + 1, [DataFormatter.current_row(item)])
    end

    worksheet.save
  end

  def fetch_spreadsheet
    session.spreadsheet_by_title(SPREADSHEET_TITLE)
  end

  private

  attr_reader :session

  def session
    @session ||= Tempfile.create(['client_secret', '.json']) do |temp_file|
      temp_file.write(CREDENTIALS)
      temp_file.rewind
      GoogleDrive::Session.from_service_account_key(temp_file.path)
    end
  end
end
