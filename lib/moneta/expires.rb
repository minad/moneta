module Moneta
  # Adds expiration support to the underlying store
  #
  # `#store`, `#load` and `#key?` support the `:expires` option to set/update
  # the expiration time.
  #
  # @api public
  class Expires < Proxy

    include ExpiresSupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [String] :expires Default expiration time
    def initialize(adapter, options = {})
      super
      self.default_expires = options[:expires]
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      # Transformer might raise exception
      load_entry(key, options) != nil
    rescue Exception
      options.include?(:expires) && (options = options.dup; options.delete(:expires))
      super(key, options)
    end

    # (see Proxy#load)
    def load(key, options = {})
      return super if options.include?(:raw)
      value, expires = load_entry(key, options)
      value
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      return super if options.include?(:raw)
      expires = expiration_time(options[:expires])
      if options.include?(:expires)
        options = options.dup
        options.delete(:expires)
      end
      super(key,value_with_expires(value, expires), options)
      value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      return super if options.include?(:raw)
      value, expires = super
      value if !expires || Time.now.to_i <= expires
    end

    private

    def load_entry(key, options)
      new_expires = nil
      if options.include? :expires
        options = options.dup
        new_expires = expiration_time_without_default( options.delete(:expires) )
      end
      entry = @adapter.load(key, options)
      if entry != nil
        value, expires = entry
        if expires && Time.now.to_i > expires
          delete(key)
          nil
        elsif !new_expires.nil?
          @adapter.store(key, value_with_expires(value, new_expires), options)
          entry
        else
          entry
        end
      end
    end


    def value_with_expires(value, expires)
      if expires
        [value, expires.to_i]
      elsif Array === value || value == nil
        [value]
      else
        value
      end
    end

  end
end
