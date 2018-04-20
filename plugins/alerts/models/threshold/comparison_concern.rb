module Threshold::ComparisonConcern
  extend ActiveSupport::Concern

  def eq(a, b)
    a == b || a.to_f == b.to_f
  end

  # eqi - equal ignore case operator
  def eqi(a, b)
    a.casecmp(b) == 0
  end

  def lt(a, b)
    a.to_f < b.to_f
  end

  def lte(a, b)
    a.to_f <= b.to_f
  end

  def gt(a, b)
    a.to_f > b.to_f
  end

  def gte(a, b)
    a.to_f >= b.to_f
  end

  def con(a, b)
    not a.scan(/#{b}/i).empty?
  end
end
