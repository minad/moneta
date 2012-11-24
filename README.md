Juno: A unified interface for key/value stores
================================================

[![Build Status](https://secure.travis-ci.org/minad/juno.png?branch=master)](http://travis-ci.org/minad/juno) [![Dependency Status](https://gemnasium.com/minad/juno.png?travis)](https://gemnasium.com/minad/juno) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/juno)

Juno provides a standard interface for interacting with various kinds of key/value stores. Juno
is based on Moneta and replaces it with a mostly compatible interface. The reason for the
fork was that Moneta was unmaintained for a long time.

Out of the box, it supports:

* Memory:
    * In-memory store (:Memory)
    * LocalMemCache (:LocalMemCache)
    * Memcached store (:Memcached, :MemcachedNative and :MemcachedDalli)
* Relational Databases:
    * DataMapper (:DataMapper)
    * ActiveRecord (:ActiveRecord)
    * Sequel (:Sequel)
    * Sqlite3 (:Sqlite)
* Filesystem:
    * PStore (:PStore)
    * YAML store (:YAML)
    * Filesystem directory store (:File)
    * Filesystem directory store which spreads files in subdirectories using md5 hash (:HashFile)
* Key/value databases:
    * Berkeley DB (:DBM)
    * GDBM (:GDBM)
    * SDBM (:SDBM)
    * Redis (:Redis)
    * Riak (:Riak)
    * TokyoCabinet (:TokyoCabinet)
    * Cassandra (:Cassandra)
* Document databases:
    * CouchDB (:Couch)
    * MongoDB (:Mongo)
* Other
    * Fog cloud storage which supports Amazon S3, Rackspace, etc. (:Fog)
    * Storage which doesn't store anything (:Null)

Special proxies:
* Juno::Expires to add expiration support to stores
* Juno::Stack to stack multiple stores
* Juno::Proxy basic proxy class
* Juno::Transformer transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...)
* Juno::Cache combine two stores, one as backend and one as cache (e.g. Juno::Adapters::File + Juno::Adapters::Memory)

The Juno API is purposely extremely similar to the Hash API. In order so support an
identical API across stores, it does not support iteration or partial matches.

Links
-----

* Source: <http://github.com/minad/juno>
* Bugs:   <http://github.com/minad/juno/issues>
* API documentation:
    * Latest Gem: <http://rubydoc.info/gems/juno/frames>
    * GitHub master: <http://rubydoc.info/github/minad/juno/master/frames>

Store API
---------

~~~
#initialize(options)              options differs per-store, and is used to set up the store

#[](key)                          retrieve a key. if the key is not available, return nil

#load(key, options = {})          retrieve a key. if the key is not available, return nil

#fetch(key, options = {}, &block) retrieve a key. if the key is not available, execute the
                                  block and return its return value.

#fetch(key, value, options = {})  retrieve a key. if the key is not available, return the value

#[]=(key, value)                  set a value for a key. if the key is already used, clobber it.
                                  keys set using []= will never expire

#delete(key, options = {})        delete the key from the store and return the current value

#key?(key, options = {})          true if the key exists, false if it does not

#store(key, value, options = {})  same as []=, but you can supply options

#clear(options = {})              clear all keys in this store

#close                            close database connection
~~~

Creating a Store
----------------

There is a simple interface to create a store using `Juno.new`:

~~~ ruby
store = Juno.new(:Memcached, :server => 'localhost:11211')
~~~

If you want to have control over the proxies, you have to use `Juno.build`:

~~~ ruby
store = Juno.build do
  # Adds expires proxy
  use :Expires
  # Transform key and value using Marshal
  use :Transformer, :key => :marshal, :value => :marshal
  # Memory backend
  adapter :Memory
end
~~~

Expiration
----------

The Cassandra, Memcached and Redis backends supports expires values directly:

~~~ ruby
cache = Juno::Adapters::Memcached.new
# Expires in 10 seconds
cache.store(key, value, :expires => 10)

# Or using the builder...
cache = Juno.build do
  adapter :Memcached
end
~~~

You can add the expires feature to other backends using the Expires proxy:

~~~ ruby
# Using the :expires option
cache = Juno.new(:File, :dir => '...', :expires => true)

# or using the proxy...
cache = Juno::Expires.new(Juno::Adapters::File.new(:dir => '...'))
cache.store(key, value, :expires => 10)

# or using the builder...
cache = Juno.build do
  use :Expires
  adapter :File, :dir => '...'
end
~~~

Authors
-------

* Moneta originally by wycats
* Juno by Daniel Mendler