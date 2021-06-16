require 'daybreak'

module Moneta
  module Adapters
    # Daybreak backend
    # @api public
    class Daybreak < Adapter
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::Daybreak] :backend Use existing backend instance
      backend { |file:| ::Daybreak::DB.new(file, serializer: ::Daybreak::Serializer::None) }

      # (see Proxy#load)
      def load(key, options = {})
        backend.load if options[:sync]
        backend[key]
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        backend[key] = value
        backend.flush if options[:sync]
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        backend.lock { super }
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        backend.lock { super }
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        if block_given?
          backend.lock do
            backend.update(pairs.map do |key, new_value|
              new_value = yield(key, load(key), new_value) if key?(key)
              [key, new_value]
            end)
          end
        else
          backend.update(pairs)
        end

        self
      end
    end
  end
end
