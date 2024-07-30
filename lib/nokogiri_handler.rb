# frozen_string_literal: true

require 'nokogiri'

## NokogiriHandler class
# This class handles the Nokogiri requests
# It has a class method to parse the HTML
# The method takes the body, selector, and an optional attribute
# It returns the parsed HTML
class NokogiriHandler
  ## HTML method
  # This method parses the HTML
  # It takes the body, selector, and an optional attribute
  # It returns the parsed HTML
  def self.html(body, sel, at = '')
    html = Nokogiri::HTML(body)
    html.css(sel).map { |val| at ? val[at] : val.text }
  end
end
