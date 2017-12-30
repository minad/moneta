describe 'adapter_daybreak' do
  moneta_build do
    Moneta::Adapters::Daybreak.new(file: File.join(tempdir, "adapter_daybreak"))
  end

  moneta_specs ADAPTER_SPECS.without_multiprocess.returnsame
end
