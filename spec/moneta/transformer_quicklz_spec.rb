describe 'transformer_quicklz' do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :quicklz
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::QuickLZ.decompress(value)
  end

  moneta_specs TRANSFORMER_SPECS.stringvalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::QuicklzValue.should_not be_nil
  end
end
