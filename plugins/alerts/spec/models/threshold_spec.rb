require 'spec_helper'

describe Threshold do
  it { should belong_to :collection }
  it { should validate_presence_of(:ord) }
  it { should validate_presence_of(:color) }
  its(:conditions) { should eq([]) }

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:beds) { layer.numeric_fields.make id: 1, code: 'beds'}
  let!(:doctors) { layer.numeric_fields.make id: 2, code: 'doctors' }
  let!(:options) { [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}] }

  it "should convert conditions' value to int if the field is int" do
    threshold = collection.thresholds.make conditions: [ field: beds.es_code, op: :lt, value: '10' ]
    threshold.conditions[0][:value].should eq(10)
  end

  [
    { field: '1', op: :lt, value: '10', property_value: 9 },
    { field: '1', op: :lte, value: '10', property_value: 10 },
    { field: '1', op: :gt, value: '10', property_value: 11 },
    { field: '1', op: :gte, value: '10', property_value: 10 },
    { field: '1', op: :eq, value: '10', property_value: 10 }
  ].each do |hash|
    it "should throw :threshold with #{hash[:op].to_s} condition" do
      threshold = collection.thresholds.make conditions: [ hash ]
      expect { threshold.test({ hash[:field] => hash[:property_value] }) }.to throw_symbol :threshold, threshold
    end
  end

  describe "multiple conditions" do
    describe "all conditions" do 
      let!(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [ {field: beds.es_code, op: :gt, value: '10'}, {field: doctors.es_code, op: :lte, value: '2'} ] }

      it "should throw :threshold when all conditions are matched" do
        expect { threshold.test({beds.es_code => 11, doctors.es_code => 2}) }.to throw_symbol :threshold, threshold
      end

      it "should not throw when one condition is not matched" do
        expect { threshold.test({beds.es_code => 9, doctors.es_code => 2}) }.to_not throw_symbol
        expect { threshold.test({beds.es_code => 11, doctors.es_code => 3}) }.to_not throw_symbol
      end

      it "should not throw when no condition is matched" do
        expect { threshold.test({beds.es_code => 9, doctors.es_code => 3}) }.to_not throw_symbol
      end
    end

    describe "any conditions" do
      let!(:threshold) { collection.thresholds.make is_all_condition: false, conditions: [ {field: beds.es_code, op: :gt, value: '10'}, {field: doctors.es_code, op: :lte, value: '2'} ] }
      it "should throw when one condition is not matched" do
        expect { threshold.test({beds.es_code => 9, doctors.es_code => 2}) }.to throw_symbol :threshold, threshold
        expect { threshold.test({beds.es_code => 11, doctors.es_code => 3}) }.to throw_symbol :threshold, threshold
      end
    end
  end

  describe "should test text field" do
    let!(:field) { layer.text_fields.make code: 'txt' }

    context "for equality" do
      it "case sensitive" do
        threshold = collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: 'hello'}]
        expect { threshold.test({field.es_code => 'hello'}) }.to throw_symbol :threshold, threshold
        expect { threshold.test({field.es_code => 'HeLLo'}) }.to_not throw_symbol
      end

      it "ignore case" do
        threshold = collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eqi, value: 'hello'}]
        expect { threshold.test({field.es_code => 'hello'}) }.to throw_symbol :threshold, threshold
        expect { threshold.test({field.es_code => 'HeLLo'}) }.to throw_symbol :threshold, threshold
      end
    end

    context "for inclusion" do
      let!(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :con, value: 'hello'}] }

      it "matched" do
        expect { threshold.test({field.es_code => 'This is hello world.'}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => 'This is my world.'}) }.to_not throw_symbol
      end

      it "case insensitive" do
        expect { threshold.test({field.es_code => 'HeLLo world.'}) }.to throw_symbol :threshold, threshold
      end
    end
  end

  it "should test select_one field for equality" do
    field = layer.select_one_fields.make code: 'one', config: {options: options}
    threshold = collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: 1}]

    expect { threshold.test({field.es_code => 1}) }.to throw_symbol :threshold, threshold
    expect { threshold.test({field.es_code => 2}) }.to_not throw_symbol
  end

  it "should test select_many field for equality" do
    field = layer.select_many_fields.make code: 'many', config: {options: options}
    threshold = collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: 2}]

    expect { threshold.test({field.es_code => 1}) }.to_not throw_symbol
    expect { threshold.test({field.es_code => 2}) }.to throw_symbol :threshold, threshold
  end

  describe "should test yes_no field for" do
    let(:field) { layer.yes_no_fields.make }

    describe "true" do
      let(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: true}] }

      it "matched" do
        expect { threshold.test({field.es_code => true}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => false}) }.to_not throw_symbol
      end

      it "null value" do
        expect { threshold.test({}) }.to_not throw_symbol
      end
    end

    describe "false" do
      let(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: false}] }

      it "matched" do
        expect { threshold.test({field.es_code => false}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => true}) }.to_not throw_symbol
      end

      it "null value" do
        expect { threshold.test({}) }.to throw_symbol :threshold, threshold
      end
    end
  end

  describe "should test numeric field for" do
    let(:field) { layer.numeric_fields.make }

    describe "equality" do
      let(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :eq, value: 50}] }

      it "matched" do
        expect { threshold.test({field.es_code => 50}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => 2}) }.to_not throw_symbol
      end

      it "null value" do
        expect { threshold.test({}) }.to_not throw_symbol
      end
    end

    describe "in-equality" do
     let(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :lt, value: 50}] }

      it "matched" do
        expect { threshold.test({field.es_code => 25}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => 55}) }.to_not throw_symbol
      end

      it "null value" do
        expect { threshold.test({}) }.to_not throw_symbol
      end
    end

    describe "field comparison" do
      let(:field_2) { layer.numeric_fields.make }
      let(:threshold) { collection.thresholds.make is_all_condition: true, conditions: [{field: field.es_code, op: :lt, value: 100, type: 'percentage', compare_field: field_2.es_code}] }

      it "matched" do
        expect { threshold.test({field.es_code => 25, field_2.es_code => 26}) }.to throw_symbol :threshold, threshold
      end

      it "not matched" do
        expect { threshold.test({field.es_code => 55, field_2.es_code => 50}) }.to_not throw_symbol
      end

      it "null value" do
        expect { threshold.test({}) }.to_not throw_symbol
      end
    end
  end
end
