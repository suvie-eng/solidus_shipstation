module SolidusShipstation
  class ConsoleHarness
    attr_reader :runner, :syncer, :shipments

    attr_accessor :cursor, :batch

    def initialize
      @runner = SolidusShipstation::Api::RequestRunner.from_config
      @syncer = SolidusShipstation::Api::BatchSyncer.from_config
      @shipments = SolidusShipstation::Api::ScheduleShipmentSyncsJob.new.query_shipments
      @cursor = 0
      @batch = 4
    end

    def refresh
      @shipments = SolidusShipstation::Api::ScheduleShipmentSyncsJob.new.query_shipments
    end

    def serialize(shipment)
      # SolidusShipstation::Api::ApplianceShipmentSerializer.new(shipment)
      @syncer.client.shipment_serializer.call(shipment)
    end

    def try_batch(batch_size=nil)
      b = [batch_size.to_i, @batch].max
      resps = @runner.call(:post, '/orders/createorders', @shipments[@cursor..@cursor+b])

      # this is not a safe advance of the cursor since just some records could fail or succeed
      # @cursor = @cursor+b  if resps.map{|r| r['hasErrors'] }.reduce(&:&) # if no errors

      @cursor = @cursor+b
      resps
    end
  end
end
