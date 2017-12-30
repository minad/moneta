describe "standard_couch_with_expires" do
  moneta_store :Couch, db: 'standard_couch_with_expires', expires: true

  moneta_loader do |value|
    ::Marshal.load(value.unpack('m').first)
  end

  moneta_specs STANDARD_SPECS.without_increment.with_expires
end
