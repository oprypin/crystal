require "spec"

alias RecursiveArray = Array(RecursiveArray)

class BadSortingClass
  include Comparable(self)

  def <=>(other)
    1
  end
end

describe "Array" do
  describe "new" do
    it "creates with default value" do
      ary = Array.new(5, 3)
      assert ary == [3, 3, 3, 3, 3]
    end

    it "creates with default value in block" do
      ary = Array.new(5) { |i| i * 2 }
      assert ary == [0, 2, 4, 6, 8]
    end

    it "raises on negative count" do
      expect_raises(ArgumentError, "negative array size") do
        Array.new(-1, 3)
      end
    end

    it "raises on negative capacity" do
      expect_raises(ArgumentError, "negative array size") do
        Array(Int32).new(-1)
      end
    end
  end

  describe "==" do
    it "compares empty" do
      assert ([] of Int32) == [] of Int32
      assert [1] != [] of Int32
      assert ([] of Int32) != [1]
    end

    it "compares elements" do
      assert [1, 2, 3] == [1, 2, 3]
      assert [1, 2, 3] != [3, 2, 1]
    end

    it "compares other" do
      a = [1, 2, 3]
      b = [1, 2, 3]
      c = [1, 2, 3, 4]
      d = [1, 2, 4]
      assert (a == b) == true
      assert (b == c) == false
      assert (a == d) == false
    end
  end

  it "does &" do
    assert ([1, 2, 3] & [] of Int32) == [] of Int32
    assert ([] of Int32 & [1, 2, 3]) == [] of Int32
    assert ([1, 2, 3] & [3, 2, 4]) == [2, 3]
    assert ([1, 2, 3, 1, 2, 3] & [3, 2, 4, 3, 2, 4]) == [2, 3]
    assert ([1, 2, 3, 1, 2, 3, nil, nil] & [3, 2, 4, 3, 2, 4, nil]) == [2, 3, nil]
  end

  it "does |" do
    assert ([1, 2, 3] | [5, 3, 2, 4]) == [1, 2, 3, 5, 4]
    assert ([1, 1, 2, 3, 3] | [4, 5, 5, 6]) == [1, 2, 3, 4, 5, 6]
  end

  it "does +" do
    a = [1, 2, 3]
    b = [4, 5]
    c = a + b
    assert c.size == 5
    0.upto(4) { |i| assert c[i] == i + 1 }
  end

  it "does + with empty tuple converted to array (#909)" do
    assert ([1, 2] + Tuple.new.to_a) == [1, 2]
    assert (Tuple.new.to_a + [1, 2]) == [1, 2]
  end

  describe "-" do
    it "does it" do
      assert ([1, 2, 3, 4, 5] - [4, 2]) == [1, 3, 5]
    end

    it "does with larger array coming second" do
      assert ([4, 2] - [1, 2, 3]) == [4]
    end
  end

  it "does *" do
    assert ([1, 2, 3] * 3) == [1, 2, 3, 1, 2, 3, 1, 2, 3]
  end

  describe "[]" do
    it "gets on positive index" do
      assert [1, 2, 3][1] == 2
    end

    it "gets on negative index" do
      assert [1, 2, 3][-1] == 3
    end

    it "gets on inclusive range" do
      assert [1, 2, 3, 4, 5, 6][1..4] == [2, 3, 4, 5]
    end

    it "gets on inclusive range with negative indices" do
      assert [1, 2, 3, 4, 5, 6][-5..-2] == [2, 3, 4, 5]
    end

    it "gets on exclusive range" do
      assert [1, 2, 3, 4, 5, 6][1...4] == [2, 3, 4]
    end

    it "gets on exclusive range with negative indices" do
      assert [1, 2, 3, 4, 5, 6][-5...-2] == [2, 3, 4]
    end

    it "gets on range with start higher than end" do
      assert [1, 2, 3][2..1] == [] of Int32
      assert [1, 2, 3][3..1] == [] of Int32
      expect_raises IndexError do
        [1, 2, 3][4..1]
      end
    end

    it "gets on range with start higher than negative end" do
      assert [1, 2, 3][1..-1] == [2, 3] of Int32
      assert [1, 2, 3][2..-2] == [] of Int32
    end

    it "raises on index out of bounds with range" do
      expect_raises IndexError do
        [1, 2, 3][4..6]
      end
    end

    it "gets with start and count" do
      assert [1, 2, 3, 4, 5, 6][1, 3] == [2, 3, 4]
    end

    it "gets with start and count exceeding size" do
      assert [1, 2, 3][1, 3] == [2, 3]
    end

    it "gets with negative start" do
      assert [1, 2, 3, 4, 5, 6][-4, 2] == [3, 4]
    end

    it "raises on index out of bounds with start and count" do
      expect_raises IndexError do
        [1, 2, 3][4, 0]
      end
    end

    it "raises on negative count" do
      expect_raises ArgumentError do
        [1, 2, 3][3, -1]
      end
    end

    it "raises on index out of bounds" do
      expect_raises IndexError do
        [1, 2, 3][-4, 2]
      end
    end

    it "raises on negative count" do
      expect_raises ArgumentError, /negative count: -1/ do
        [1, 2, 3][1, -1]
      end
    end

    it "raises on negative count on empty Array" do
      expect_raises ArgumentError, /negative count: -1/ do
        Array(Int32).new[0, -1]
      end
    end

    it "gets 0, 0 on empty array" do
      a = [] of Int32
      assert a[0, 0] == a
    end

    it "gets 0 ... 0 on empty array" do
      a = [] of Int32
      assert a[0..0] == a
    end

    it "gets nilable" do
      assert [1, 2, 3][2]? == 3
      assert [1, 2, 3][3]?.nil?
    end

    it "same access by at" do
      assert [1, 2, 3][1] == [1, 2, 3].at(1)
    end

    it "doesn't exceed limits" do
      assert [1][0..3] == [1]
    end

    it "returns empty if at end" do
      assert [1][1, 0] == [] of Int32
      assert [1][1, 10] == [] of Int32
    end

    it "raises on too negative left bound" do
      expect_raises IndexError do
        [1, 2, 3][-4..0]
      end
    end
  end

  describe "[]=" do
    it "sets on positive index" do
      a = [1, 2, 3]
      a[1] = 4
      assert a[1] == 4
    end

    it "sets on negative index" do
      a = [1, 2, 3]
      a[-1] = 4
      assert a[2] == 4
    end

    it "replaces a subrange with a single value" do
      a = [1, 2, 3, 4, 5]
      a[1, 3] = 6
      assert a == [1, 6, 5]

      a = [1, 2, 3, 4, 5]
      a[1, 1] = 6
      assert a == [1, 6, 3, 4, 5]

      a = [1, 2, 3, 4, 5]
      a[1, 0] = 6
      assert a == [1, 6, 2, 3, 4, 5]

      a = [1, 2, 3, 4, 5]
      a[1, 10] = 6
      assert a == [1, 6]

      a = [1, 2, 3, 4, 5]
      a[-3, 2] = 6
      assert a == [1, 2, 6, 5]

      a = [1, 2, 3, 4, 5, 6, 7, 8]
      a[1, 3] = 6
      assert a == [1, 6, 5, 6, 7, 8]

      expect_raises ArgumentError, "negative count" do
        [1, 2, 3][0, -1]
      end

      a = [1, 2, 3, 4, 5]
      a[1..3] = 6
      assert a == [1, 6, 5]

      a = [1, 2, 3, 4, 5]
      a[2..3] = 6
      assert a == [1, 2, 6, 5]

      a = [1, 2, 3, 4, 5]
      a[1...1] = 6
      assert a == [1, 6, 2, 3, 4, 5]
    end

    it "replaces a subrange with an array" do
      a = [1, 2, 3, 4, 5]
      a[1, 3] = [6, 7, 8]
      assert a == [1, 6, 7, 8, 5]

      a = [1, 2, 3, 4, 5]
      a[1, 3] = [6, 7]
      assert a == [1, 6, 7, 5]

      a = [1, 2, 3, 4, 5, 6, 7, 8]
      a[1, 3] = [6, 7]
      assert a == [1, 6, 7, 5, 6, 7, 8]

      a = [1, 2, 3, 4, 5]
      a[1, 3] = [6, 7, 8, 9, 10]
      assert a == [1, 6, 7, 8, 9, 10, 5]

      a = [1, 2, 3, 4, 5]
      a[1, 2] = [6, 7, 8, 9, 10]
      assert a == [1, 6, 7, 8, 9, 10, 4, 5]

      a = [1, 2, 3, 4, 5]
      a[1..3] = [6, 7, 8]
      assert a == [1, 6, 7, 8, 5]
    end
  end

  describe "values_at" do
    it "returns the given indexes" do
      assert ["a", "b", "c", "d"].values_at(1, 0, 2) == {"b", "a", "c"}
    end

    it "raises when passed an invalid index" do
      expect_raises IndexError do
        ["a"].values_at(10)
      end
    end

    it "works with mixed types" do
      assert [1, "a", 1.0, :a].values_at(0, 1, 2, 3) == {1, "a", 1.0, :a}
    end
  end

  it "find the element by using binary search" do
    assert [2, 5, 7, 10].bsearch { |x| x >= 4 } == 5
    assert [2, 5, 7, 10].bsearch { |x| x > 10 }.nil?
  end

  it "find the index by using binary search" do
    assert [2, 5, 7, 10].bsearch_index { |x, i| x >= 4 } == 1
    assert [2, 5, 7, 10].bsearch_index { |x, i| x > 10 }.nil?

    assert [2, 5, 7, 10].bsearch_index { |x, i| i >= 3 } == 3
    assert [2, 5, 7, 10].bsearch_index { |x, i| i > 3 }.nil?
  end

  it "does clear" do
    a = [1, 2, 3]
    a.clear
    assert a == [] of Int32
  end

  it "does clone" do
    x = {1 => 2}
    a = [x]
    b = a.clone
    assert b == a
    assert !a.same?(b)
    assert !a[0].same?(b[0])
  end

  it "does compact" do
    a = [1, nil, 2, nil, 3]
    b = assert a.compact == [1, 2, 3]
    assert a == [1, nil, 2, nil, 3]
  end

  describe "compact!" do
    it "returns true if removed" do
      a = [1, nil, 2, nil, 3]
      b = assert a.compact! == true
      assert a == [1, 2, 3]
    end

    it "returns false if not removed" do
      a = [1]
      b = assert a.compact! == false
      assert a == [1]
    end
  end

  describe "concat" do
    it "concats small arrays" do
      a = [1, 2, 3]
      a.concat([4, 5, 6])
      assert a == [1, 2, 3, 4, 5, 6]
    end

    it "concats large arrays" do
      a = [1, 2, 3]
      a.concat((4..1000).to_a)
      assert a == (1..1000).to_a
    end

    it "concats enumerable" do
      a = [1, 2, 3]
      a.concat((4..1000))
      assert a == (1..1000).to_a
    end

    it "concats enumerable to empty array (#2047)" do
      a = [] of Int32
      a.concat(1..1)
      assert a.@capacity == 3

      a = [] of Int32
      a.concat(1..4)
      assert a.@capacity == 6
    end
  end

  describe "delete" do
    it "deletes many" do
      a = [1, 2, 3, 1, 2, 3]
      assert a.delete(2) == true
      assert a == [1, 3, 1, 3]
    end

    it "delete not found" do
      a = [1, 2]
      assert a.delete(4) == false
      assert a == [1, 2]
    end
  end

  describe "delete_at" do
    it "deletes positive index" do
      a = [1, 2, 3, 4]
      assert a.delete_at(1) == 2
      assert a == [1, 3, 4]
    end

    it "deletes use range" do
      a = [1, 2, 3]
      assert a.delete_at(1) == 2
      assert a == [1, 3]

      a = [1, 2, 3]
      assert a.delete_at(-1) == 3
      assert a == [1, 2]

      a = [1, 2, 3]
      assert a.delete_at(-2..-1) == [2, 3]
      assert a == [1]

      a = [1, 2, 3]
      assert a.delete_at(1, 2) == [2, 3]
      assert a == [1]

      a = [1, 2, 3]
      assert a.delete_at(1..5) == [2, 3]
      assert a == [1]
      assert a.size == 1

      a = [1, 2, 3, 4, 5]
      a.delete_at(1..2)
      assert a == [1, 4, 5]

      a = [1, 2, 3, 4, 5, 6, 7]
      a.delete_at(1..2)
      assert a == [1, 4, 5, 6, 7]
    end

    it "deletes with index and count" do
      a = [1, 2, 3, 4, 5]
      a.delete_at(1, 2)
      assert a == [1, 4, 5]

      a = [1, 2, 3, 4, 5, 6, 7]
      a.delete_at(1, 2)
      assert a == [1, 4, 5, 6, 7]
    end

    it "returns empty if at end" do
      a = [1]
      assert a.delete_at(1, 0) == [] of Int32
      assert a.delete_at(1, 10) == [] of Int32
      assert a.delete_at(1..0) == [] of Int32
      assert a.delete_at(1..10) == [] of Int32
      assert a == [1]
    end

    it "deletes negative index" do
      a = [1, 2, 3, 4]
      assert a.delete_at(-3) == 2
      assert a == [1, 3, 4]
    end

    it "deletes out of bounds" do
      expect_raises IndexError do
        [1].delete_at(2)
      end
      expect_raises IndexError do
        [1].delete_at(2, 1)
      end
      expect_raises IndexError do
        [1].delete_at(2..3)
      end
      expect_raises IndexError do
        [1].delete_at(-2..-1)
      end
    end
  end

  it "does dup" do
    x = {1 => 2}
    a = [x]
    b = a.dup
    assert b == [x]
    assert !a.same?(b)
    assert a[0].same?(b[0])
    b << {3 => 4}
    assert a == [x]
  end

  it "does each_index" do
    a = [1, 1, 1]
    b = 0
    a.each_index { |i| b += i }
    assert b == 3
  end

  describe "empty" do
    it "is empty" do
      assert ([] of Int32).empty? == true
    end

    it "is not empty" do
      assert [1].empty? == false
    end
  end

  it "does equals? with custom block" do
    a = [1, 3, 2]
    b = [3, 9, 4]
    c = [5, 7, 3]
    d = [1, 3, 2, 4]
    f = ->(x : Int32, y : Int32) { (x % 2) == (y % 2) }
    assert a.equals?(b, &f) == true
    assert a.equals?(c, &f) == false
    assert a.equals?(d, &f) == false
  end

  describe "fill" do
    it "replaces all values" do
      a = ['a', 'b', 'c']
      expected = ['x', 'x', 'x']
      assert a.fill('x') == expected
    end

    it "replaces only values between index and size" do
      a = ['a', 'b', 'c']
      expected = ['x', 'x', 'c']
      assert a.fill('x', 0, 2) == expected
    end

    it "replaces only values between index and size (2)" do
      a = ['a', 'b', 'c']
      expected = ['a', 'x', 'x']
      assert a.fill('x', 1, 2) == expected
    end

    it "replaces all values from index onwards" do
      a = ['a', 'b', 'c']
      expected = ['a', 'x', 'x']
      assert a.fill('x', -2) == expected
    end

    it "replaces only values between negative index and size" do
      a = ['a', 'b', 'c']
      expected = ['a', 'b', 'x']
      assert a.fill('x', -1, 1) == expected
    end

    it "replaces only values in range" do
      a = ['a', 'b', 'c']
      expected = ['x', 'x', 'c']
      assert a.fill('x', -3..1) == expected
    end

    it "works with a block" do
      a = [3, 6, 9]
      assert a.clone.fill { 0 } == [0, 0, 0]
      assert a.clone.fill { |i| i } == [0, 1, 2]
      assert a.clone.fill(1) { |i| i ** i } == [3, 1, 4]
      assert a.clone.fill(1, 1) { |i| i ** i } == [3, 1, 9]
      assert a.clone.fill(1..1) { |i| i ** i } == [3, 1, 9]
    end
  end

  describe "first" do
    it "gets first when non empty" do
      a = [1, 2, 3]
      assert a.first == 1
    end

    it "raises when empty" do
      expect_raises IndexError do
        ([] of Int32).first
      end
    end

    it "returns a sub array with given number of elements" do
      arr = [1, 2, 3]
      assert arr.first(0) == [] of Int32
      assert arr.first(1) == [1]
      assert arr.first(2) == [1, 2]
      assert arr.first(3) == [1, 2, 3]
      assert arr.first(4) == [1, 2, 3]
    end
  end

  describe "first?" do
    it "gets first? when non empty" do
      a = [1, 2, 3]
      assert a.first? == 1
    end

    it "gives nil when empty" do
      assert ([] of Int32).first?.nil?
    end
  end

  it "does hash" do
    a = [1, 2, [3]]
    b = [1, 2, [3]]
    assert a.hash == b.hash
  end

  describe "index" do
    it "performs without a block" do
      a = [1, 2, 3]
      assert a.index(3) == 2
      assert a.index(4).nil?
    end

    it "performs without a block and offset" do
      a = [1, 2, 3, 1, 2, 3]
      assert a.index(3, offset: 3) == 5
      assert a.index(3, offset: -3) == 5
    end

    it "performs with a block" do
      a = [1, 2, 3]
      assert a.index { |i| i > 1 } == 1
      assert a.index { |i| i > 3 }.nil?
    end

    it "performs with a block and offset" do
      a = [1, 2, 3, 1, 2, 3]
      assert a.index(offset: 3) { |i| i > 1 } == 4
      assert a.index(offset: -3) { |i| i > 1 } == 4
    end

    it "raises if out of bounds" do
      expect_raises IndexError do
        [1, 2, 3][4]
      end
    end
  end

  describe "insert" do
    it "inserts with positive index" do
      a = [1, 3, 4]
      expected = [1, 2, 3, 4]
      assert a.insert(1, 2) == expected
      assert a == expected
    end

    it "inserts with negative index" do
      a = [1, 2, 3]
      expected = [1, 2, 3, 4]
      assert a.insert(-1, 4) == expected
      assert a == expected
    end

    it "inserts with negative index (2)" do
      a = [1, 2, 3]
      expected = [4, 1, 2, 3]
      assert a.insert(-4, 4) == expected
      assert a == expected
    end

    it "inserts out of range" do
      a = [1, 3, 4]

      expect_raises IndexError do
        a.insert(4, 1)
      end
    end
  end

  describe "inspect" do
    it { assert [1, 2, 3].inspect == "[1, 2, 3]" }
  end

  describe "last" do
    it "gets last when non empty" do
      a = [1, 2, 3]
      assert a.last == 3
    end

    it "raises when empty" do
      expect_raises IndexError do
        ([] of Int32).last
      end
    end

    it "returns a sub array with given number of elements" do
      arr = [1, 2, 3]
      assert arr.last(0) == [] of Int32
      assert arr.last(1) == [3]
      assert arr.last(2) == [2, 3]
      assert arr.last(3) == [1, 2, 3]
      assert arr.last(4) == [1, 2, 3]
    end
  end

  describe "size" do
    it "has size 0" do
      assert ([] of Int32).size == 0
    end

    it "has size 2" do
      assert [1, 2].size == 2
    end
  end

  it "does map" do
    a = [1, 2, 3]
    assert a.map { |x| x * 2 } == [2, 4, 6]
    assert a == [1, 2, 3]
  end

  it "does map!" do
    a = [1, 2, 3]
    a.map! { |x| x * 2 }
    assert a == [2, 4, 6]
  end

  describe "pop" do
    it "pops when non empty" do
      a = [1, 2, 3]
      assert a.pop == 3
      assert a == [1, 2]
    end

    it "raises when empty" do
      expect_raises IndexError do
        ([] of Int32).pop
      end
    end

    it "pops many elements" do
      a = [1, 2, 3, 4, 5]
      b = a.pop(3)
      assert b == [3, 4, 5]
      assert a == [1, 2]
    end

    it "pops more elements that what is available" do
      a = [1, 2, 3, 4, 5]
      b = a.pop(10)
      assert b == [1, 2, 3, 4, 5]
      assert a == [] of Int32
    end

    it "pops negative count raises" do
      a = [1, 2]
      expect_raises ArgumentError do
        a.pop(-1)
      end
    end
  end

  it "does product with block" do
    r = [] of Int32
    [1, 2, 3].product([5, 6]) { |a, b| r << a; r << b }
    assert r == [1, 5, 1, 6, 2, 5, 2, 6, 3, 5, 3, 6]
  end

  it "does product without block" do
    assert [1, 2, 3].product(['a', 'b']) == [{1, 'a'}, {1, 'b'}, {2, 'a'}, {2, 'b'}, {3, 'a'}, {3, 'b'}]
  end

  describe "push" do
    it "pushes one element" do
      a = [1, 2]
      assert a.push(3).same?(a)
      assert a == [1, 2, 3]
    end

    it "pushes multiple elements" do
      a = [1, 2]
      assert a.push(3, 4).same?(a)
      assert a == [1, 2, 3, 4]
    end

    it "pushes multiple elements to an empty array" do
      a = [] of Int32
      assert a.push(1, 2, 3).same?(a)
      assert a == [1, 2, 3]
    end

    it "has the << alias" do
      a = [1, 2]
      a << 3
      assert a == [1, 2, 3]
    end
  end

  it "does replace" do
    a = [1, 2, 3]
    b = [1]
    b.replace a
    assert b == a
  end

  it "does reverse with an odd number of elements" do
    a = [1, 2, 3]
    assert a.reverse == [3, 2, 1]
    assert a == [1, 2, 3]
  end

  it "does reverse with an even number of elements" do
    a = [1, 2, 3, 4]
    assert a.reverse == [4, 3, 2, 1]
    assert a == [1, 2, 3, 4]
  end

  it "does reverse! with an odd number of elements" do
    a = [1, 2, 3, 4, 5]
    a.reverse!
    assert a == [5, 4, 3, 2, 1]
  end

  it "does reverse! with an even number of elements" do
    a = [1, 2, 3, 4, 5, 6]
    a.reverse!
    assert a == [6, 5, 4, 3, 2, 1]
  end

  describe "rindex" do
    it "performs without a block" do
      a = [1, 2, 3, 4, 5, 3, 6]
      assert a.rindex(3) == 5
      assert a.rindex(7).nil?
    end

    it "performs without a block and an offset" do
      a = [1, 2, 3, 4, 5, 3, 6]
      assert a.rindex(3, offset: 4) == 2
      assert a.rindex(6, offset: 4).nil?
      assert a.rindex(3, offset: -2) == 5
      assert a.rindex(3, offset: -3) == 2
      assert a.rindex(3, offset: -100).nil?
    end

    it "performs with a block" do
      a = [1, 2, 3, 4, 5, 3, 6]
      assert a.rindex { |i| i > 1 } == 6
      assert a.rindex { |i| i > 6 }.nil?
    end

    it "performs with a block and offset" do
      a = [1, 2, 3, 4, 5, 3, 6]
      assert a.rindex { |i| i > 1 } == 6
      assert a.rindex { |i| i > 6 }.nil?
      assert a.rindex(offset: 4) { |i| i == 3 } == 2
      assert a.rindex(offset: -3) { |i| i == 3 } == 2
    end
  end

  describe "sample" do
    it "sample" do
      assert [1].sample == 1

      x = [1, 2, 3].sample
      assert [1, 2, 3].includes?(x) == true
    end

    it "sample with random" do
      x = [1, 2, 3]
      assert x.sample(Random.new(1)) == 3
    end

    it "gets sample of negative count elements raises" do
      expect_raises ArgumentError do
        [1].sample(-1)
      end
    end

    it "gets sample of 0 elements" do
      assert [1].sample(0) == [] of Int32
    end

    it "gets sample of 1 elements" do
      assert [1].sample(1) == [1]

      x = [1, 2, 3].sample(1)
      assert x.size == 1
      x = x.first
      assert [1, 2, 3].includes?(x) == true
    end

    it "gets sample of k elements out of n" do
      a = [1, 2, 3, 4, 5]
      b = a.sample(3)
      set = Set.new(b)
      assert set.size == 3

      set.each do |e|
        assert a.includes?(e) == true
      end
    end

    it "gets sample of k elements out of n, where k > n" do
      a = [1, 2, 3, 4, 5]
      b = a.sample(10)
      assert b.size == 5
      set = Set.new(b)
      assert set.size == 5

      set.each do |e|
        assert a.includes?(e) == true
      end
    end

    it "gets sample of k elements out of n, with random" do
      a = [1, 2, 3, 4, 5]
      b = a.sample(3, Random.new(1))
      assert b == [4, 3, 5]
    end
  end

  describe "shift" do
    it "shifts when non empty" do
      a = [1, 2, 3]
      assert a.shift == 1
      assert a == [2, 3]
    end

    it "raises when empty" do
      expect_raises IndexError do
        ([] of Int32).shift
      end
    end

    it "shifts many elements" do
      a = [1, 2, 3, 4, 5]
      b = a.shift(3)
      assert b == [1, 2, 3]
      assert a == [4, 5]
    end

    it "shifts more than what is available" do
      a = [1, 2, 3, 4, 5]
      b = a.shift(10)
      assert b == [1, 2, 3, 4, 5]
      assert a == [] of Int32
    end

    it "shifts negative count raises" do
      a = [1, 2]
      expect_raises ArgumentError do
        a.shift(-1)
      end
    end
  end

  describe "shuffle" do
    it "shuffle!" do
      a = [1, 2, 3]
      a.shuffle!
      b = [1, 2, 3]
      3.times { assert a.includes?(b.shift) == true }
    end

    it "shuffle" do
      a = [1, 2, 3]
      b = a.shuffle
      assert a.same?(b) == false
      assert a == [1, 2, 3]

      3.times { assert b.includes?(a.shift) == true }
    end

    it "shuffle! with random" do
      a = [1, 2, 3]
      a.shuffle!(Random.new(1))
      assert a == [2, 1, 3]
    end

    it "shuffle with random" do
      a = [1, 2, 3]
      b = a.shuffle(Random.new(1))
      assert b == [2, 1, 3]
    end
  end

  describe "sort" do
    it "sort without block" do
      a = [3, 4, 1, 2, 5, 6]
      b = a.sort
      assert b == [1, 2, 3, 4, 5, 6]
      assert a != b
    end

    it "sort with a block" do
      a = ["foo", "a", "hello"]
      b = a.sort { |x, y| x.size <=> y.size }
      assert b == ["a", "foo", "hello"]
      assert a != b
    end

    it "doesn't crash on special situations" do
      [1, 2, 3].sort { 1 }
      Array.new(10) { BadSortingClass.new }.sort
    end
  end

  describe "sort!" do
    it "sort! without block" do
      a = [3, 4, 1, 2, 5, 6]
      a.sort!
      assert a == [1, 2, 3, 4, 5, 6]
    end

    it "sort! with a block" do
      a = ["foo", "a", "hello"]
      a.sort! { |x, y| x.size <=> y.size }
      assert a == ["a", "foo", "hello"]
    end
  end

  describe "sort_by" do
    it "sorts by" do
      a = ["foo", "a", "hello"]
      b = a.sort_by &.size
      assert b == ["a", "foo", "hello"]
      assert a != b
    end
  end

  describe "sort_by!" do
    it "sorts by!" do
      a = ["foo", "a", "hello"]
      a.sort_by! &.size
      assert a == ["a", "foo", "hello"]
    end

    it "calls given block exactly once for each element" do
      calls = Hash(String, Int32).new(0)
      a = ["foo", "a", "hello"]
      a.sort_by! { |e| calls[e] += 1; e.size }
      assert calls == {"foo" => 1, "a" => 1, "hello" => 1}
    end
  end

  describe "swap" do
    it "swaps" do
      a = [1, 2, 3]
      a.swap(0, 2)
      assert a == [3, 2, 1]
    end

    it "swaps with negative indices" do
      a = [1, 2, 3]
      a.swap(-3, -1)
      assert a == [3, 2, 1]
    end

    it "swaps but raises out of bounds on left" do
      a = [1, 2, 3]
      expect_raises IndexError do
        a.swap(3, 0)
      end
    end

    it "swaps but raises out of bounds on right" do
      a = [1, 2, 3]
      expect_raises IndexError do
        a.swap(0, 3)
      end
    end
  end

  describe "to_s" do
    it "does to_s" do
      it { assert [1, 2, 3].to_s == "[1, 2, 3]" }
    end

    it "does with recursive" do
      ary = [] of RecursiveArray
      ary << ary
      assert ary.to_s == "[[...]]"
    end
  end

  describe "uniq" do
    it "uniqs without block" do
      a = [1, 2, 2, 3, 1, 4, 5, 3]
      b = a.uniq
      assert b == [1, 2, 3, 4, 5]
      assert a.same?(b) == false
    end

    it "uniqs with block" do
      a = [-1, 1, 0, 2, -2]
      b = a.uniq &.abs
      assert b == [-1, 0, 2]
      assert a.same?(b) == false
    end

    it "uniqs with true" do
      a = [1, 2, 3]
      b = a.uniq { true }
      assert b == [1]
      assert a.same?(b) == false
    end
  end

  describe "uniq!" do
    it "uniqs without block" do
      a = [1, 2, 2, 3, 1, 4, 5, 3]
      a.uniq!
      assert a == [1, 2, 3, 4, 5]
    end

    it "uniqs with block" do
      a = [-1, 1, 0, 2, -2]
      a.uniq! &.abs
      assert a == [-1, 0, 2]
    end

    it "uniqs with true" do
      a = [1, 2, 3]
      a.uniq! { true }
      assert a == [1]
    end
  end

  describe "unshift" do
    it "unshifts one element" do
      a = [1, 2]
      assert a.unshift(3).same?(a)
      assert a == [3, 1, 2]
    end

    it "unshifts multiple elements" do
      a = [1, 2]
      assert a.unshift(3, 4).same?(a)
      assert a == [3, 4, 1, 2]
    end

    it "unshifts multiple elements to an empty array" do
      a = [] of Int32
      assert a.unshift(1, 2, 3).same?(a)
      assert a == [1, 2, 3]
    end
  end

  it "does update" do
    a = [1, 2, 3]
    a.update(1) { |x| x * 2 }
    assert a == [1, 4, 3]
  end

  it "does <=>" do
    a = [1, 2, 3]
    b = [4, 5, 6]
    c = [1, 2]

    assert (a <=> b) < 1
    assert (a <=> c) > 0
    assert (b <=> c) > 0
    assert (b <=> a) > 0
    assert (c <=> a) < 0
    assert (c <=> b) < 0
    assert (a <=> a) == 0

    assert ([8] <=> [1, 2, 3]) > 0
    assert ([8] <=> [8, 1, 2]) < 0

    assert [[1, 2, 3], [4, 5], [8], [1, 2, 3, 4]].sort == [[1, 2, 3], [1, 2, 3, 4], [4, 5], [8]]
  end

  it "does each while modifying array" do
    a = [1, 2, 3]
    count = 0
    a.each do
      count += 1
      a.clear
    end
    assert count == 1
  end

  it "does each index while modifying array" do
    a = [1, 2, 3]
    count = 0
    a.each_index do
      count += 1
      a.clear
    end
    assert count == 1
  end

  describe "zip" do
    describe "when a block is provided" do
      it "yields pairs of self's elements and passed array" do
        a, b, r = [1, 2, 3], [4, 5, 6], ""
        a.zip(b) { |x, y| r += "#{x}:#{y}," }
        assert r == "1:4,2:5,3:6,"
      end
    end

    describe "when no block is provided" do
      describe "and the arrays have different typed elements" do
        it "returns an array of paired elements (tuples)" do
          a, b = [1, 2, 3], ["a", "b", "c"]
          r = a.zip(b)
          assert r == [{1, "a"}, {2, "b"}, {3, "c"}]
        end
      end
    end
  end

  describe "zip?" do
    describe "when a block is provided" do
      describe "and size of an arg is less than receiver" do
        it "yields pairs of self's elements and passed array (with nil)" do
          a, b, r = [1, 2, 3], [4, 5], ""
          a.zip?(b) { |x, y| r += "#{x}:#{y}," }
          assert r == "1:4,2:5,3:,"
        end
      end
    end

    describe "when no block is provided" do
      describe "and the arrays have different typed elements" do
        describe "and size of an arg is less than receiver" do
          it "returns an array of paired elements (tuples with nil)" do
            a, b = [1, 2, 3], ["a", "b"]
            r = a.zip?(b)
            assert r == [{1, "a"}, {2, "b"}, {3, nil}]
          end
        end
      end
    end
  end

  it "does compact_map" do
    a = [1, 2, 3, 4, 5]
    b = a.compact_map { |e| e.divisible_by?(2) ? e : nil }
    assert b.size == 2
    assert b == [2, 4]
  end

  it "does compact_map with false" do
    a = [1, 2, 3]
    b = a.compact_map do |e|
      case e
      when 1 then 1
      when 2 then nil
      else        false
      end
    end
    assert b.size == 2
    assert b == [1, false]
  end

  it "builds from buffer" do
    ary = Array(Int32).build(4) do |buffer|
      buffer[0] = 1
      buffer[1] = 2
      2
    end
    assert ary.size == 2
    assert ary == [1, 2]
  end

  it "selects!" do
    ary1 = [1, 2, 3, 4, 5]

    ary2 = ary1.select! { |elem| elem % 2 == 0 }
    assert ary2 == [2, 4]
    assert ary2.same?(ary1)
  end

  it "returns nil when using select! and no changes were made" do
    ary1 = [1, 2, 3, 4, 5]

    ary2 = ary1.select! { true }
    assert ary2 == nil
    assert ary1 == [1, 2, 3, 4, 5]
  end

  it "rejects!" do
    ary1 = [1, 2, 3, 4, 5]

    ary2 = ary1.reject! { |elem| elem % 2 == 0 }
    assert ary2 == [1, 3, 5]
    assert ary2.same?(ary1)
  end

  it "returns nil when using reject! and no changes were made" do
    ary1 = [1, 2, 3, 4, 5]

    ary2 = ary1.reject! { false }
    assert ary2 == nil
    assert ary1 == [1, 2, 3, 4, 5]
  end

  it "does map_with_index" do
    ary = [1, 1, 2, 2]
    ary2 = ary.map_with_index { |e, i| e + i }
    assert ary2 == [1, 2, 4, 5]
  end

  it "does + with different types (#568)" do
    a = [1, 2, 3]
    a += ["hello"]
    assert a == [1, 2, 3, "hello"]
  end

  describe "each iterator" do
    it "does next" do
      a = [1, 2, 3]
      iter = a.each
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next == 3
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "cycles" do
      assert [1, 2, 3].cycle.first(8).join == "12312312"
    end
  end

  describe "each_index iterator" do
    it "does next" do
      a = [1, 2, 3]
      iter = a.each_index
      assert iter.next == 0
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 0
    end
  end

  describe "reverse_each iterator" do
    it "does next" do
      a = [1, 2, 3]
      iter = a.reverse_each
      assert iter.next == 3
      assert iter.next == 2
      assert iter.next == 1
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 3
    end
  end

  describe "cycle" do
    it "cycles" do
      a = [] of Int32
      [1, 2, 3].cycle do |x|
        a << x
        break if a.size == 9
      end
      assert a == [1, 2, 3, 1, 2, 3, 1, 2, 3]
    end

    it "cycles N times" do
      a = [] of Int32
      [1, 2, 3].cycle(2) do |x|
        a << x
      end
      assert a == [1, 2, 3, 1, 2, 3]
    end

    it "cycles with iterator" do
      assert [1, 2, 3].cycle.first(5).to_a == [1, 2, 3, 1, 2]
    end

    it "cycles with N and iterator" do
      assert [1, 2, 3].cycle(2).to_a == [1, 2, 3, 1, 2, 3]
    end
  end

  describe "transpose" do
    it "transeposes elements" do
      assert [[:a, :b], [:c, :d], [:e, :f]].transpose == [[:a, :c, :e], [:b, :d, :f]]
      assert [[:a, :c, :e], [:b, :d, :f]].transpose == [[:a, :b], [:c, :d], [:e, :f]]
      assert [[:a]].transpose == [[:a]]
    end

    it "transposes union of arrays" do
      assert [[1, 2], [1.0, 2.0]].transpose == [[1, 1.0], [2, 2.0]]
      assert [[1, 2.0], [1, 2.0]].transpose == [[1, 1], [2.0, 2.0]]
      assert [[1, 1.0], ['a', "aaa"]].transpose == [[1, 'a'], [1.0, "aaa"]]

      assert typeof([[1.0], [1]].transpose) == Array(Array(Int32 | Float64))
      assert typeof([[1, 1.0], ['a', "aaa"]].transpose) == Array(Array(String | Int32 | Float64 | Char))
    end

    it "transposes empty array" do
      e = [] of Array(Int32)
      assert e.transpose.empty? == true
      assert [e].transpose.empty? == true
      assert [e, e, e].transpose.empty? == true
    end

    it "raises IndexError error when size of element is invalid" do
      expect_raises(IndexError) { [[1], [1, 2]].transpose }
      expect_raises(IndexError) { [[1, 2], [1]].transpose }
    end
  end

  describe "rotate" do
    it "rotate!" do
      a = [1, 2, 3]
      a.rotate!; assert a == [2, 3, 1]
      a.rotate!; assert a == [3, 1, 2]
      a.rotate!; assert a == [1, 2, 3]
      a.rotate!; assert a == [2, 3, 1]
      assert a.rotate! == a
    end

    it "rotate" do
      a = [1, 2, 3]
      assert a.rotate == [2, 3, 1]
      assert a == [1, 2, 3]
      assert a.rotate == [2, 3, 1]
    end

    it { a = [1, 2, 3]; a.rotate!(0); assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; a.rotate!(1); assert a == [2, 3, 1] }
    it { a = [1, 2, 3]; a.rotate!(2); assert a == [3, 1, 2] }
    it { a = [1, 2, 3]; a.rotate!(3); assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; a.rotate!(4); assert a == [2, 3, 1] }
    it { a = [1, 2, 3]; a.rotate!(3001); assert a == [2, 3, 1] }
    it { a = [1, 2, 3]; a.rotate!(-1); assert a == [3, 1, 2] }
    it { a = [1, 2, 3]; a.rotate!(-3001); assert a == [3, 1, 2] }

    it { a = [1, 2, 3]; assert a.rotate(0) == [1, 2, 3]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(1) == [2, 3, 1]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(2) == [3, 1, 2]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(3) == [1, 2, 3]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(4) == [2, 3, 1]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(3001) == [2, 3, 1]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(-1) == [3, 1, 2]; assert a == [1, 2, 3] }
    it { a = [1, 2, 3]; assert a.rotate(-3001) == [3, 1, 2]; assert a == [1, 2, 3] }
  end

  describe "permutations" do
    it { assert [1, 2, 2].permutations == [[1, 2, 2], [1, 2, 2], [2, 1, 2], [2, 2, 1], [2, 1, 2], [2, 2, 1]] }
    it { assert [1, 2, 3].permutations == [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]] }
    it { assert [1, 2, 3].permutations(1) == [[1], [2], [3]] }
    it { assert [1, 2, 3].permutations(2) == [[1, 2], [1, 3], [2, 1], [2, 3], [3, 1], [3, 2]] }
    it { assert [1, 2, 3].permutations(3) == [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]] }
    it { assert [1, 2, 3].permutations(0) == [[] of Int32] }
    it { assert [1, 2, 3].permutations(4) == [] of Array(Int32) }
    it { expect_raises(ArgumentError, "size must be positive") { [1].permutations(-1) } }

    it "accepts a block" do
      sums = [] of Int32
      assert [1, 2, 3].each_permutation(2) do |perm|
        sums << perm.sum
      end == [1, 2, 3]
      assert sums == [3, 4, 3, 5, 4, 5]
    end

    it "yielding dup of arrays" do
      sums = [] of Int32
      assert [1, 2, 3].each_permutation(3) do |perm|
        perm.map! &.+(1)
        sums << perm.sum
      end == [1, 2, 3]
      assert sums == [9, 9, 9, 9, 9, 9]
    end

    it { expect_raises(ArgumentError, "size must be positive") { [1].each_permutation(-1) { } } }

    it "returns iterator" do
      a = [1, 2, 3]
      perms = a.permutations
      iter = a.each_permutation
      perms.each do |perm|
        assert iter.next == perm
      end
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == perms[0]
    end

    it "returns iterator with given size" do
      a = [1, 2, 3]
      perms = a.permutations(2)
      iter = a.each_permutation(2)
      perms.each do |perm|
        assert iter.next == perm
      end
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == perms[0]
    end
  end

  describe "combinations" do
    it { assert [1, 2, 2].combinations == [[1, 2, 2]] }
    it { assert [1, 2, 3].combinations == [[1, 2, 3]] }
    it { assert [1, 2, 3].combinations(1) == [[1], [2], [3]] }
    it { assert [1, 2, 3].combinations(2) == [[1, 2], [1, 3], [2, 3]] }
    it { assert [1, 2, 3].combinations(3) == [[1, 2, 3]] }
    it { assert [1, 2, 3].combinations(0) == [[] of Int32] }
    it { assert [1, 2, 3].combinations(4) == [] of Array(Int32) }
    it { assert [1, 2, 3, 4].combinations(3) == [[1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]] }
    it { assert [1, 2, 3, 4].combinations(2) == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] }
    it { expect_raises(ArgumentError, "size must be positive") { [1].combinations(-1) } }

    it "accepts a block" do
      sums = [] of Int32
      assert [1, 2, 3].each_combination(2) do |comb|
        sums << comb.sum
      end == [1, 2, 3]
      assert sums == [3, 4, 5]
    end

    it "yielding dup of arrays" do
      sums = [] of Int32
      assert [1, 2, 3].each_combination(3) do |comb|
        comb.map! &.+(1)
        sums << comb.sum
      end == [1, 2, 3]
      assert sums == [9]
    end

    it { expect_raises(ArgumentError, "size must be positive") { [1].each_combination(-1) { } } }

    it "returns iterator" do
      a = [1, 2, 3, 4]
      combs = a.combinations(2)
      iter = a.each_combination(2)
      combs.each do |comb|
        assert iter.next == comb
      end
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == combs[0]
    end
  end

  describe "repeated_combinations" do
    it { assert [1, 2, 2].repeated_combinations == [[1, 1, 1], [1, 1, 2], [1, 1, 2], [1, 2, 2], [1, 2, 2], [1, 2, 2], [2, 2, 2], [2, 2, 2], [2, 2, 2], [2, 2, 2]] }
    it { assert [1, 2, 3].repeated_combinations == [[1, 1, 1], [1, 1, 2], [1, 1, 3], [1, 2, 2], [1, 2, 3], [1, 3, 3], [2, 2, 2], [2, 2, 3], [2, 3, 3], [3, 3, 3]] }
    it { assert [1, 2, 3].repeated_combinations(1) == [[1], [2], [3]] }
    it { assert [1, 2, 3].repeated_combinations(2) == [[1, 1], [1, 2], [1, 3], [2, 2], [2, 3], [3, 3]] }
    it { assert [1, 2, 3].repeated_combinations(3) == [[1, 1, 1], [1, 1, 2], [1, 1, 3], [1, 2, 2], [1, 2, 3], [1, 3, 3], [2, 2, 2], [2, 2, 3], [2, 3, 3], [3, 3, 3]] }
    it { assert [1, 2, 3].repeated_combinations(0) == [[] of Int32] }
    it { assert [1, 2, 3].repeated_combinations(4) == [[1, 1, 1, 1], [1, 1, 1, 2], [1, 1, 1, 3], [1, 1, 2, 2], [1, 1, 2, 3], [1, 1, 3, 3], [1, 2, 2, 2], [1, 2, 2, 3], [1, 2, 3, 3], [1, 3, 3, 3], [2, 2, 2, 2], [2, 2, 2, 3], [2, 2, 3, 3], [2, 3, 3, 3], [3, 3, 3, 3]] }
    it { expect_raises(ArgumentError, "size must be positive") { [1].repeated_combinations(-1) } }

    it "accepts a block" do
      sums = [] of Int32
      assert [1, 2, 3].each_repeated_combination(2) do |comb|
        sums << comb.sum
      end == [1, 2, 3]
      assert sums == [2, 3, 4, 4, 5, 6]
    end

    it "yielding dup of arrays" do
      sums = [] of Int32
      assert [1, 2, 3].each_repeated_combination(3) do |comb|
        comb.map! &.+(1)
        sums << comb.sum
      end == [1, 2, 3]
      assert sums == [6, 7, 8, 8, 9, 10, 9, 10, 11, 12]
    end

    it { expect_raises(ArgumentError, "size must be positive") { [1].each_repeated_combination(-1) { } } }

    it "returns iterator" do
      a = [1, 2, 3, 4]
      combs = a.repeated_combinations(2)
      iter = a.each_repeated_combination(2)
      combs.each do |comb|
        assert iter.next == comb
      end
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == combs[0]
    end
  end

  describe "repeated_permutations" do
    it { assert [1, 2, 2].repeated_permutations == [[1, 1, 1], [1, 1, 2], [1, 1, 2], [1, 2, 1], [1, 2, 2], [1, 2, 2], [1, 2, 1], [1, 2, 2], [1, 2, 2], [2, 1, 1], [2, 1, 2], [2, 1, 2], [2, 2, 1], [2, 2, 2], [2, 2, 2], [2, 2, 1], [2, 2, 2], [2, 2, 2], [2, 1, 1], [2, 1, 2], [2, 1, 2], [2, 2, 1], [2, 2, 2], [2, 2, 2], [2, 2, 1], [2, 2, 2], [2, 2, 2]] }
    it { assert [1, 2, 3].repeated_permutations == [[1, 1, 1], [1, 1, 2], [1, 1, 3], [1, 2, 1], [1, 2, 2], [1, 2, 3], [1, 3, 1], [1, 3, 2], [1, 3, 3], [2, 1, 1], [2, 1, 2], [2, 1, 3], [2, 2, 1], [2, 2, 2], [2, 2, 3], [2, 3, 1], [2, 3, 2], [2, 3, 3], [3, 1, 1], [3, 1, 2], [3, 1, 3], [3, 2, 1], [3, 2, 2], [3, 2, 3], [3, 3, 1], [3, 3, 2], [3, 3, 3]] }
    it { assert [1, 2, 3].repeated_permutations(1) == [[1], [2], [3]] }
    it { assert [1, 2, 3].repeated_permutations(2) == [[1, 1], [1, 2], [1, 3], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3]] }
    it { assert [1, 2, 3].repeated_permutations(3) == [[1, 1, 1], [1, 1, 2], [1, 1, 3], [1, 2, 1], [1, 2, 2], [1, 2, 3], [1, 3, 1], [1, 3, 2], [1, 3, 3], [2, 1, 1], [2, 1, 2], [2, 1, 3], [2, 2, 1], [2, 2, 2], [2, 2, 3], [2, 3, 1], [2, 3, 2], [2, 3, 3], [3, 1, 1], [3, 1, 2], [3, 1, 3], [3, 2, 1], [3, 2, 2], [3, 2, 3], [3, 3, 1], [3, 3, 2], [3, 3, 3]] }
    it { assert [1, 2, 3].repeated_permutations(0) == [[] of Int32] }
    it { assert [1, 2, 3].repeated_permutations(4) == [[1, 1, 1, 1], [1, 1, 1, 2], [1, 1, 1, 3], [1, 1, 2, 1], [1, 1, 2, 2], [1, 1, 2, 3], [1, 1, 3, 1], [1, 1, 3, 2], [1, 1, 3, 3], [1, 2, 1, 1], [1, 2, 1, 2], [1, 2, 1, 3], [1, 2, 2, 1], [1, 2, 2, 2], [1, 2, 2, 3], [1, 2, 3, 1], [1, 2, 3, 2], [1, 2, 3, 3], [1, 3, 1, 1], [1, 3, 1, 2], [1, 3, 1, 3], [1, 3, 2, 1], [1, 3, 2, 2], [1, 3, 2, 3], [1, 3, 3, 1], [1, 3, 3, 2], [1, 3, 3, 3], [2, 1, 1, 1], [2, 1, 1, 2], [2, 1, 1, 3], [2, 1, 2, 1], [2, 1, 2, 2], [2, 1, 2, 3], [2, 1, 3, 1], [2, 1, 3, 2], [2, 1, 3, 3], [2, 2, 1, 1], [2, 2, 1, 2], [2, 2, 1, 3], [2, 2, 2, 1], [2, 2, 2, 2], [2, 2, 2, 3], [2, 2, 3, 1], [2, 2, 3, 2], [2, 2, 3, 3], [2, 3, 1, 1], [2, 3, 1, 2], [2, 3, 1, 3], [2, 3, 2, 1], [2, 3, 2, 2], [2, 3, 2, 3], [2, 3, 3, 1], [2, 3, 3, 2], [2, 3, 3, 3], [3, 1, 1, 1], [3, 1, 1, 2], [3, 1, 1, 3], [3, 1, 2, 1], [3, 1, 2, 2], [3, 1, 2, 3], [3, 1, 3, 1], [3, 1, 3, 2], [3, 1, 3, 3], [3, 2, 1, 1], [3, 2, 1, 2], [3, 2, 1, 3], [3, 2, 2, 1], [3, 2, 2, 2], [3, 2, 2, 3], [3, 2, 3, 1], [3, 2, 3, 2], [3, 2, 3, 3], [3, 3, 1, 1], [3, 3, 1, 2], [3, 3, 1, 3], [3, 3, 2, 1], [3, 3, 2, 2], [3, 3, 2, 3], [3, 3, 3, 1], [3, 3, 3, 2], [3, 3, 3, 3]] }
    it { expect_raises(ArgumentError, "size must be positive") { [1].repeated_permutations(-1) } }

    it "accepts a block" do
      sums = [] of Int32
      assert [1, 2, 3].each_repeated_permutation(2) do |a|
        sums << a.sum
      end == [1, 2, 3]
      assert sums == [2, 3, 4, 3, 4, 5, 4, 5, 6]
    end

    it "yielding dup of arrays" do
      sums = [] of Int32
      assert [1, 2, 3].each_repeated_permutation(3) do |a|
        a.map! &.+(1)
        sums << a.sum
      end == [1, 2, 3]
      assert sums == [6, 7, 8, 7, 8, 9, 8, 9, 10, 7, 8, 9, 8, 9, 10, 9, 10, 11, 8, 9, 10, 9, 10, 11, 10, 11, 12]
    end

    it { expect_raises(ArgumentError, "size must be positive") { [1].each_repeated_permutation(-1) { } } }
  end

  describe "Array.each_product" do
    it "single array" do
      res = [] of Array(Int32)
      Array.each_product([[1]]) { |r| res << r }
      assert res == [[1]]
    end

    it "2 arrays" do
      res = [] of Array(Int32)
      Array.each_product([[1, 2], [3, 4]]) { |r| res << r }
      assert res == [[1, 3], [1, 4], [2, 3], [2, 4]]
    end

    it "2 arrays different types" do
      res = [] of Array(Int32 | Char)
      Array.each_product([[1, 2], ['a', 'b']]) { |r| res << r }
      assert res == [[1, 'a'], [1, 'b'], [2, 'a'], [2, 'b']]
    end

    it "more arrays" do
      res = [] of Array(Int32)
      Array.each_product([[1, 2], [3], [5, 6]]) { |r| res << r }
      assert res == [[1, 3, 5], [1, 3, 6], [2, 3, 5], [2, 3, 6]]
    end

    it "with splat" do
      res = [] of Array(Int32 | Char)
      Array.each_product([1, 2], ['a', 'b']) { |r| res << r }
      assert res == [[1, 'a'], [1, 'b'], [2, 'a'], [2, 'b']]
    end
  end

  describe "Array.product" do
    it "with array" do
      assert Array.product([[1, 2], ['a', 'b']]) == [[1, 'a'], [1, 'b'], [2, 'a'], [2, 'b']]
    end

    it "with splat" do
      assert Array.product([1, 2], ['a', 'b']) == [[1, 'a'], [1, 'b'], [2, 'a'], [2, 'b']]
    end
  end

  it "doesn't overflow buffer with Array.new(size, value) (#1209)" do
    a = Array.new(1, 1_i64)
    b = Array.new(1, 1_i64)
    b << 2_i64 << 3_i64
    assert a == [1]
    assert b == [1, 2, 3]
  end

  it "flattens" do
    assert [[1, 'a'], [[[[true], "hi"]]]].flatten == [1, 'a', true, "hi"]
  end
end
