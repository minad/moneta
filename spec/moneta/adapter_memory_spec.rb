describe 'adapter_memory' do
  moneta_build do
    Moneta::Adapters::Memory.new
  end

  moneta_specs STANDARD_SPECS.without_transform.returnsame.without_persist
end
