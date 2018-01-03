#!/bin/env ruby
# encoding: utf-8
class FieldMock

  def self.create(collection_id, layer_id, type, index)
    case type
    when "text"
      Field.create(name: "Text_#{index}", code: "Text_#{index}", kind: "text", ord: index, collection_id: collection_id, layer_id: layer_id)
    when "numeric"
      Field.create(name: "Numeric_#{index}", code: "Numeric_#{index}", kind: "numeric", ord: index, collection_id: collection_id, layer_id: layer_id)
    when "yes_no"
      Field.create(name: "YesNo_#{index}", code: "YesNo_#{index}", kind: "yes_no", ord: index, collection_id: collection_id, layer_id: layer_id)
    when "select_one"
      Field.create(name: "SelectOne_#{index}", code: "SelectOne_#{index}", kind: "select_one", ord: index,
                    config: {"options"=>   [{"id"=>1, "code"=>"one", "label"=>"One"},
                                        {"id"=>2, "code"=>"two", "label"=>"Two"},
                                        {"id"=>3, "code"=>"three", "label"=>"Three"}
                                      ]
                            }, collection_id: collection_id, layer_id: layer_id)
    when "select_many"
      Field.create(name: "SelectMany_#{index}", code: "SelectMany_#{index}", kind: "select_many", ord: index,
                  config: {"options" => [{"id"=>1, "code"=>"0", "label"=>"zero"},
                                     {"id"=>2, "code"=>"1", "label"=>"one"},
                                     {"id"=>3, "code"=>"2", "label"=>"two"},
                                     {"id"=>4, "code"=>"3", "label"=>"three"},
                                     {"id"=>5, "code"=>"4", "label"=>"four"}
                                   ]
                          }, collection_id: collection_id, layer_id: layer_id)
    when "hierarchy"
      Field.create(name: "Hierarchy_#{index}", code: "Hierarchy_#{index}", kind: "hierarchy", ord: index,
                    config: {"hierarchy"=>[{"order"=>"1", "id"=>"1", "name"=>"ខេត្តបន្ទាយមានជ័យ"},
                                           {"order"=>"2", "id"=>"2", "name"=>"ខេត្តបាត់ដំបង"},
                                           {"order"=>"3", "id"=>"3", "name"=>"ខេត្តកំពង់ចាម"},
                                           {"order"=>"4", "id"=>"4", "name"=>"ខេត្តកំពង់ឆ្នាំង"},
                                           {"order"=>"5", "id"=>"5", "name"=>"ខេត្តកំពង់ស្ពឺ"},
                                           {"order"=>"6", "id"=>"6", "name"=>"ខេត្តកំពង់ធំ"},
                                           {"order"=>"7", "id"=>"7", "name"=>"ខេត្តកំពត"},
                                           {"order"=>"8", "id"=>"8", "name"=>"ខេត្តកណ្ដាល"},
                                           {"order"=>"9", "id"=>"9", "name"=>"ខេត្តកោះកុង"},
                                           {"order"=>"10", "id"=>"10", "name"=>"ខេត្តក្រចេះ"},
                                           {"order"=>"11", "id"=>"11", "name"=>"ខេត្តមណ្ឌលគិរី"},
                                           {"order"=>"12", "id"=>"12", "name"=>"រាជធានីភ្នំពេញ"},
                                           {"order"=>"13", "id"=>"13", "name"=>"ខេត្តព្រះវិហារ"},
                                           {"order"=>"14", "id"=>"14", "name"=>"ខេត្តព្រៃវែង"},
                                           {"order"=>"15", "id"=>"15", "name"=>"ខេត្តពោធិ៍សាត់"},
                                           {"order"=>"16", "id"=>"16", "name"=>"ខេត្តរតនគិរី"},
                                           {"order"=>"17", "id"=>"17", "name"=>"ខេត្តសៀមរាប"},
                                           {"order"=>"18", "id"=>"18", "name"=>"ខេត្តព្រះសីហនុ"},
                                           {"order"=>"19", "id"=>"19", "name"=>"ខេត្តស្ទឹងត្រែង"},
                                           {"order"=>"20", "id"=>"20", "name"=>"ខេត្តស្វាយរៀង"},
                                           {"order"=>"21", "id"=>"21", "name"=>"ខេត្តតាកែវ"},
                                           {"order"=>"22", "id"=>"22", "name"=>"ខេត្តឧត្ដរមានជ័យ"},
                                           {"order"=>"23", "id"=>"23", "name"=>"ខេត្តកែប"},
                                           {"order"=>"24", "id"=>"24", "name"=>"ខេត្តប៉ៃលិន"},
                                           {"order"=>"25", "id"=>"25", "name"=>"ខេត្តត្បូងឃ្មុំ"}]
                            },collection_id: collection_id, layer_id: layer_id)
    when "date"
      Field.create(name: "Date_#{index}", code: "Date_#{index}", kind: "date", ord: index, collection_id: collection_id, layer_id: layer_id)
    else
      Field.create(name: "Text_#{index}", code: "Text_#{index}", kind: "text", ord: index, collection_id: collection_id, layer_id: layer_id)
    end
  end


  def self.value
    case type
    when "text"

    when "numeric"

    when "yes_no"

    when "select_one"

    when "select_many"

    when "hierarchy"

    when "date"

    else

    end
  end

end
