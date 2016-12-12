module Api::FieldHelper
  def field_parse(collection, site_params)
    properties_params = site_params["properties"]
    field_ids = properties_params.keys
    collection.fields.where(id: field_ids).find_each(batch_size: 100) do |field|
      properties_params["#{field.id}"] = field.parse(properties_params["#{field.id}"])
    end
    site_params["properties"] = properties_params
    return site_params
  end

end
