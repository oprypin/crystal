require "spec"
require "big_int"

module StructSpec
  struct TestClass
    @x : Int32
    @y : String

    def initialize(@x, @y)
    end
  end

  struct BigIntWrapper
    @value : BigInt

    def initialize(@value : BigInt)
    end
  end

  struct DupCloneStruct
    property x, y

    def initialize
      @x = 1
      @y = [1, 2, 3]
    end

    def_clone
  end
end

describe "Struct" do
  it "does to_s" do
    s = StructSpec::TestClass.new(1, "hello")
    assert s.to_s == %(StructSpec::TestClass(@x=1, @y="hello"))
  end

  it "does ==" do
    s = StructSpec::TestClass.new(1, "hello")
    assert s == s
  end

  it "does hash" do
    s = StructSpec::TestClass.new(1, "hello")
    assert s.hash == 31 + "hello".hash
  end

  it "does hash for struct wrapper (#1940)" do
    assert StructSpec::BigIntWrapper.new(BigInt.new(0)).hash == 0
  end

  it "does dup" do
    original = StructSpec::DupCloneStruct.new
    duplicate = original.dup
    assert duplicate.x == original.x
    assert duplicate.y.same?(original.y)

    original.x = 10
    assert duplicate.x != 10
  end

  it "clones with def_clone" do
    original = StructSpec::DupCloneStruct.new
    clone = original.clone
    assert clone.x == original.x
    assert !clone.y.same?(original.y)
    assert clone.y == original.y

    original.x = 10
    assert clone.x != 10
  end
end
