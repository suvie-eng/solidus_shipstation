# frozen_string_literal: true

module SolidusShipstation
  module Api
    class ScheduleShipmentSyncsJob < ApplicationJob
      queue_as :default

      def perform
        query_shipments.find_in_batches(batch_size: SolidusShipstation.config.api_batch_size) do |batch|
          SyncShipmentsJob.perform_later(batch.to_a)
        end
      rescue StandardError => e
        SolidusShipstation.config.error_handler.call(e, {})
      end

      def query_shipments
        SolidusShipstation::Shipment::PendingApiSyncQuery.apply(::Spree::Shipment.all)
      end
    end
  end
end
