describe 'adapter_sqlite' do
  moneta_build do
    Moneta::Adapters::Sqlite.new(file: File.join(tempdir, "adapter_sqlite"))
  end

  moneta_specs ADAPTER_SPECS.without_concurrent
end
