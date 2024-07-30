# frozen_string_literal: true

require 'date'
# require 'logger'

## FileManager module
module FileManager
  ## Write to file method
  # Writes the data to the file
  def self.write_to_file(file_name, data)
    File.open(file_name, 'w:UTF-8') do |file|
      file.write(data)
    end
  rescue StandardError => e
    raise e
  end

  ## Read from file method
  # Reads the data from the file
  def read_from_file(file_name)
    File.read(file_name)
  rescue StandardError
    raise
  end
end
