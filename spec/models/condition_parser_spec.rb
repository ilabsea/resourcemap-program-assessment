require 'spec_helper'

describe ConditionParser do
  describe '.sanitize' do
    context 'with valid expression' do
      it "return true" do
        expr = "(1and2or(3and 4) and(5 or 6 or (7and8)) )"
        result = ConditionParser.sanitize(expr)
        expect(result).to eq "( 1 and 2 or ( 3 and 4 ) and ( 5 or 6 or ( 7 and 8 ) ) )"
      end
    end
  end

  describe '.parse' do
    context "single expression" do
      it "return parsed query" do
        condition = ConditionParser.new("1")
        result = condition.parse
        expect(result).to eq "1"
      end
    end

    context "expression without parentesis" do
      it "return parsed query" do
        condition = ConditionParser.new(" 1 or 2 and 3 or 4")
        result = condition.parse
        expected =  {"or"=>["1", {"and"=>["2", {"or"=>["3", "4"]}]}]}
        expect(result).to eq expected
      end
    end

    context "expression with complex parentesis" do
      it "return parsed query" do
        condition = ConditionParser.new(" 1 or ( ( 2 and 3 ) or 4 ) and 5")
        result = condition.parse
        expected =  {"or"=>["1", {"and"=>[{"or"=>[{"and"=>["2", "3"]}, "4"]}, "5"]}]}
        expect(result).to eq expected
      end
    end

    context "without block" do
      it "return parsed query" do
        condition = ConditionParser.new("( 1 or 2 ) and ( 3 or 4 )")
        result = condition.parse
        expected =  {"and"=>[{"or"=>["1", "2"]}, {"or"=>["3", "4"]}]}
        expect(result).to eq expected
      end
    end


    context "with a block of filter" do
      it "return parsed query translated to block result" do
        filters = [ { "key"=>"key1", "value"=>{"gt"=>10}, "type"=>"range", "condition_id"=> '1' },
                    { "key"=>"key2", "value"=>{"gt"=>10}, "type"=>"range", "condition_id"=> '2' },
                    { "key"=>"key3", "value"=>{"gt"=>10}, "type"=>"range", "condition_id"=> '3' },
                    { "key"=>"key4", "value"=>{"gt"=>10}, "type"=>"range", "condition_id"=> '4' }
                  ]
        condition = ConditionParser.new("( 1 or 2 ) and ( 3 or 4 )")

        result = condition.parse do |current_token|
          filter = filters.select {|f| f["condition_id"] == current_token}.first
          (filter && { filter["type"]=> { filter["key"] => filter["value"] }}) || nil
        end
        expected = {"and"=>[
                      {"or"=>[
                        {"range"=>{"key1"=>{"gt"=>10} } },
                        {"range"=>{"key2"=>{"gt"=>10} } } ] },
                      {"or"=>[
                        {"range"=>{"key3"=>{"gt"=>10}}},
                        {"range"=>{"key4"=>{"gt"=>10}}}]}
                    ]
                  }
        expect(result).to eq expected

      end
    end
  end

end
