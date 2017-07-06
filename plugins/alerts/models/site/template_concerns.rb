module Site::TemplateConcerns
  extend ActiveSupport::Concern

  def get_template_value_hash
    template_value = properties_with_code_ref
    template_value["Site Name"] = self.name
    template_value
  end
end
