# frozen_string_literal: true

require 'nokogiri'
require_relative './httparty_handler'

## Scraper class
# This class scrapes the data from the website
# It has a method to scrape the data
class Scraper
  ## Initialize method
  # This method initializes the Scraper object with a base link and an optional path
  def initialize(link)
    @url = link
    @features = {}
  end

  ## Scrap method
  # This method scrapes the data from the website
  # It makes a GET request to the URL using the HttpartyHandler
  # It parses the HTML using Nokogiri
  # It scrapes the features of the car
  # It returns the features
  def scrap
    response = HttpartyHandler.get(@url)
    html = Nokogiri::HTML(response)
    @features['URL'] = @url
    html.xpath('//div[@class="dt-row" or @class="dt-row no-value"]').each do |row|
      label_element = row.at_xpath('.//div[@class="dt-row__text__content"]')
      value_element = row.at_xpath('.//span[@class="dt-param-value"]')

      label = label_element ? label_element.text.strip : 'brak etykiety'
      value = value_element ? value_element.text.strip : 'brak danych'
      value = 'brak danych' if value.empty?

      # Debugging information
      # puts "[#{@name}]Label: #{label}, Value: #{value}"
      @features[label] = value
    end
    @features
  end
end
