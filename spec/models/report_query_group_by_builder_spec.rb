require 'spec_helper'

describe ReportQueryGroupByBuilder do
  let!(:collection) { Collection.make }
  let!(:field_with_distinct_values) do
   [
      { "province" => ['Kpc', 'Pp' ] },
      { "year" => [ 2016, 2017] },
      { "district" => ['Tektla', 'Beung kok', 'Krek'] }
    ]
  end

  let!(:agg_fields) do
    [
     {"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"},
     {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}
   ]
  end

  let!(:report_query) { ReportQuery.create(name: "3 fields",
                                        condition_fields: [
                                          {"id"=>"1", "field_id"=>"1017", "operator"=>"=", "value"=>"3"},
                                          {"id"=>"2", "field_id"=> "1019", "operator"=>">", "value"=>"3"},
                                          {"id"=>"3", "field_id"=> "1020", "operator"=>">", "value"=>"4"}],
                                        group_by_fields: ["1017", "1018", "1022"],
                                        aggregate_fields: [
                                          {"id"=>"1", "field_id"=> "1019", "aggregator"=>"sum"},
                                          {"id"=>"2", "field_id"=> "1020", "aggregator"=>"sum"}],
                                        condition: "1 and ( 2 or 3 )",
                                        collection_id: collection.id)}

  let(:group_by_builder) {
    ReportQueryGroupByBuilder.new(report_query)
  }

  describe "#combine_tags" do
    context "with empty group by field" do
      it 'return single field hash' do
        result = group_by_builder.combine_tags([])
        expect(result).to eq []
      end
    end

    context "with single group by field" do
      it 'return single field hash' do
        fields = [{ "province" => ['Kpc', 'Pp' ] }]
        result = group_by_builder.combine_tags fields
        expect(result).to eq [  { "province" => "Kpc" }, { "province" => "Pp"}]
      end
    end

    context "with more than multiple group by fields" do
      it 'return multiple field hash' do
        fields = [ { "province" => ['Kpc', 'Pp' ] },
                   { "year" => [ 2016, 2017] } ]
        result = [ {"province"=>"Kpc", "year"=>2016},
                     {"province"=>"Pp", "year"=>2016},
                     {"province"=>"Kpc", "year"=>2017},
                     {"province"=>"Pp", "year"=>2017}
                   ]
        expect(group_by_builder.combine_tags(fields)).to eq result
      end
    end

  end

  describe '#facet_term_stats' do
    before(:each) do
      group_by_builder.stub(:distinct_value).with("1017").and_return({"province" => ['Kpc', 'Pp' ]})
      group_by_builder.stub(:distinct_value).with("1018").and_return({ "year" => [ 2016, 2017] })
    end

    it 'return facet filters for aggregate_fields' do
      result = {
        "Kpc___2016___1019"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}},
                {"term"=>{"properties.year"=>2016}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1019"}}
              }
            }
          }
        },
        "Pp___2016___1019"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Pp"}},
                {"term"=>{"properties.year"=>2016}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1019"}}
              }
            }
          }
        },
        "Kpc___2017___1019"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}},
                {"term"=>{"properties.year"=>2017}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1019"}}
              }
            }
          }
        },
        "Pp___2017___1019"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Pp"}},
                {"term"=>{"properties.year"=>2017}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1019"}}
              }
            }
          }
        },
        "Kpc___2016___1020"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}},
                {"term"=>{"properties.year"=>2016}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1020"}}
              }
            }
          }
        },
        "Pp___2016___1020"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Pp"}},
                {"term"=>{"properties.year"=>2016}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1020"}}
              }
            }
          }
        },
        "Kpc___2017___1020"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}},
                {"term"=>{"properties.year"=>2017}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1020"}}
              }
            }
          }
        },
        "Pp___2017___1020"=>{
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Pp"}},
                {"term"=>{"properties.year"=>2017}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.1020"}}
              }
            }
          }
        }
      }
      expect(group_by_builder.facet_term_stats).to eq result
    end
  end

  describe "#facet_term_stats_by_field" do
    context "without facet field" do
      it "return term stats without facet filter" do
        result = {
          "1022" => {
            'terms' => { 'field' => "properties.1022" },
            'aggs' => {
              'term' => { 'stats' => { 'field' => "properties.agg_field_id" } }
            }
          }
        }
        expect(group_by_builder.facet_term_stats_by_field( 'agg_field_id', {})).to eq result
      end
    end

    context "with one facet field" do
      it "return term stats with facet filter" do
        result = {
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.agg_field_id"}}
              }
            }
          }
        }

        expect(group_by_builder.facet_term_stats_by_field( 'agg_field_id', { "province" => "Kpc" })).to eq result
      end
    end

    context "with two facet fields" do
      it "return term stats with facet filter" do
        # result = {"terms_stats"=>{"key_field"=>"1022", "value_field"=>"agg_field_id"},
        #           "facet_filter"=>{"bool"=>
        #                                     {"must"=>[
        #                                                 {"term"=>{"province"=>"Kpc"}},
        #                                                 {"term"=>{"year"=>2016}}
        #                                             ]
        #                                     }
        #                           }
        #           }

        result = {
          "filter"=>{
            "bool"=>{
              "must"=>[
                {"term"=>{"properties.province"=>"Kpc"}},
                {"term"=>{"properties.year"=>2016}}
              ]
            }
          },
          "aggs"=>{
            "1022"=>{
              "terms"=>{"field"=>"properties.1022"},
              "aggs"=>{
                "term"=>{"stats"=>{"field"=>"properties.agg_field_id"}}
              }
            }
          }
        }

        expect(group_by_builder.facet_term_stats_by_field( 'agg_field_id', { "province" => "Kpc", "year" => 2016 })).to eq result
      end
    end
  end

  describe '.distinct_value_query' do
    it "return query for distinct_value for field" do
      group_by_builder.stub(:query_builder).and_return({ "query" => { "match_all" => {} }})
      result = group_by_builder.distinct_value_query("1018")
      expected = {
        "query"=>{"match_all"=>{}},
        "aggs" => {
          "1018" => {
            'terms' => {
              'field' => "properties.1018",
              'size' => Settings.max_aggregate_result_size.to_i
            }
          }
        }
      }
      # expected = {"query"=>{"match_all"=>{}}, "facets"=>{"1018"=>{"terms"=>{"field"=>"1018"}}}}
      expect(result).to eq expected
    end
  end


end
