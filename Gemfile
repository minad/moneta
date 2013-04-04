source 'https://rubygems.org'
gemspec

# Testing
gem 'rake'
gem 'rspec'
gem 'rspec-retry'

# Serializer used by Transformer
gem 'tnetstring'
gem 'bencode'
gem 'multi_json'
gem 'bson_ext', :platforms => :ruby
gem 'bson', :platforms => :jruby
gem 'ox', :platforms => :ruby
gem 'msgpack', :platforms => :ruby
gem 'msgpack-jruby', :platforms => :jruby
gem 'bert', :platforms => :ruby

# Compressors used by Transformer
if RUBY_VERSION < '2.0'
  gem 'bzip2-ruby', :platforms => :mri # Only on mri currently
end
gem 'ruby-lzma', :platforms => :ruby
gem 'lzoruby', :platforms => :ruby
gem 'snappy', :platforms => :ruby
gem 'qlzruby', :platforms => :ruby

# Backends
gem 'faraday'
gem 'daybreak'
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-mysql-adapter'
gem 'fog'
gem 'activerecord', '>= 3.2.11'
gem 'redis'
gem 'mongo'
gem 'couchbase'
# Use sequel master because of deprecation warnings
gem 'sequel', :github => 'jeremyevans/sequel'
gem 'dalli'
gem 'riak-client'
gem 'cassandra'
gem 'tokyotyrant'
#gem 'ruby-tokyotyrant', :platforms => :ruby
#gem 'hbaserb'
#gem 'localmemcache'
gem 'tdb', :platforms => :ruby
gem 'leveldb-ruby', :platforms => :ruby
if RUBY_VERSION < '2.0'
  gem 'tokyocabinet', :platforms => :ruby
end
if RUBY_VERSION < '2.0' && !defined?(JRUBY_VERSION)
  # FIXME: We have to check manually for jruby
  # otherwise bundle install --deployment doesn't work
  gem 'kyotocabinet-ruby', :github => 'minad/kyotocabinet-ruby'
end
gem 'memcached', :platforms => :ruby
gem 'jruby-memcached', :platforms => :jruby
gem 'sqlite3', :platforms => :ruby
gem 'activerecord-jdbc-adapter', :platforms => :jruby
gem 'activerecord-jdbcmysql-adapter', :platforms => :jruby
gem 'mysql2', '>= 0.3.12b5', :platforms => :ruby
# gdbm for jruby needs ffi
gem 'ffi', :platforms => :jruby
gem 'gdbm', :platforms => :jruby

# Rack integration testing
gem 'rack'
gem 'rack-cache'

# Rails integration testing
gem 'actionpack', '>= 3.2.11'
gem 'minitest'
