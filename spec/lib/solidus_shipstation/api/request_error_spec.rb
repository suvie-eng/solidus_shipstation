RSpec.describe SolidusShipstation::Api::RequestError do
  describe '.from_response' do
    it 'extracts the status code, body and headers from the response' do
      response = instance_double(
        'HTTParty::Response',
        code: 500,
        headers: { 'Key' => 'Value' },
        body: '{ "Message": "An error has occured.", "ExceptionMessage": "orders are required", "ExceptionType": "System.ArgumentException" }',
      )

      error = described_class.from_response(response)

      expect(error).to have_attributes(
        response_code: 500,
        response_headers: { 'Key' => 'Value' },
        response_body: '{ "Message": "An error has occured.", "ExceptionMessage": "orders are required", "ExceptionType": "System.ArgumentException" }',
      )
    end
  end

  describe '.message' do
    it 'returns the name of the exception if there is no message body' do
      response = instance_double(
        'HTTParty::Response',
        code: 500,
        headers: { 'Key' => 'Value' },
        body: nil
      )

      error = described_class.from_response(response)

      expect(error.message).to eq("SolidusShipstation::Api::RequestError")
    end

    it 'extracts both the ExceptionMessage and ExceptionType' do
      response = instance_double(
        'HTTParty::Response',
        code: 500,
        headers: { 'Key' => 'Value' },
        body: '{ "Message": "An error has occured.", "ExceptionMessage": "orders are required", "ExceptionType": "System.ArgumentException" }',
      )

      error = described_class.from_response(response)

      expect(error.message).to eq("System.ArgumentException: orders are required")
    end

    it 'doesn\'t fail when the ExceptionMessage and ExceptionType are missing' do
      response = instance_double(
        'HTTParty::Response',
        code: 500,
        headers: { 'Key' => 'Value' },
        body: '{ "Message": "An error has occured." }',
      )

      error = described_class.from_response(response)

      expect(error.message).to eq("Unknown Exception Type: ")
    end

    it 'returns the raw body prefixed with Error when the response is not a valid JSON' do
      response = instance_double(
        'HTTParty::Response',
        code: 429,
        headers: {'Key' => 'Value'},
        body: 'Too Many Requests'
      )

      error = described_class.from_response(response)

      expect(error.message).to eq('Unknown Exception Type: Too Many Requests')
    end


    it 'it should NOT raise any error when the response is not a valid JSON' do
      response = instance_double(
        'HTTParty::Response',
        code: 429,
        headers: {'Key' => 'Value'},
        body: 'Too Many Requests'
      )

      expect { described_class.from_response(response) }.not_to raise_error
    end
  end
end
