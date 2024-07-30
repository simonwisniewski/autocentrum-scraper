# frozen_string_literal: true

require 'csv'
require 'set'

##
# The ReportGenerator class is responsible for generating a report from car data,
# extracting links from the report, and reading car data from an existing report file.
class ReportGenerator
  ##
  # Initializes the ReportGenerator object with a file name.
  #
  # @param [String] file_name The name of the file where the report will be saved.
  # @param [String] encoding The encoding to be used for reading and writing CSV files.
  def initialize(file_name, encoding: 'utf-8')
    @file_name = file_name
    @encoding = encoding
  end

  ##
  # Reads cars from an existing CSV file.
  #
  # @param [String] file_name The name of the file to read cars from.
  # @return [Array<Car>] An array of Car objects read from the file.
  def self.read_cars_from_file(file_name)
    cars = []
    CSV.foreach(file_name, headers: true, encoding: 'bom|utf-8') do |row|
      features = row.to_h
      car = Car.new(features)
      cars << car
    end
    puts "Read #{cars.size} cars from file."

    if cars.any?
      most_features_car = car_with_most_features(cars)
      puts "Car with most features: #{most_features_car.print_url}"
    else
      puts 'No cars read from file.'
    end
    cars
  end

  ##
  # Finds the car with the most features.
  #
  # @param [Array<Car>] cars An array of Car objects.
  # @return [Car, nil] The car with the most features, or nil if no cars are provided.
  def self.car_with_most_features(cars)
    cars.max_by { |car| car.features.size }
  end

  ##
  # Colorizes the given text with the specified color code.
  #
  # @param [String] text The text to colorize.
  # @param [Integer] color_code The color code to use for colorizing the text.
  # @return [String] The colorized text.
  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  ##
  # Generates a report from the given cars and saves it to a CSV file.
  #
  # The headers of the CSV file are based on the features of the car with the most features.
  # Prints messages when the report is being generated and when it is saved.
  #
  # @param [Array<Car>] cars An array of Car objects to include in the report.
  def generate_report(cars)
    puts colorize('Generating report...', 33)
    most_features_car = self.class.car_with_most_features(cars)
    if most_features_car.nil?
      puts 'No car with features to generate report.'
      return
    end
    headers = most_features_car.features.keys

    sorted_cars = cars.sort_by { |car| car.features['URL'].downcase }

    CSV.open(@file_name, 'wb', write_headers: true, headers: headers) do |csv|
      sorted_cars.each do |car|
        # Build each row by iterating over headers, using "brak danych" for missing features
        row = headers.map { |header| car.features[header] || 'no data' }
        csv << row
      end
    end
    puts colorize('Report generated and saved to report.csv.', 32)
    puts "Car with most features: #{most_features_car.print_url}"
  end
end
