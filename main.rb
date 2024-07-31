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

class Main
  def initialize
    @cars = Concurrent::Array.new
    @car_urls = Concurrent::Set.new
    @car_counter = Concurrent::AtomicFixnum.new(0)
    @report_file = './reports/report.csv'
    @logger = Logger.new('./logs/main.log', shift_age = 0, shift_size = 0)

    check_and_load_existing_report
    fetch_and_parse_sitemap
    scrap
  end

  def check_and_load_existing_report
    if File.exist?(@report_file)
      puts "Loading existing report from #{@report_file}..."
      @cars.concat(ReportGenerator.read_cars_from_file(@report_file))
      @car_urls.merge(@cars.map(&:print_url))
    else
      puts "Report file #{@report_file} not found. Starting from scratch..."
    end
  end

  def fetch_and_parse_sitemap
    sitemap_url = 'https://www.autocentrum.pl/sitemap/daneTechniczne.xml'
    response = HttpartyHandler.get(sitemap_url)

    sitemap = Nokogiri::XML(response)
    sitemap.remove_namespaces!

    all_links = sitemap.xpath('//url/loc').map(&:text)
    @sitemap_links = all_links.reject { |link| link.count('/') < 6 }
  end

  def scrap
    puts 'Scraping started...'
    thread_pool = Concurrent::FixedThreadPool.new(300)

    @sitemap_links.each do |link|
      thread_pool.post do
        process_link(link)
      end
    end

    thread_pool.shutdown
    thread_pool.wait_for_termination

    puts "Scraping finished. Scraped #{@cars.count} cars."
  rescue Interrupt
    puts "Operation was interrupted by the user. Scraped #{@car_counter.value} cars."
    exit
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
    @logger.error("Error during scraping: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
  ensure
    generate_report
  end

  def process_link(link)
    return if car_already_loaded?(link)

    add_car(link)
  end

  def car_already_loaded?(link)
    @car_urls.include?(link)
  end

  def add_car(version_or_engine_data)
    return if car_already_loaded?(version_or_engine_data)

    begin
      scraper = Scraper.new(version_or_engine_data)
      version_details = scraper.scrap
      return if version_details.nil? || version_details.size <= 5

      car = Car.new(version_details)
      @cars << car
      @car_counter.increment
      @car_urls.add(version_or_engine_data)
      puts "[\e[32m##{@car_counter.value}\e[0m]"
      @logger.info("[#{@car_counter.value}] Added car: #{version_or_engine_data}")
    rescue StandardError => e
      @logger.error("Error adding car: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
    end
  end

  def generate_report
    if @cars.empty?
      puts 'No cars to generate report.'
      return
    end
    report_generator = ReportGenerator.new('./reports/report.csv')
    report_generator.generate_report(@cars)
  end
end

Main.new
