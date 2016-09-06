require 'spec_helper'

describe GroupByParser do
  let!(:field_with_distinct_values) do
   [
      { province: ['Kpc', 'Pp' ] },
      { year: [ 2016, 2017] },
      { district: ['Tektla', 'Beung kok', 'Krek'] }
    ]
  end

  let!(:agg_fields) do
    [
     {"id"=>"1", "field_id"=>"men", "aggregator"=>"sum"},
     {"id"=>"2", "field_id"=>"women", "aggregator"=>"sum"}
   ]
  end

  let(:group_by_parser) {
    GroupByParser.new(field_with_distinct_values, agg_fields)
  }

  it "set remaining fields for facet filtering " do
    remaining = [
      { province: ['Kpc', 'Pp' ] },
      { year: [ 2016, 2017] }]
    expect(group_by_parser.field_with_distinct_values).to eq remaining
  end

  describe "#combine_tags" do

    context "with empty group by field " do
      it 'return single field hash' do
        fields = []
        result = group_by_parser.combine_tags(fields)
        expect(result).to eq []
      end
    end

    context "with single group by field " do
      it 'return single field hash' do
        fields = [{ province: ['Kpc', 'Pp' ] }]
        result = group_by_parser.combine_tags(fields)
        expect(result).to eq [  { "province" => "Kpc" }, { "province" => "Pp"}]
      end
    end

    context "with more than multiple group by fields" do
      it 'return multiple field hash' do
        fields = [ { province: ['Kpc', 'Pp' ] },
                   { year: [ 2016, 2017] } ]
        result = [ {"province"=>"Kpc", "year"=>2016},
                     {"province"=>"Pp", "year"=>2016},
                     {"province"=>"Kpc", "year"=>2017},
                     {"province"=>"Pp", "year"=>2017}
                   ]
        expect(group_by_parser.combine_tags(fields)).to eq result
      end
    end

  end

  describe '#facet_filters' do
    it 'return facet filters for aggregate_fields' do
      result = { "Kpc_2016_men"=> {
                    "terms_stats"=>{"key_field"=>"district", "value_field"=>"men"},
                    "facet_filter"=>{
                      "bool"=>{
                        "must"=>[
                          {"term"=> { "province" => "Kpc"} },
                          {"term"=> {"year" => 2016} }
                        ]
                      }
                    }
                  },
                "Pp_2016_men"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"men"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Pp"}},
                        {"term"=>{"year"=>2016}}
                      ]
                    }
                  }
                },

                "Kpc_2017_men"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"men"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Kpc"}},
                        {"term"=>{"year"=>2017}}
                      ]
                    }
                  }
                },
                "Pp_2017_men"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"men"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Pp"}},
                        {"term"=>{"year"=>2017}}
                      ]
                    }
                  }
                },
                "Kpc_2016_women"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"women"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Kpc"}},
                        {"term"=>{"year"=>2016}}
                      ]
                    }
                  }
                },
                "Pp_2016_women"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"women"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Pp"}},
                        {"term"=>{"year"=>2016}}]}}},
                "Kpc_2017_women"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"women"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Kpc"}},
                        {"term"=>{"year"=>2017}}
                      ]
                    }
                  }
                },
                "Pp_2017_women"=>{
                  "terms_stats"=>{"key_field"=>"district", "value_field"=>"women"},
                  "facet_filter"=>{
                    "bool"=>{
                      "must"=>[
                        {"term"=>{"province"=>"Pp"}},
                        {"term"=>{"year"=>2017}}
                      ]
                    }
                  }
                }
              }
      expect(group_by_parser.facet_filters).to eq result
    end
  end

  describe "#facet_per_aggregator" do
    context "without facet field" do
      it "return term stats without facet filter" do
        result = {"terms_stats"=>{"key_field"=>"district", "value_field"=>"agg_field_id"}}
        expect(group_by_parser.facet_per_aggregator( 'agg_field_id', {})).to eq result
      end
    end

    context "with one facet field" do
      it "return term stats with facet filter" do
        result = {"terms_stats"=>{"key_field"=>"district", "value_field"=>"agg_field_id"},
                  "facet_filter"=>{"bool"=>
                                            {"must"=>[
                                                        {"term"=>{"province"=>"Kpc"}}
                                                    ]
                                            }
                                  }
                  }
        expect(group_by_parser.facet_per_aggregator( 'agg_field_id', { "province" => "Kpc" })).to eq result
      end
    end

    context "with two facet fields" do
      it "return term stats with facet filter" do
        result = {"terms_stats"=>{"key_field"=>"district", "value_field"=>"agg_field_id"},
                  "facet_filter"=>{"bool"=>
                                            {"must"=>[
                                                        {"term"=>{"province"=>"Kpc"}},
                                                        {"term"=>{"year"=>2016}}
                                                    ]
                                            }
                                  }
                  }
        expect(group_by_parser.facet_per_aggregator( 'agg_field_id', { "province" => "Kpc", "year" => 2016 })).to eq result
      end
    end

  end



end
