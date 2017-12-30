describe 'transformer_ox' do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :ox, value: :ox
      adapter :Memory
    end
  end

  moneta_loader do |value|
    ::Ox.parse_obj(value)
  end
  
  moneta_specs TRANSFORMER_SPECS

  it 'compile transformer class' do
    store.should_not be_nil
    Moneta::Transformer::OxKeyOxValue.should_not be_nil
  end
end
