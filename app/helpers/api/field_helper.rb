module Api::FieldHelper
  def field_parse(collection, site_params)
    properties_params = site_params["properties"]
    field_codes = properties_params.keys
    collection.fields.where(code: field_codes).find_each(batch_size: 100) do |field|
      properties_params["#{field.code}"] = field.parse(properties_params["#{field.code}"])
    end
    site_params["properties"] = properties_params
    return site_params
  end

end
