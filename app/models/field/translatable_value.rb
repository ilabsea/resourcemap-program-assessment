module Field::TranslatableValue
  def type
    if self.kind == "numeric"
      return self.config && self.config["allows_decimals"] == "true" ? "float" : "int"
    else
      return self.kind
    end
  end

  def translate_value(value)
    field_type = self.type
    if field_type == "int"
      value.to_i
    elsif field_type == "hierarchy"
      #[{:id=>"1", :name=>"PHD"}, {:id=>"2", :name=>"OD"}
      self.hierarchy_options.each do |option|
        return option[:name] if option[:id] == value
      end
      "#{value} not found in hierarchy"
    elsif field_type == "location"
      # config: {"locations"=>[
      #  {"code"=>"100", "name"=>"កាកា Leak", "latitude"=>"12.7237", "longitude"=>"104.893997"},
      #  {"code"=>"200", "name"=>"កណ្តាល", "latitude"=>"13.8067", "longitude"=>"104.958"}]
      self.config["locations"].each do |location|
        return location["name"] if location["code"] == value
      end
      "#{value} not found in locations"
    elsif field_type == "select_one"
      #config: {"options"=>[
      # {"id"=>1, "code"=>"1", "label"=>"SMP"},
      # {"id"=>2, "code"=>"2", "label"=>"THR"}]}
      self.config["options"].each do |option|
        test_options = option.with_indifferent_access
        return test_options["label"] if test_options["id"].to_s == value.to_s
      end
      "#{value} is not found in options"

    elsif field_type == "yes_no"
      value == "T" ? "Yes" : "No"
    else
      value
    end
  end
end
