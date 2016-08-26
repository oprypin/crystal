require "spec"

class SafeIndexable
  include Indexable(Int32)

  getter size

  def initialize(@size : Int32)
  end

  def unsafe_at(i)
    raise IndexError.new unless 0 <= i < size
    i
  end
end

describe Indexable do
  it "does index with big negative offset" do
    indexable = SafeIndexable.new(3)
    assert indexable.index(0, -100).nil?
  end

  it "does index with big offset" do
    indexable = SafeIndexable.new(3)
    assert indexable.index(0, 100).nil?
  end

  it "does rindex with big negative offset" do
    indexable = SafeIndexable.new(3)
    assert indexable.rindex(0, -100).nil?
  end

  it "does rindex with big offset" do
    indexable = SafeIndexable.new(3)
    assert indexable.rindex(0, 100).nil?
  end
end
