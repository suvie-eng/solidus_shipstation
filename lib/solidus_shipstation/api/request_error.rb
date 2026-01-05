# frozen_string_literal: true

module SolidusShipstation
  module Api
    class RequestError < RuntimeError
      attr_reader :response_code, :response_body, :response_headers

      class << self
        def from_response(response)
          new(**options_from_response(response))
        end

        private

        def options_from_response(response)
          {
            response_code: response.code,
            response_headers: response.headers,
            response_body: response.body,
          }
        end
      end

      def initialize(response_code:, response_body:, response_headers:)
        @response_code = response_code
        @response_body = response_body
        @response_headers = response_headers

        super(message_from_body)
      end

      private

      def message_from_body
        return unless @response_body

        parsed_body = parse_response_body
        exception_type = parsed_body.fetch('ExceptionType', 'Unknown Exception Type')
        exception_message = parsed_body.fetch('ExceptionMessage', '')
        "#{exception_type}: #{exception_message}"
      end

      def parse_response_body
        JSON.parse(@response_body)
      rescue JSON::ParserError
        { 'ExceptionMessage' => @response_body.to_s.strip }
      end
    end
  end
end
