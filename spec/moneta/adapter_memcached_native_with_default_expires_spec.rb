# Generated by generate-specs
require 'helper'

describe_moneta "adapter_memcached_native_with_default_expires" do
  def new_store
    Moneta::Adapters::MemcachedNative.new(:expires => 1)
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'default_expires'
  it_should_behave_like 'expires'
  it_should_behave_like 'increment'
  it_should_behave_like 'multiprocess'
  it_should_behave_like 'null_stringkey_stringvalue'
  it_should_behave_like 'persist_stringkey_stringvalue'
  it_should_behave_like 'returndifferent_stringkey_stringvalue'
  it_should_behave_like 'store_stringkey_stringvalue'
end