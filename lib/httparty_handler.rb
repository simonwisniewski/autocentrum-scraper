# frozen_string_literal: true

require 'persistent_httparty'
require 'logger'
require 'concurrent'

##
# HttpartyHandler class is responsible for handling HTTP requests with retry logic,
# rate limiting, and logging. It uses HTTParty for making HTTP requests and includes
# concurrency control using semaphores.
class HttpartyHandler
  include HTTParty
  default_timeout 20

  # Logger for HTTP request errors and information
  @logger = ::Logger.new('./logs/httparty_handler.log', 1_024_000)
  @max_attempts = 5
  @delay = 1
  @max_delay = 16
  @last_request_time = Time.now
  # Semaphore to limit the number of concurrent requests
  @semaphore = Concurrent::Semaphore.new(300)
  @user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36'

  ##
  # Makes a GET request to the given URL with retry logic and rate limiting.
  #
  # @param [String] url The URL to make the GET request to.
  # @return [String] The response body of the GET request.
  # @raise [RuntimeError] If the request fails after the maximum number of attempts.
  def self.get(url)
    attempts = 0
    begin
      @semaphore.acquire
      sleep_until_next_allowed_request
      response = super(url, headers: { 'User-Agent' => @user_agent })
      raise 'Empty response body' if response.body.nil? || response.body.empty?

      adjust_delay_based_on_response(response)
      @last_request_time = Time.now
      response.body
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
      attempts += 1
      @logger.error("Connection error: #{e.message}")
      if attempts <= @max_attempts
        puts "[\e[33mConnection error\e[0m]: \e[34m#{e.message}\e[0m. Retrying in \e[34m#{@delay}\e[0m seconds..."
        @delay = [@delay * 2, @max_delay].min
        sleep(@delay)
        retry
      else
        puts "Failed to retrieve data after #{attempts} attempts due to connection issues."
        raise
      end
    ensure
      @@semaphore.release
    end
  end

  ##
  # Sleeps until the next request is allowed based on the rate limiting delay.
  def self.sleep_until_next_allowed_request
    now = Time.now
    sleep_time = @delay - (now - @last_request_time) + rand(0.5..2.0)
    sleep(sleep_time) if sleep_time.positive?
  end

  ##
  # Adjusts the rate limiting delay based on the HTTP response code.
  #
  # If the response code is 429 (Too Many Requests), the delay is increased.
  # Otherwise, the delay is reset to 1 second.
  #
  # @param [HTTParty::Response] response The HTTP response to adjust the delay based on.
  def self.adjust_delay_based_on_response(response)
    @delay = if response.code == 429 # Too Many Requests
               [@delay * 2, @max_delay].min
             else
               1
             end
  end
end
