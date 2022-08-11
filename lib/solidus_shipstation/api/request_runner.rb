# frozen_string_literal: true

module SolidusShipstation
  module Api
    class RequestRunner
      API_BASE = 'https://ssapi.shipstation.com'

      attr_reader :username, :password, :last_response

      class << self
        def from_config
          new(
            username: SolidusShipstation.config.api_key,
            password: SolidusShipstation.config.api_secret,
          )
        end
      end

      def initialize(username:, password:)
        @username = username
        @password = password
      end

      def call(method, path, params = {})
        @last_response = HTTParty.send(
          method,
          URI.join(API_BASE, path),
          body: params.to_json,
          basic_auth: {
            username: @username,
            password: @password,
          },
          headers: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
          },
        )

        case @last_response.code.to_s
        when /2\d{2}/
          @last_response.parsed_response
        when '429'
          raise RateLimitedError.from_response(@last_response)
        else
          raise RequestError.from_response(@last_response)
        end
      end
    end
  end
end
