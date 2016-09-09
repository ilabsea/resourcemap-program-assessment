require 'spec_helper'

describe ReportQueryResult do

  context 'with group by fields' do
    let(:report_query) { ReportQuery.make(name: "3 fields",
                                          condition_fields: [
                                            {"id"=>"1", "field_id"=>1017, "operator"=>"=", "value"=>"3"},
                                            {"id"=>"2", "field_id"=>1019, "operator"=>">", "value"=>"3"},
                                            {"id"=>"3", "field_id"=>1020, "operator"=>">", "value"=>"4"}],
                                          group_by_fields: [1017, 1018, 1022],
                                          aggregate_fields: [
                                            {"id"=>"1", "field_id"=>1019, "aggregator"=>"sum"},
                                            {"id"=>2, "field_id"=>1020, "aggregator"=>"sum"}],
                                          condition: "1 and ( 2 or 3 )",
                                          collection_id: 219)}
    let(:elastic_result) do
      {"3.0_district 5 _1019"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2012.0,
            "count"=>2,
            "total_count"=>2,
            "min"=>3.0,
            "max"=>4.0,
            "total"=>7.0,
            "mean"=>3.5},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 4 _1019"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>2.0,
            "max"=>2.0,
            "total"=>2.0,
            "mean"=>2.0},
           {"term"=>2014.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0},
           {"term"=>2013.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 2 _1019"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>1.0,
            "max"=>1.0,
            "total"=>1.0,
            "mean"=>1.0},
           {"term"=>2012.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>2.0,
            "max"=>2.0,
            "total"=>2.0,
            "mean"=>2.0},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 3 _1019"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2012.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 1 _1019"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 5 _1020"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2012.0,
            "count"=>2,
            "total_count"=>2,
            "min"=>1.0,
            "max"=>5.0,
            "total"=>6.0,
            "mean"=>3.0},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>3.0,
            "max"=>3.0,
            "total"=>3.0,
            "mean"=>3.0}]},
       "3.0_district 4 _1020"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0},
           {"term"=>2014.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0},
           {"term"=>2013.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>2.0,
            "max"=>2.0,
            "total"=>2.0,
            "mean"=>2.0}]},
       "3.0_district 2 _1020"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0},
           {"term"=>2012.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0}]},
       "3.0_district 3 _1020"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2012.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>5.0,
            "max"=>5.0,
            "total"=>5.0,
            "mean"=>5.0},
           {"term"=>2011.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>4.0,
            "max"=>4.0,
            "total"=>4.0,
            "mean"=>4.0}]},
       "3.0_district 1 _1020"=>
        {"_type"=>"terms_stats",
         "missing"=>0,
         "terms"=>
          [{"term"=>2015.0,
            "count"=>1,
            "total_count"=>1,
            "min"=>1.0,
            "max"=>1.0,
            "total"=>1.0,
            "mean"=>1.0}]
        }
      }
    end

    let(:report_query_result) { ReportQueryResult.new(report_query, elastic_result) }
    describe "#agg_function_types" do
      it "return aggregate function" do
        expect(report_query_result.agg_function_types).to eq({"1019"=>"total", "1020"=>"total"} )
      end
    end

    describe '#normalize' do
      context 'with 3 group by fields' do
        it "result a hash result" do
          expected = { "3.0_district 5 _2012.0"=>{"1019"=>7.0, "1020"=>6.0},
                       "3.0_district 5 _2011.0"=>{"1019"=>4.0, "1020"=>3.0},
                       "3.0_district 4 _2015.0"=>{"1019"=>2.0, "1020"=>5.0},
                       "3.0_district 4 _2014.0"=>{"1019"=>5.0, "1020"=>4.0},
                       "3.0_district 4 _2013.0"=>{"1019"=>4.0, "1020"=>2.0},
                       "3.0_district 2 _2015.0"=>{"1019"=>1.0, "1020"=>5.0},
                       "3.0_district 2 _2012.0"=>{"1019"=>2.0, "1020"=>5.0},
                       "3.0_district 2 _2011.0"=>{"1019"=>4.0, "1020"=>5.0},
                       "3.0_district 3 _2012.0"=>{"1019"=>4.0, "1020"=>5.0},
                       "3.0_district 3 _2011.0"=>{"1019"=>4.0, "1020"=>4.0},
                       "3.0_district 1 _2015.0"=>{"1019"=>4.0, "1020"=>1.0}
                     }

          result = report_query_result.normalize
          expect(result).to eq expected
        end
      end
    end

    context 'without group by field' do
      let(:report_query) do
        ReportQuery.make({name: "0 field",
                          condition_fields: [],
                          group_by_fields: [],
                          aggregate_fields: [
                            {"id"=>1, "field_id"=>1019, "aggregator"=>"sum"},
                            {"id"=>2, "field_id"=>1020, "aggregator"=>"sum"}],
                          condition: "",
                          collection_id: 219})
      end

      let(:elastic_result) do
        {"1019"=>
          {"_type"=>"statistical",
           "count"=>100,
           "total"=>294.0,
           "min"=>1.0,
           "max"=>5.0,
           "mean"=>2.94,
           "sum_of_squares"=>1076.0,
           "variance"=>2.1164,
           "std_deviation"=>1.4547852075134666},
         "1020"=>
          {"_type"=>"statistical",
           "count"=>100,
           "total"=>295.0,
           "min"=>1.0,
           "max"=>5.0,
           "mean"=>2.95,
           "sum_of_squares"=>1083.0,
           "variance"=>2.1275,
           "std_deviation"=>1.4585952145814822}
         }
      end
      let(:report_query_result) { ReportQueryResult.new(report_query, elastic_result) }
      it "return a hash with empty key and value of aggregator" do
        expected = {""=>{"1019"=>294.0, "1020"=>295.0}}
        result = report_query_result.normalize
        expect(result).to eq expected
      end
    end


  end




end
