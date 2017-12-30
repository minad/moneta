describe 'transformer_snappy' do
  moneta_build do
    Moneta.build do
      use :Transformer, value: :snappy
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Snappy.inflate(value)
  end
  
  moneta_specs TRANSFORMER_SPECS.stringvalues_only

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::SnappyValue.should_not be_nil
  end
end
