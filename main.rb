# frozen_string_literal: true

require 'set'
require 'nokogiri'
require 'httparty'
require 'concurrent'
require_relative './lib/scraper'
require_relative './lib/report_generator'
require_relative './lib/httparty_handler'
require_relative './lib/nokogiri_handler'
require_relative './lib/car'
require 'logger'

##
# The Main class orchestrates the scraping process. It fetches URLs from a sitemap,
# processes each link to gather car data, and generates a report.
class Main
  ##
  # Initializes a new Main object.
  #
  # Sets up the initial state, including loading existing report data if available,
  # fetching and parsing the sitemap, and starting the scraping process.
  def initialize
    @cars = []
    @report_file = './reports/report.csv'
    @car_urls = Set.new
    @car_counter = 0
    @logger = Logger.new('./logs/main.log', shift_age = 0, shift_size = 0)

    check_and_load_existing_report
    fetch_and_parse_sitemap
    scrap
  end

  ##
  # Checks for an existing report file and loads the car data if it exists.
  #
  # If the report file is found, it loads the cars and their URLs into memory.
  # If the report file is not found, it starts from scratch.
  def check_and_load_existing_report
    if File.exist?(@report_file)
      puts "Loading existing report from #{@report_file}..."
      @cars = ReportGenerator.read_cars_from_file(@report_file)
      @car_urls = Set.new(@cars.map(&:print_url))
    else
      puts "Report file #{@report_file} not found. Starting from scratch..."
    end
  end

  ##
  # Fetches and parses the sitemap to extract all car-related URLs.
  #
  # It fetches the sitemap from the given URL, removes namespaces for easier processing,
  # and filters out URLs that do not lead to specific car data.
  def fetch_and_parse_sitemap
    sitemap_url = 'https://www.autocentrum.pl/sitemap/daneTechniczne.xml'
    response = HttpartyHandler.get(sitemap_url)

    sitemap = Nokogiri::XML(response)
    sitemap.remove_namespaces!

    all_links = sitemap.xpath('//url/loc').map(&:text)
    @sitemap_links = all_links.reject { |link| link.count('/') <= 5 }
  end

  ##
  # Starts the scraping process by processing each link from the sitemap.
  #
  # It uses a thread pool to handle multiple links concurrently and ensures all
  # threads are completed before finishing. If interrupted or an error occurs,
  # it logs the error and generates the report with the data collected so far.
  def scrap
    puts 'Scraping started...'

    thread_pool = Concurrent::FixedThreadPool.new(200) # Limit based on your system resources

    @sitemap_links.each do |link|
      thread_pool.post do
        process_link(link)
      end
    end

    thread_pool.shutdown
    thread_pool.wait_for_termination

    puts "Scraping finished. Scraped #{@cars.count} cars."
  rescue Interrupt
    puts "Operation was interrupted by the user. Scraped #{@cars.count} cars."
    exit
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
    @logger.error("Error during scraping: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
  ensure
    generate_report
  end

  ##
  # Processes a single link by checking if the car data is already loaded.
  #
  # If the car data is not already loaded, it adds the car.
  #
  # @param [String] link The URL to process.
  def process_link(link)
    return if car_already_loaded?(link)

    add_car(link)
  end

  ##
  # Checks if the car data for a given link is already loaded.
  #
  # @param [String] link The URL to check.
  # @return [Boolean] True if the car data is already loaded, false otherwise.
  def car_already_loaded?(link)
    @car_urls.include?(link)
  end

  ##
  # Adds a car's data by scraping the given URL.
  #
  # It scrapes the data, creates a Car object, and adds it to the list of cars.
  # If an error occurs, it logs the error.
  #
  # @param [String] version_or_engine_data The URL to scrape.
  def add_car(version_or_engine_data)
    return if car_already_loaded?(version_or_engine_data)

    begin
      scraper = Scraper.new(version_or_engine_data)
      version_details = scraper.scrap
      return if version_details.nil? || version_details.size < 2

      car = Car.new(version_details)
      @car_counter += 1
      @cars.push(car)
      @car_urls.add(version_or_engine_data)
      puts "[\e[32m##{@car_counter}\e[0m]"
      @logger.info("[#{@car_counter}] Added car: #{version_or_engine_data}")
    rescue StandardError => e
      @logger.error("Error adding car: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
    end
  end

  ##
  # Generates a report with the collected car data.
  #
  # If no cars have been collected, it prints a message indicating that no report will be generated.
  def generate_report
    if @cars.nil? || @cars.empty?
      puts 'No cars to generate report.'
      return
    end
    report_generator = ReportGenerator.new('./reports/report.csv')
    report_generator.generate_report(@cars)
  end
end

Main.new
