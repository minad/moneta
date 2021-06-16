require 'hbaserb'

module Moneta
  module Adapters
    # HBase thrift backend
    # @api public
    class HBase < Adapter
      config :column, 'value'
      config :table, 'moneta'
      config :column_family, 'moneta'

      backend { |host: '127.0.0.1', port: 9090| HBaseRb::Client.new(host, port) }

      # TODO: Add create support using checkAndPut if added to thrift api
      # https://issues.apache.org/jira/browse/HBASE-3307
      # https://github.com/bmuller/hbaserb/issues/2
      supports :increment

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9090) Server port
      # @option options [String] :table ('moneta') Table name
      # @option options [String] :column_family ('moneta') Column family
      # @option options [String] :column ('value') Column
      # @option options [::HBaseRb::Client] :backend Use existing backend instance
      def initialize(options = {})
        super
        @column = [config.column_family, config.column].join(':')
        backend.create_table(config.table, config.column_family) unless backend.has_table?(config.table)
        @table = backend.get_table(config.table)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @table.get(key, @column).first != nil
      end

      # (see Proxy#load)
      def load(key, options = {})
        cell = @table.get(key, @column).first
        cell && unpack(cell.value)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @table.mutate_row(key, @column => pack(value))
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        result = @table.atomic_increment(key, @column, amount)
        # HACK: Throw error if applied to invalid value
        Integer(load(key)) if result == 0
        result
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @table.delete_row(key)
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.create_scanner do |row|
          @table.delete_row(row.row)
        end
        self
      end

      # (see Proxy#close)
      def close
        backend.close
        nil
      end

      private

      def pack(value)
        intvalue = value.to_i
        if intvalue >= 0 && intvalue <= 0xFFFFFFFFFFFFFFFF && intvalue.to_s == value
          # Pack as 8 byte big endian
          [intvalue].pack('Q>')
        elsif value.bytesize >= 8
          # Add nul character to make value distinguishable from integer
          value + "\0"
        else
          value
        end
      end

      def unpack(value)
        if value.bytesize == 8
          # Unpack 8 byte big endian
          value.unpack('Q>').first.to_s
        elsif value.bytesize >= 9 && value[-1] == ?\0
          # Remove nul character
          value[0..-2]
        else
          value
        end
      end
    end
  end
end
