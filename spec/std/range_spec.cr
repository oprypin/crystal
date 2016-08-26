require "spec"
require "big_int"

struct RangeSpecIntWrapper
  include Comparable(self)

  getter value : Int32

  def initialize(@value)
  end

  def succ
    RangeSpecIntWrapper.new(@value + 1)
  end

  def <=>(other)
    value <=> other.value
  end

  def self.zero
    RangeSpecIntWrapper.new(0)
  end

  def +(other : RangeSpecIntWrapper)
    RangeSpecIntWrapper.new(value + other.value)
  end
end

describe "Range" do
  it "initialized with new method" do
    assert Range.new(1, 10) == 1..10
    assert Range.new(1, 10, false) == 1..10
    assert Range.new(1, 10, true) == 1...10
  end

  it "gets basic properties" do
    r = 1..5
    assert r.begin == 1
    assert r.end == 5
    assert r.excludes_end? == false

    r = 1...5
    assert r.begin == 1
    assert r.end == 5
    assert r.excludes_end? == true
  end

  it "includes?" do
    assert (1..5).includes?(1) == true
    assert (1..5).includes?(5) == true

    assert (1...5).includes?(1) == true
    assert (1...5).includes?(5) == false
  end

  it "does to_s" do
    assert (1...5).to_s == "1...5"
    assert (1..5).to_s == "1..5"
  end

  it "does inspect" do
    assert (1...5).inspect == "1...5"
  end

  it "is empty with .. and begin > end" do
    assert (1..0).to_a.empty? == true
  end

  it "is empty with ... and begin > end" do
    assert (1...0).to_a.empty? == true
  end

  it "is not empty with .. and begin == end" do
    assert (1..1).to_a == [1]
  end

  it "is not empty with ... and begin.succ == end" do
    assert (1...2).to_a == [1]
  end

  describe "sum" do
    it "called with no block is specialized for performance" do
      assert (1..3).sum == 6
      assert (1...3).sum == 3
      assert (BigInt.new("1")..BigInt.new("1 000 000 000")).sum == BigInt.new("500 000 000 500 000 000")
      assert (1..3).sum(4) == 10
      assert (3..1).sum(4) == 4
      assert (1..11).step(2).sum == 36
      assert (1...11).step(2).sum == 25
      assert (BigInt.new("1")..BigInt.new("1 000 000 000")).step(2).sum == BigInt.new("250 000 000 000 000 000")
    end

    it "is equivalent to Enumerable#sum" do
      assert (1..3).sum { |x| x * 2 } == 12
      assert (1..3).step(2).sum { |x| x * 2 } == 8
      assert (RangeSpecIntWrapper.new(1)..RangeSpecIntWrapper.new(3)).sum == RangeSpecIntWrapper.new(6)
      assert (RangeSpecIntWrapper.new(1)..RangeSpecIntWrapper.new(3)).step(2).sum == RangeSpecIntWrapper.new(4)
    end
  end

  describe "bsearch" do
    it "Int" do
      ary = [3, 4, 7, 9, 12]
      assert (0...ary.size).bsearch { |i| ary[i] >= 2 } == 0
      assert (0...ary.size).bsearch { |i| ary[i] >= 4 } == 1
      assert (0...ary.size).bsearch { |i| ary[i] >= 6 } == 2
      assert (0...ary.size).bsearch { |i| ary[i] >= 8 } == 3
      assert (0...ary.size).bsearch { |i| ary[i] >= 10 } == 4
      assert (0...ary.size).bsearch { |i| ary[i] >= 100 } == nil
      assert (0...ary.size).bsearch { |i| true } == 0
      assert (0...ary.size).bsearch { |i| false } == nil

      ary = [0, 100, 100, 100, 200]
      assert (0...ary.size).bsearch { |i| ary[i] >= 100 } == 1

      assert (0_i8..10_i8).bsearch { |x| x >= 10 } == 10_i8
      assert (0_i8...10_i8).bsearch { |x| x >= 10 } == nil
      assert (-10_i8...10_i8).bsearch { |x| x >= -5 } == -5_i8

      assert (0_u8..10_u8).bsearch { |x| x >= 10 } == 10_u8
      assert (0_u8...10_u8).bsearch { |x| x >= 10 } == nil
      assert (0_u32..10_u32).bsearch { |x| x >= 10 } == 10_u32
      assert (0_u32...10_u32).bsearch { |x| x >= 10 } == nil

      assert (BigInt.new("-10")...BigInt.new("10")).bsearch { |x| x >= -5 } == BigInt.new("-5")
    end

    it "Float" do
      inf = Float64::INFINITY
      assert (0.0...100.0).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.not_nil!.close?(10.0, 0.0001)
      assert (0.0...inf).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.not_nil!.close?(10.0, 0.0001)
      assert (-inf..100.0).bsearch { |x| x >= 0 || Math.log(-x / 10) < 0 }.not_nil!.close?(-10.0, 0.0001)
      assert (-inf..inf).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.not_nil!.close?(10.0, 0.0001)
      assert (-inf..5).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.nil?

      assert (-inf..10).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.not_nil!.close?(10.0, 0.0001)
      assert (inf...10).bsearch { |x| x > 0 && Math.log(x / 10) >= 0 }.nil?

      assert (-inf..inf).bsearch { false }.nil?
      assert (-inf..inf).bsearch { true } == -inf

      assert (0..inf).bsearch { |x| x == inf } == inf
      assert (0...inf).bsearch { |x| x == inf }.nil?

      v = (0.0..1.0).bsearch { |x| x > 0 }.not_nil!
      assert v.close?(0, 0.0001)
      assert (0 < v) == true

      assert (-1.0..0.0).bsearch { |x| x >= 0 } == 0.0
      assert (-1.0...0.0).bsearch { |x| x >= 0 }.nil?

      assert (0.0..inf).bsearch { |x| Math.log(x) >= 0 }.not_nil!.close?(1.0, 0.0001)

      assert (0.0..10).bsearch { |x| x >= 3.5 }.not_nil!.to_f.close?(3.5, 0.0001)
      assert (0..10.0).bsearch { |x| x >= 3.5 }.not_nil!.to_f.close?(3.5, 0.0001)

      assert (0_f32..5_f32).bsearch { |x| x >= 5_f32 }.not_nil!.close?(5_f32, 0.0001_f32)
      assert (0_f32...5_f32).bsearch { |x| x >= 5_f32 }.nil?
      assert (0_f32..5.0).bsearch { |x| x >= 5.0 }.not_nil!.close?(5.0, 0.0001)
      assert (0..5.0_f32).bsearch { |x| x >= 5.0 }.not_nil!.to_f.close?(5.0, 0.0001)

      inf32 = Float32::INFINITY
      assert (0..inf32).bsearch { |x| x == inf32 } == inf32
      assert (0_f32..inf).bsearch { |x| x == inf } == inf
      assert (0.0..inf32).bsearch { |x| x == inf32 } == inf32
      assert (0_f32...5_f32).bsearch { |x| x >= 5_f32 }.nil?
    end
  end

  describe "each" do
    it "gives correct values with inclusive range" do
      range = -1..3
      arr = [] of Int32
      range.each { |x| arr << x }
      assert arr == [-1, 0, 1, 2, 3]
    end

    it "gives correct values with exclusive range" do
      range = 'a'...'c'
      arr = [] of Char
      range.each { |x| arr << x }
      assert arr == ['a', 'b']
    end

    it "is empty with empty inclusive range" do
      range = 0..-1
      any = false
      range.each { any = true }
      assert any == false
    end
  end

  describe "reverse_each" do
    it "gives correct values with inclusive range" do
      range = 'a'..'c'
      arr = [] of Char
      range.reverse_each { |x| arr << x }
      assert arr == ['c', 'b', 'a']
    end

    it "gives correct values with exclusive range" do
      range = -1...3
      arr = [] of Int32
      range.reverse_each { |x| arr << x }
      assert arr == [2, 1, 0, -1]
    end

    it "is empty with empty inclusive range" do
      range = 0..-1
      any = false
      range.reverse_each { any = true }
      assert any == false
    end
  end

  describe "each iterator" do
    it "does next with inclusive range" do
      a = 1..3
      iter = a.each
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next == 3
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "does next with exclusive range" do
      r = 1...3
      iter = r.each
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "cycles" do
      assert (1..3).cycle.first(8).join == "12312312"
    end

    it "is empty with .. and begin > end" do
      assert (1..0).each.to_a.empty? == true
    end

    it "is empty with ... and begin > end" do
      assert (1...0).each.to_a.empty? == true
    end

    it "is not empty with .. and begin == end" do
      assert (1..1).each.to_a == [1]
    end

    it "is not empty with ... and begin.succ == end" do
      assert (1...2).each.to_a == [1]
    end
  end

  describe "reverse_each iterator" do
    it "does next with inclusive range" do
      a = 1..3
      iter = a.reverse_each
      assert iter.next == 3
      assert iter.next == 2
      assert iter.next == 1
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 3
    end

    it "does next with exclusive range" do
      r = 1...3
      iter = r.reverse_each
      assert iter.next == 2
      assert iter.next == 1
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 2
    end

    it "reverse cycles" do
      assert (1..3).reverse_each.cycle.first(8).join == "32132132"
    end

    it "is empty with .. and begin > end" do
      assert (1..0).reverse_each.to_a.empty? == true
    end

    it "is empty with ... and begin > end" do
      assert (1...0).reverse_each.to_a.empty? == true
    end

    it "is not empty with .. and begin == end" do
      assert (1..1).reverse_each.to_a == [1]
    end

    it "is not empty with ... and begin.succ == end" do
      assert (1...2).reverse_each.to_a == [1]
    end
  end

  describe "step iterator" do
    it "does next with inclusive range" do
      a = 1..5
      iter = a.step(2)
      assert iter.next == 1
      assert iter.next == 3
      assert iter.next == 5
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "does next with exclusive range" do
      a = 1...5
      iter = a.step(2)
      assert iter.next == 1
      assert iter.next == 3
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "does next with exclusive range (2)" do
      a = 1...6
      iter = a.step(2)
      assert iter.next == 1
      assert iter.next == 3
      assert iter.next == 5
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "is empty with .. and begin > end" do
      assert (1..0).step(1).to_a.empty? == true
    end

    it "is empty with ... and begin > end" do
      assert (1...0).step(1).to_a.empty? == true
    end

    it "is not empty with .. and begin == end" do
      assert (1..1).step(1).to_a == [1]
    end

    it "is not empty with ... and begin.succ == end" do
      assert (1...2).step(1).to_a == [1]
    end
  end

  it "clones" do
    range = [1]..[2]
    clone = range.clone
    assert clone == range
    assert !clone.begin.same?(range.begin)
    assert !clone.end.same?(range.end)
  end
end
