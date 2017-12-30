describe 'adapter_activerecord_existing_connection' do
  before :all do
    require 'active_record'

    ActiveRecord::Base.establish_connection adapter: (defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql2'),
                                            database: 'moneta',
                                            username: 'root'
  end

  moneta_build do
    Moneta::Adapters::ActiveRecord.new(table: 'adapter_activerecord_existing_connection')
  end

  moneta_specs ADAPTER_SPECS
end
