# coding: binary
# Generated by generate-specs
require 'helper'

describe_moneta "standard_environment" do
  def features
    [:increment]
  end

  def new_store
    Moneta.new(:Environment, :logger => {:file => File.join(make_tempdir, 'standard_environment.log')})
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'features'
  it_should_behave_like 'increment'
  it_should_behave_like 'marshallable_key'
  it_should_behave_like 'marshallable_value'
  it_should_behave_like 'not_create'
  it_should_behave_like 'null_stringkey_stringvalue'
  it_should_behave_like 'persist_stringkey_stringvalue'
  it_should_behave_like 'returndifferent_stringkey_stringvalue'
  it_should_behave_like 'store_stringkey_stringvalue'
  it_should_behave_like 'transform_value'
end
