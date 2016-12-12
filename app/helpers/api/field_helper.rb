module Api::FieldHelper
  def parse(collection, properties_params)
    #{\"1379\":1,\"1380\":\"\",\"1381\":\"test\"}"
    field_ids = properties_params.keys
    collection.fields.where(id: field_ids).find_each(batch_size: 100) do |field|
      properties_params["#{field.id}"] = field.parse(properties_params["#{field.id}"])
    end
    properties_params
  end

end
