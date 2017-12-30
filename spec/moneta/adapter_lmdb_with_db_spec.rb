describe 'adapter_lmdb_with_db' do
  moneta_build do
    Moneta::Adapters::LMDB.new(dir: File.join(tempdir, "adapter_lmdb"), db: "adapter_lmdb_with_db")
  end

  moneta_specs ADAPTER_SPECS.without_concurrent
end
