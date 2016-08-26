require "spec"

class TupleSpecObj
  getter x : Int32

  def initialize(@x)
  end

  def clone
    TupleSpecObj.new(@x)
  end
end

describe "Tuple" do
  it "does size" do
    assert {1, 2, 1, 2}.size == 4
  end

  it "checks empty?" do
    assert Tuple.new.empty? == true
    assert {1}.empty? == false
  end

  it "does []" do
    a = {1, 2.5}
    i = 0
    assert a[i] == 1
    i = 1
    assert a[i] == 2.5
  end

  it "does [] raises index out of bounds" do
    a = {1, 2.5}
    i = 2
    expect_raises(IndexError) { a[i] }
    i = -1
    expect_raises(IndexError) { a[i] }
  end

  it "does []?" do
    a = {1, 2}
    assert a[1]? == 2
    assert a[2]?.nil?
  end

  it "does at" do
    a = {1, 2}
    assert a.at(1) == 2

    expect_raises(IndexError) { a.at(2) }

    assert a.at(2) { 3 } == 3
  end

  describe "values_at" do
    it "returns the given indexes" do
      assert {"a", "b", "c", "d"}.values_at(1, 0, 2) == {"b", "a", "c"}
    end

    it "raises when passed an invalid index" do
      expect_raises IndexError do
        {"a"}.values_at(10)
      end
    end

    it "works with mixed types" do
      assert {1, "a", 1.0, :a}.values_at(0, 1, 2, 3) == {1, "a", 1.0, :a}
    end
  end

  it "does ==" do
    a = {1, 2}
    b = {3, 4}
    c = {1, 2, 3}
    d = {1}
    e = {1, 2}
    assert a == a
    assert a == e
    assert a != b
    assert a != c
    assert a != d
  end

  it "does == with different types but same size" do
    assert {1, 2} == {1.0, 2.0}
  end

  it "does == with another type" do
    assert {1, 2} != 1
  end

  it "does compare" do
    a = {1, 2}
    b = {3, 4}
    c = {1, 6}
    d = {3, 5}
    e = {0, 8}
    assert [a, b, c, d, e].sort == [e, a, c, b, d]
    assert [a, b, c, d, e].min == e
  end

  it "does compare with different sizes" do
    a = {2}
    b = {1, 2, 3}
    c = {1, 2}
    d = {1, 1}
    e = {1, 1, 3}
    assert [a, b, c, d, e].sort == [d, e, c, b, a]
    assert [a, b, c, d, e].min == d
  end

  it "does to_s" do
    assert {1, 2, 3}.to_s == "{1, 2, 3}"
  end

  it "does each" do
    a = 0
    {1, 2, 3}.each do |i|
      a += i
    end
    assert a == 6
  end

  it "does dup" do
    r1, r2 = TupleSpecObj.new(10), TupleSpecObj.new(20)
    t = {r1, r2}
    u = t.dup
    assert u.size == 2
    assert u[0].same?(r1)
    assert u[1].same?(r2)
  end

  it "does clone" do
    r1, r2 = TupleSpecObj.new(10), TupleSpecObj.new(20)
    t = {r1, r2}
    u = t.clone
    assert u.size == 2
    assert u[0].x == r1.x
    assert !u[0].same?(r1)
    assert u[1].x == r2.x
    assert !u[1].same?(r2)
  end

  it "does Tuple.new" do
    assert Tuple.new(1, 2, 3) == {1, 2, 3}
    assert Tuple.new([1, 2, 3]) == {[1, 2, 3]}
  end

  it "does Tuple.from" do
    t = Tuple(Int32, Float64).from([1_i32, 2.0_f64])
    assert t == {1_i32, 2.0_f64}
    assert t.class == Tuple(Int32, Float64)

    expect_raises ArgumentError do
      Tuple(Int32).from([1, 2])
    end

    expect_raises(TypeCastError, /cast from String to Int32 failed/) do
      Tuple(Int32, String).from(["foo", 1])
    end
  end

  it "does Tuple#from" do
    t = {Int32, Float64}.from([1_i32, 2.0_f64])
    assert t == {1_i32, 2.0_f64}
    assert t.class == Tuple(Int32, Float64)

    expect_raises ArgumentError do
      {Int32}.from([1, 2])
    end

    expect_raises(TypeCastError, /cast from String to Int32 failed/) do
      {Int32, String}.from(["foo", 1])
    end
  end

  it "clones empty tuple" do
    assert Tuple.new.clone == Tuple.new
  end

  it "does iterator" do
    iter = {1, 2, 3}.each

    assert iter.next == 1
    assert iter.next == 2
    assert iter.next == 3
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1
  end

  it "does map" do
    tuple = {1, 2.5, "a"}
    tuple2 = tuple.map &.to_s
    assert tuple2.is_a?(Tuple) == true
    assert tuple2 == {"1", "2.5", "a"}
  end

  it "does reverse" do
    assert {1, 2.5, "a", 'c'}.reverse == {'c', "a", 2.5, 1}
  end

  it "does reverse_each" do
    str = ""
    {"a", "b", "c"}.reverse_each do |i|
      str += i
    end
    assert str == "cba"
  end

  describe "reverse_each iterator" do
    it "does next" do
      a = {1, 2, 3}
      iter = a.reverse_each
      assert iter.next == 3
      assert iter.next == 2
      assert iter.next == 1
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 3
    end
  end

  it "gets first element" do
    tuple = {1, 2.5}
    assert tuple.first == 1
    assert typeof(tuple.first) == Int32
  end

  it "gets first? element" do
    tuple = {1, 2.5}
    assert tuple.first? == 1

    assert Tuple.new.first?.nil?
  end

  it "gets last element" do
    tuple = {1, 2.5, "a"}
    assert tuple.last == "a"
    assert typeof(tuple.last) == String
  end

  it "gets last? element" do
    tuple = {1, 2.5, "a"}
    assert tuple.last? == "a"

    assert Tuple.new.last?.nil?
  end

  it "does comparison" do
    tuple1 = {"a", "a", "c"}
    tuple2 = {"a", "b", "c"}
    assert (tuple1 <=> tuple2) == -1
    assert (tuple2 <=> tuple1) == 1
  end

  it "does <=> for equality" do
    tuple1 = {0, 1}
    tuple2 = {0.0, 1}
    assert (tuple1 <=> tuple2) == 0
  end

  it "does <=> with the same beginning and different size" do
    tuple1 = {1, 2, 3}
    tuple2 = {1, 2}
    assert (tuple1 <=> tuple2) == 1
  end

  it "does types" do
    tuple = {1, 'a', "hello"}
    assert tuple.types.to_s == "Tuple(Int32, Char, String)"
  end

  it "does ===" do
    assert ({1, 2} === {1, 2}) == true
    assert ({1, 2} === {1, 3}) == false
    assert ({1, 2, 3} === {1, 2}) == false
    assert ({/o+/, "bar"} === {"fox", "bar"}) == true
    assert ({1, 2} === nil) == false
  end
end
