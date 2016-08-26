require "spec"

module ReferenceSpec
  class TestClass
    @x : Int32
    @y : String

    def initialize(@x, @y)
    end
  end

  class TestClassBase
  end

  class TestClassSubclass < TestClassBase
  end

  class DupCloneClass
    getter x, y

    def initialize
      @x = 1
      @y = [1, 2, 3]
    end

    def_clone
  end
end

describe "Reference" do
  it "compares reference to other reference" do
    o1 = Reference.new
    o2 = Reference.new
    assert (o1 == o1) == true
    assert (o1 == o2) == false
    assert (o1 == 1) == false
  end

  it "should not be nil" do
    assert Reference.new.nil? == false
  end

  it "should be false when negated" do
    assert (!Reference.new) == false
  end

  it "does inspect" do
    r = ReferenceSpec::TestClass.new(1, "hello")
    assert r.inspect == %(#<ReferenceSpec::TestClass:0x#{r.object_id.to_s(16)} @x=1, @y="hello">)
  end

  it "does to_s" do
    r = ReferenceSpec::TestClass.new(1, "hello")
    assert r.to_s == %(#<ReferenceSpec::TestClass:0x#{r.object_id.to_s(16)}>)
  end

  it "does inspect for class" do
    assert String.inspect == "String"
  end

  it "does to_s for class" do
    assert String.to_s == "String"
  end

  it "does to_s for class if virtual" do
    assert [ReferenceSpec::TestClassBase, ReferenceSpec::TestClassSubclass].to_s == "[ReferenceSpec::TestClassBase, ReferenceSpec::TestClassSubclass]"
  end

  it "returns itself" do
    x = "hello"
    assert x.itself.same?(x)
  end

  it "dups" do
    original = ReferenceSpec::DupCloneClass.new
    duplicate = original.dup
    assert !duplicate.same?(original)
    assert duplicate.x == original.x
    assert duplicate.y.same?(original.y)
  end

  it "clones with def_clone" do
    original = ReferenceSpec::DupCloneClass.new
    clone = original.clone
    assert !clone.same?(original)
    assert clone.x == original.x
    assert !clone.y.same?(original.y)
    assert clone.y == original.y
  end
end
