# frozen_string_literal: true

module SolidusShipstation
  module Api
    class SyncShipmentsJob < ApplicationJob
      queue_as :default

      retry_on StandardError, attempts: SolidusShipstation.config.api_request_attempts do |_job, error|
        SolidusShipstation.config.error_handler.call(error, {})
      end

      def perform(shipments)
        shipments = select_shipments(shipments)
        return if shipments.empty?

        sync_shipments(shipments)

        valid = all_shipments_valid?(shipments, verbose: true)
        unless valid.try(:[], :all_valid)
          SolidusShipstation.config.error_handler.call('not all shipments match selection query', valid)
        end
      rescue RateLimitedError => e
        self.class.set(wait: e.retry_in).perform_later
      end

      def all_shipments_valid?(shipments, verbose: false)
        selected = select_shipments(shipments)
        if verbose
          res = {
            all_valid: shipments.size == selected.size,
          }
          unless res[:result]
            res.merge!({
              invalid_count: shipments.size - selected.size,
              invalid_shipment_ids: shipments.map(&:id) - selected.map(&:id),
            })
          end
          return res
        else
          return shipments.size == selected.size
        end
      end


      private

      def select_shipments(shipments)
        shipments.select do |shipment|
          if ThresholdVerifier.call(shipment)
            true
          else
            ::Spree::Bus.publish(:'solidus_shipstation.api.sync_skipped',
              shipment: shipment
            )

            false
          end
        end
      end

      def sync_shipments(shipments)
        BatchSyncer.from_config.call(shipments)
      end
    end
  end
end
