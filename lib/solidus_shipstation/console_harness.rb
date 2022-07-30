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

    def shipment(id)
      @shipments.find_by(id: id)
    end

    def shipment_number(ship_number)
      @shipments.find_by(number: ship_number)
    end

    def serialize(shipment)
      # SolidusShipstation::Api::ApplianceShipmentSerializer.new(shipment)
      @syncer.client.shipment_serializer.call(shipment)
    end

    def try_one
      puts "trying shipment #{(shipment = @shipments[@cursor]).id}"
      resp = @runner.call(:post, '/orders/createorders', [serialize(shipment)])
      unless resp['hasErrors']
        @cursor += 1
        return true
      end
    ensure
      puts resp
    end

    def try_batch(batch_size=nil)
      b = [batch_size.to_i, @batch].max
      b.times do
        break unless try_one
      end
    end
  end
end
