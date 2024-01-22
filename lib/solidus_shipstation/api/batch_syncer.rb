# frozen_string_literal: true

module SolidusShipstation
  module Api
    class BatchSyncer
      class << self
        def from_config
          new(
            client: SolidusShipstation::Api::Client.from_config,
            shipment_matcher: SolidusShipstation.config.api_shipment_matcher,
          )
        end
      end

      attr_reader :client, :shipment_matcher

      def initialize(client:, shipment_matcher:)
        @client = client
        @shipment_matcher = shipment_matcher
      end

      def call(shipments)
        begin
          response = client.bulk_create_orders(shipments)
        rescue RateLimitedError => e
          ::Spree::Event.fire(
            'solidus_shipstation.api.rate_limited',
            shipments: shipments,
            error: e,
          )

          raise e
        rescue RequestError => e
          ::Spree::Event.fire(
            'solidus_shipstation.api.sync_errored',
            shipments: shipments,
            error: e,
          )

          raise e
        end

        return unless response

        response['results'].each do |shipstation_order|
          post_sync(shipstation_order, shipments)
        end
      end

      UNMODIFIABLE_RX = /The order with orderKey "\w+" is inactive and cannot be modified/

      def post_sync(shipstation_order, shipments)
        shipment = shipment_matcher.call(shipstation_order, shipments)
        unmodifiable = shipstation_order.fetch('errorMessage','').match?(UNMODIFIABLE_RX)

        # an unmodifiable order will never sync, so don't fail it
        if (!shipstation_order['success'] && !unmodifiable)
          ::Spree::Event.fire(
            'solidus_shipstation.api.sync_failed',
            shipment: shipment,
            payload: shipstation_order,
          )

          return false
        end

        shipment.update_columns(
          shipstation_synced_at: Time.zone.now,
          shipstation_order_id: shipstation_order['orderId'],
        )

        ::Spree::Event.fire(
          'solidus_shipstation.api.sync_completed',
          shipment: shipment,
          payload: shipstation_order,
        )

        true
      end
    end
  end
end
