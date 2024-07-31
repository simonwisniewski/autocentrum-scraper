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
    name_element = html.at_xpath('//div/h1[@class="site-title"]')
    url_parts = @url.split('/')
    @features['Marka'] = url_parts[4] || 'brak danych'
    @features['Model'] = url_parts[5] || 'brak danych'
    if name_element
      name = name_element.text.strip
      name_parts = name.sub('Dane techniczne ', '')
      @features['Dodatkowe'] = name_parts
    else
      @features['Dodatkowe'] = 'brak danych'
    end
    @features['URL'] = @url || 'brak danych'
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
    if @features.values[4..-1].all? { |value| value == 'brak danych' || value == 'brak etykiety' }
      return
    end
    @features
  end
end
