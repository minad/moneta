module Moneta
  module Adapters
    class Sequel
      # @api private
      module MySQL
        def store(key, value, options = {})
          @store.call(key: key, value: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            # this creates a row-level lock even if there is no existing row (a
            # "gap lock").
            if row = @load_for_update.call(key: key)
              # Integer() will raise an exception if the existing value cannot be parsed
              amount += Integer(row[config.value_column])
              @increment_update.call(key: key, value: amount)
            else
              @create.call(key: key, value: amount)
            end
            amount
          end
        rescue ::Sequel::SerializationFailure # Thrown on deadlock
          tries ||= 0
          (tries += 1) <= 3 ? retry : raise
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table
              .on_duplicate_key_update
              .import([config.key_column, config.value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        def each_key
          return super unless block_given? && config.each_key_server && @table.respond_to?(:stream)
          # Order is not required when streaming
          @table.server(config.each_key_server).select(config.key_column).paged_each do |row|
            yield row[config.key_column]
          end
          self
        end

        protected

        def prepare_store
          @store = @table
            .on_duplicate_key_update
            .prepare(:insert, statement_id(:store), config.key_column => :$key, config.value_column => :$value)
        end

        def prepare_increment
          @increment_update = @table
            .where(config.key_column => :$key)
            .prepare(:update, statement_id(:increment_update), config.value_column => :$value)
          super
        end
      end
    end
  end
end
