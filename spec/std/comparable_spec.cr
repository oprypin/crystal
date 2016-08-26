require "spec"

class ComparableTestClass
  include Comparable(Int)

  def initialize(@value : Int32)
  end

  def <=>(other : Int)
    @value <=> other
  end
end

describe Comparable do
  it "can compare against Int (#2461)" do
    obj = ComparableTestClass.new(4)
    assert (obj == 3) == false
    assert (obj < 3) == false
    assert (obj > 3) == true
  end
end
