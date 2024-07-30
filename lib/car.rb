# frozen_string_literal: true

##
# Car class is responsible for creating a Car object with features.
# It initializes the object with a hash of attributes and provides
# methods to access and print the car's features.
class Car
  ##
  # This attr_accessor is for the features attribute.
  attr_accessor :features

  ##
  # Initializes the Car object with a hash of attributes.
  #
  # @param [Hash] attributes A hash of attributes to initialize the Car object with.
  def initialize(attributes)
    @features = {}
    attributes.each do |key, value|
      @features[key] = value
    end
  end

  ##
  # Prints the URL of the car.
  #
  # @return [String] The URL of the car.
  def print_url
    @features['URL']
  end
end
