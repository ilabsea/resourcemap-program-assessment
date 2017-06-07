require 'spec_helper'

describe ReportQuerySearchResult do
  let!(:collection) { Collection.make }

  context 'with group by fields' do
    let(:report_query) {
      ReportQuery.make(name: "3 fields",
      condition_fields: [
        {"id"=>"1", "field_id"=>"1017", "operator"=>"=", "value"=>"3"},
        {"id"=>"2", "field_id"=>"1019", "operator"=>">", "value"=>"3"},
        {"id"=>"3", "field_id"=>"1020", "operator"=>">", "value"=>"4"}],
      group_by_fields: ["1017", "1018", "1022"],
      aggregate_fields: [
        {"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"},
        {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}],
      condition: "1 and ( 2 or 3 )",
      collection_id: collection.id)}

    let(:elastic_result) do
      {
        "3.0_district 5 _1019"=>{
          "term" => {
            "buckets" => [
              { 'key' =>  '2012.0', 'term' =>  { "count"=>2, "min"=>3.0, "max"=>4.0, "sum"=>7.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 4 _1019"=>{
          "term" => {
            "buckets" => [
              { 'key' => '2015.0', 'term' =>  { "count"=>1, "min"=>2.0, "max"=>2.0, "sum"=>2.0 } },
              { 'key' => '2014.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } },
              { 'key' =>  '2013.0', 'term' => { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 2 _1019"=>{
          "term" => {
            "buckets" => [
              { 'key' =>  '2015.0', 'term' =>  { "count"=>1, "min"=>1.0, "max"=>1.0, "sum"=>1.0 } },
              { 'key' =>  '2012.0', 'term' =>  { "count"=>1, "min"=>2.0, "max"=>2.0, "sum"=>2.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 3 _1019"=>{
          "term" => {
            "buckets" => [
              { 'key' =>  '2012.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 1 _1019"=>{
          "term" => {
            "buckets" => [
              { 'key' =>  '2015.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 5 _1020"=> {
          "term" => {
            "buckets" => [
              { 'key' =>  '2012.0', 'term' =>  { "count"=>2, "min"=>1.0, "max"=>5.0, "sum"=>6.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>3.0, "max"=>3.0, "sum"=>3.0 } },
            ]
          }
        },
        "3.0_district 4 _1020"=>{
          "term" => {
            "buckets" => [
              { 'key' =>  '2015.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } },
              { 'key' =>  '2014.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } },
              { 'key' =>  '2013.0', 'term' =>  { "count"=>1, "min"=>2.0, "max"=>2.0, "sum"=>2.0 } }
            ]
          }
        },
        "3.0_district 2 _1020"=> {
          "term" => {
            "buckets" => [
              { 'key' =>  '2015.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } },
              { 'key' =>  '2012.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } }
            ]
          }
        },
        "3.0_district 3 _1020"=> {
          "term" => {
            "buckets" => [
              { 'key' =>  '2012.0', 'term' =>  { "count"=>1, "min"=>5.0, "max"=>5.0, "sum"=>5.0 } },
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>4.0, "max"=>4.0, "sum"=>4.0 } }
            ]
          }
        },
        "3.0_district 1 _1020"=> {
          "term" => {
            "buckets" => [
              { 'key' =>  '2011.0', 'term' =>  { "count"=>1, "min"=>1.0, "max"=>1.0, "sum"=>1.0 } }
            ]
          }
        }
      }
    end

    let(:report_query_result) { ReportQuerySearchResult.new(report_query, elastic_result) }
    describe '#transform' do
      it 'return an array with head as field names and body as value' do

        query_result = { "3.0___district 5 ___2012.0"=>{"1019"=>7.0, "1020"=>6.0},
                         "3.0___district 5 ___2011.0"=>{"1019"=>4.0, "1020"=>3.0},
                         "3.0___district 4 ___2015.0"=>{"1019"=>2.0, "1020"=>5.0},
                         "3.0___district 4 ___2014.0"=>{"1019"=>5.0, "1020"=>4.0}
                       }

        privince_field = Field::NumericField.make name: 'Province'
        district_field = Field::TextField.make name: 'District'
        year_field = Field::NumericField.make name: 'Year'
        house_hold_field = Field::NumericField.make(name: 'Household', config: { "allows_decimals" => true})
        women_field = Field::NumericField.make name: 'Women affected'

        hash_mapping_result = {"1017" => privince_field,
                               "1018" => district_field,
                               "1022" => year_field,
                               "1019" => house_hold_field,
                               "1020" => women_field
                             }
        report_query_result.stub(:hash_mapping) {hash_mapping_result}
        table_result = report_query_result.transform(query_result)

        expected = [["Province", "District", "Year", "Household", "Women affected"],
                    [3, "district 5 ", 2012, 7.0, 6],
                    [3, "district 5 ", 2011, 4.0, 3],
                    [3, "district 4 ", 2015, 2.0, 5],
                    [3, "district 4 ", 2014, 5.0, 4]]

        expect(table_result).to eq expected
      end
    end

    describe "#agg_function_types" do
      it "return aggregate function" do
        expect(report_query_result.agg_function_types).to eq({"1019"=>"sum", "1020"=>"sum"} )
      end
    end

    describe '#normalize' do
      context 'with 3 group by fields' do
        it "result a hash result" do
           expected = {
             "2012.0"=>{"3.0_district 5 _1019"=>nil, "3.0_district 2 _1019"=>nil, "3.0_district 3 _1019"=>nil, "3.0_district 5 _1020"=>nil, "3.0_district 2 _1020"=>nil, "3.0_district 3 _1020"=>nil},
             "2011.0"=>{"3.0_district 5 _1019"=>nil, "3.0_district 2 _1019"=>nil, "3.0_district 3 _1019"=>nil, "3.0_district 5 _1020"=>nil, "3.0_district 2 _1020"=>nil, "3.0_district 3 _1020"=>nil, "3.0_district 1 _1020"=>nil},
             "2015.0"=>{"3.0_district 4 _1019"=>nil, "3.0_district 2 _1019"=>nil, "3.0_district 1 _1019"=>nil, "3.0_district 4 _1020"=>nil, "3.0_district 2 _1020"=>nil}, "2014.0"=>{"3.0_district 4 _1019"=>nil, "3.0_district 4 _1020"=>nil},
             "2013.0"=>{"3.0_district 4 _1019"=>nil, "3.0_district 4 _1020"=>nil}}

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
                            {"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"},
                            {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}],
                          condition: "",
                          collection_id: collection.id})
      end

      let(:elastic_result) do
        {
          "1019"=> { "count"=>100, "sum"=>294.0, "min"=>1.0, "max"=>5.0 },
          "1020"=>{ "count"=>100, "sum"=>295.0, "min"=>1.0, "max"=>5.0 }
        }
      end
      let(:report_query_result) { ReportQuerySearchResult.new(report_query, elastic_result) }
      it "return a hash with empty key and value of aggregator" do
        expected = {""=>{"1019"=>294.0, "1020"=>295.0}}
        result = report_query_result.normalize
        expect(result).to eq expected
      end
    end
  end

end
