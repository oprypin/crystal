require "spec"

class SpecEnumerable
  include Enumerable(Int32)

  def each
    yield 1
    yield 2
    yield 3
  end
end

describe "Enumerable" do
  describe "all? with block" do
    it "returns true" do
      assert ["ant", "bear", "cat"].all? { |word| word.size >= 3 } == true
    end

    it "returns false" do
      assert ["ant", "bear", "cat"].all? { |word| word.size >= 4 } == false
    end
  end

  describe "all? without block" do
    it "returns true" do
      assert [15].all? == true
    end

    it "returns false" do
      assert [nil, true, 99].all? == false
    end
  end

  describe "any? with block" do
    it "returns true if at least one element fulfills the condition" do
      assert ["ant", "bear", "cat"].any? { |word| word.size >= 4 } == true
    end

    it "returns false if all elements does not fulfill the condition" do
      assert ["ant", "bear", "cat"].any? { |word| word.size > 4 } == false
    end
  end

  describe "any? without block" do
    it "returns true if at least one element is truthy" do
      assert [nil, true, 99].any? == true
    end

    it "returns false if all elements are falsey" do
      assert [nil, false].any? == false
    end
  end

  describe "compact map" do
    it { assert Set{1, nil, 2, nil, 3}.compact_map { |x| x.try &.+(1) } == [2, 3, 4] }
  end

  describe "size without block" do
    it "returns the number of elements in the Enumerable" do
      assert SpecEnumerable.new.size == 3
    end
  end

  describe "count with block" do
    it "returns the number of the times the item is present" do
      assert %w(a b c a d A).count("a") == 2
    end
  end

  describe "cycle" do
    it "calls forever if we don't break" do
      called = 0
      elements = [] of Int32
      (1..2).cycle do |e|
        elements << e
        called += 1
        break if called == 6
      end
      assert called == 6
      assert elements == [1, 2, 1, 2, 1, 2]
    end

    it "calls the block n times given the optional argument" do
      called = 0
      elements = [] of Int32
      (1..2).cycle(3) do |e|
        elements << e
        called += 1
      end
      assert called == 6
      assert elements == [1, 2, 1, 2, 1, 2]
    end
  end

  describe "each_cons" do
    it "returns running pairs" do
      array = [] of Array(Int32)
      [1, 2, 3, 4].each_cons(2) { |pair| array << pair }
      assert array == [[1, 2], [2, 3], [3, 4]]
    end

    it "returns running triples" do
      array = [] of Array(Int32)
      [1, 2, 3, 4, 5].each_cons(3) { |triple| array << triple }
      assert array == [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
    end

    it "returns each_cons iterator" do
      iter = [1, 2, 3, 4, 5].each_cons(3)
      assert iter.next == [1, 2, 3]
      assert iter.next == [2, 3, 4]
      assert iter.next == [3, 4, 5]
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == [1, 2, 3]
    end
  end

  describe "each_slice" do
    it "returns partial slices" do
      array = [] of Array(Int32)
      [1, 2, 3].each_slice(2) { |slice| array << slice }
      assert array == [[1, 2], [3]]
    end

    it "returns full slices" do
      array = [] of Array(Int32)
      [1, 2, 3, 4].each_slice(2) { |slice| array << slice }
      assert array == [[1, 2], [3, 4]]
    end

    it "returns each_slice iterator" do
      iter = [1, 2, 3, 4, 5].each_slice(2)
      assert iter.next == [1, 2]
      assert iter.next == [3, 4]
      assert iter.next == [5]
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == [1, 2]
    end
  end

  describe "each_with_index" do
    it "yields the element and the index" do
      collection = [] of {String, Int32}
      ["a", "b", "c"].each_with_index do |e, i|
        collection << {e, i}
      end
      assert collection == [{"a", 0}, {"b", 1}, {"c", 2}]
    end

    it "accepts an optional offset parameter" do
      collection = [] of {String, Int32}
      ["Alice", "Bob"].each_with_index(1) do |e, i|
        collection << {e, i}
      end
      assert collection == [{"Alice", 1}, {"Bob", 2}]
    end

    it "gets each_with_index iterator" do
      iter = [1, 2].each_with_index
      assert iter.next == {1, 0}
      assert iter.next == {2, 1}
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == {1, 0}
    end
  end

  describe "each_with_object" do
    it "yields the element and the given object" do
      collection = [] of {Int32, String}
      object = "a"
      (1..3).each_with_object(object) do |e, o|
        collection << {e, o}
      end
      assert collection == [{1, object}, {2, object}, {3, object}]
    end

    it "gets each_with_object iterator" do
      iter = [1, 2].each_with_object("a")
      assert iter.next == {1, "a"}
      assert iter.next == {2, "a"}
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == {1, "a"}
    end
  end

  describe "find" do
    it "finds" do
      assert [1, 2, 3].find { |x| x > 2 } == 3
    end

    it "doesn't find" do
      assert [1, 2, 3].find { |x| x > 3 }.nil?
    end

    it "doesn't find with default value" do
      assert [1, 2, 3].find(-1) { |x| x > 3 } == -1
    end
  end

  describe "first" do
    it "gets first" do
      assert (1..3).first == 1
    end

    it "raises if enumerable empty" do
      expect_raises Enumerable::EmptyError do
        (1...1).first
      end
    end

    it { assert [-1, -2, -3].first == -1 }
  end

  describe "first?" do
    it "gets first?" do
      assert (1..3).first? == 1
    end

    it "returns nil if enumerable empty" do
      assert (1...1).first?.nil?
    end
  end

  describe "flat_map" do
    it "does example 1" do
      assert [1, 2, 3, 4].flat_map { |e| [e, -e] } == [1, -1, 2, -2, 3, -3, 4, -4]
    end

    it "does example 2" do
      assert [[1, 2], [3, 4]].flat_map { |e| e + [100] } == [1, 2, 100, 3, 4, 100]
    end
  end

  describe "grep" do
    it "works with regexes for instance" do
      assert ["Alice", "Bob", "Cipher", "Anna"].grep(/^A/) == ["Alice", "Anna"]
    end

    it "returns empty array if nothing matches" do
      assert %w(Alice Bob Mallory).grep(/nothing/) == [] of String
    end
  end

  describe "group_by" do
    it { assert [1, 2, 2, 3].group_by { |x| x == 2 } == {true => [2, 2], false => [1, 3]} }

    it "groups can group by size (like the doc example)" do
      assert %w(Alice Bob Ary).group_by { |e| e.size } == {3 => ["Bob", "Ary"],
        5 => ["Alice"]}
    end
  end

  describe "in_groups_of" do
    it { assert [1, 2, 3].in_groups_of(1) == [[1], [2], [3]] }
    it { assert [1, 2, 3].in_groups_of(2) == [[1, 2], [3, nil]] }
    it { assert ([] of Int32).in_groups_of(2) == [] of Array(Array(Int32 | Nil)) }
    it { assert [1, 2, 3].in_groups_of(2, "x") == [[1, 2], [3, "x"]] }

    it "raises argument error if size is less than 0" do
      expect_raises ArgumentError, "size must be positive" do
        [1, 2, 3].in_groups_of(0)
      end
    end

    it "takes a block" do
      sums = [] of Int32
      [1, 2, 4].in_groups_of(2, 0) { |a| sums << a.sum }
      assert sums == [3, 4]
    end
  end

  describe "includes?" do
    it "is true if the object exists in the collection" do
      assert [1, 2, 3].includes?(2) == true
    end

    it "is false if the object is not part of the collection" do
      assert [1, 2, 3].includes?(5) == false
    end
  end

  describe "index with a block" do
    it "returns the index of the first element where the blcok returns true" do
      assert ["Alice", "Bob"].index { |name| name.size < 4 } == 1
    end

    it "returns nil if no object could be found" do
      assert ["Alice", "Bob"].index { |name| name.size < 3 } == nil
    end
  end

  describe "index with an object" do
    it "returns the index of that object if found" do
      assert ["Alice", "Bob"].index("Alice") == 0
    end

    it "returns nil if the object was not found" do
      assert ["Alice", "Bob"].index("Mallory").nil?
    end
  end

  describe "index_by" do
    it "creates a hash indexed by the value returned by the block" do
      hash = ["Anna", "Ary", "Alice"].index_by { |e| e.size }
      assert hash == {4 => "Anna", 3 => "Ary", 5 => "Alice"}
    end

    it "overrides values if a value is returned twice" do
      hash = ["Anna", "Ary", "Alice", "Bob"].index_by { |e| e.size }
      assert hash == {4 => "Anna", 3 => "Bob", 5 => "Alice"}
    end
  end

  describe "reduce" do
    it { assert [1, 2, 3].reduce { |memo, i| memo + i } == 6 }
    it { assert [1, 2, 3].reduce(10) { |memo, i| memo + i } == 16 }

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).reduce { |memo, i| memo + i }
      end
    end

    it "does not raise if empty if there is a memo argument" do
      result = ([] of Int32).reduce(10) { |memo, i| memo + i }
      assert result == 10
    end
  end

  describe "join" do
    it "joins with separator and block" do
      str = [1, 2, 3].join(", ") { |x| x + 1 }
      assert str == "2, 3, 4"
    end

    it "joins without separator and block" do
      str = [1, 2, 3].join { |x| x + 1 }
      assert str == "234"
    end

    it "joins with io and block" do
      str = MemoryIO.new
      [1, 2, 3].join(", ", str) { |x, io| io << x + 1 }
      assert str.to_s == "2, 3, 4"
    end

    it "joins with only separator" do
      assert ["Ruby", "Crystal", "Python"].join(", ") == "Ruby, Crystal, Python"
    end
  end

  describe "map" do
    it "applies the function to each element and returns a new array" do
      result = [1, 2, 3].map { |i| i * 10 }
      assert result == [10, 20, 30]
    end

    it "leaves the original unmodified" do
      original = [1, 2, 3]
      original.map { |i| i * 10 }
      assert original == [1, 2, 3]
    end
  end

  describe "map_with_index" do
    it "yields the element and the index" do
      result = ["Alice", "Bob"].map_with_index { |name, i| "User ##{i}: #{name}" }
      assert result == ["User #0: Alice", "User #1: Bob"]
    end
  end

  describe "max" do
    it { assert [1, 2, 3].max == 3 }

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).max
      end
    end
  end

  describe "max?" do
    it "returns nil if empty" do
      assert ([] of Int32).max?.nil?
    end
  end

  describe "max_by" do
    it { assert [-1, -2, -3].max_by { |x| -x } == -3 }
  end

  describe "max_by?" do
    it "returns nil if empty" do
      assert ([] of Int32).max_by? { |x| -x }.nil?
    end
  end

  describe "max_of" do
    it { assert [-1, -2, -3].max_of { |x| -x } == 3 }
  end

  describe "max_of?" do
    it "returns nil if empty" do
      assert ([] of Int32).max_of? { |x| -x }.nil?
    end
  end

  describe "min" do
    it { assert [1, 2, 3].min == 1 }

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).min
      end
    end
  end

  describe "min?" do
    it "returns nil if empty" do
      assert ([] of Int32).min?.nil?
    end
  end

  describe "min_by" do
    it { assert [1, 2, 3].min_by { |x| -x } == 3 }
  end

  describe "min_by?" do
    it "returns nil if empty" do
      assert ([] of Int32).max_by? { |x| -x }.nil?
    end
  end

  describe "min_of" do
    it { assert [1, 2, 3].min_of { |x| -x } == -3 }
  end

  describe "min_of?" do
    it "returns nil if empty" do
      assert ([] of Int32).min_of? { |x| -x }.nil?
    end
  end

  describe "minmax" do
    it { assert [1, 2, 3].minmax == {1, 3} }

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).minmax
      end
    end
  end

  describe "minmax?" do
    it "returns two nils if empty" do
      assert ([] of Int32).minmax? == {nil, nil}
    end
  end

  describe "minmax_by" do
    it { assert [-1, -2, -3].minmax_by { |x| -x } == {-1, -3} }
  end

  describe "minmax_by?" do
    it "returns two nils if empty" do
      assert ([] of Int32).minmax_by? { |x| -x } == {nil, nil}
    end
  end

  describe "minmax_of" do
    it { assert [-1, -2, -3].minmax_of { |x| -x } == {1, 3} }
  end

  describe "minmax_of?" do
    it "returns two nils if empty" do
      assert ([] of Int32).minmax_of? { |x| -x } == {nil, nil}
    end
  end

  describe "none?" do
    it { assert [1, 2, 2, 3].none? { |x| x == 1 } == false }
    it { assert [1, 2, 2, 3].none? { |x| x == 0 } == true }
  end

  describe "none? without block" do
    it { assert [nil, false].none? == true }
    it { assert [nil, false, true].none? == false }
  end

  describe "one?" do
    it { assert [1, 2, 2, 3].one? { |x| x == 1 } == true }
    it { assert [1, 2, 2, 3].one? { |x| x == 2 } == false }
    it { assert [1, 2, 2, 3].one? { |x| x == 0 } == false }
  end

  describe "partition" do
    it { assert [1, 2, 2, 3].partition { |x| x == 2 } == {[2, 2], [1, 3]} }
    it { assert [1, 2, 3, 4, 5, 6].partition(&.even?) == {[2, 4, 6], [1, 3, 5]} }
  end

  describe "reject" do
    it "rejects the values for which the block returns true" do
      assert [1, 2, 3, 4].reject(&.even?) == [1, 3]
    end
  end

  describe "select" do
    it "selects the values for which the block returns true" do
      assert [1, 2, 3, 4].select(&.even?) == [2, 4]
    end
  end

  describe "skip" do
    it "returns an array without the skipped elements" do
      assert [1, 2, 3, 4, 5, 6].skip(3) == [4, 5, 6]
    end

    it "returns an empty array when skipping more elements than array size" do
      assert [1, 2].skip(3) == [] of Int32
    end

    it "raises if count is negative" do
      expect_raises(ArgumentError) do
        [1, 2].skip(-1)
      end
    end
  end

  describe "skip_while" do
    it "skips elements while the condition holds true" do
      result = [1, 2, 3, 4, 5, 0].skip_while { |i| i < 3 }
      assert result == [3, 4, 5, 0]
    end

    it "returns an empty array if the condition is always true" do
      assert [1, 2, 3].skip_while { true } == [] of Int32
    end

    it "returns the full Array if the the first check is false" do
      assert [5, 0, 1, 2, 3].skip_while { |x| x < 4 } == [5, 0, 1, 2, 3]
    end

    it "does not yield to the block anymore once it returned false" do
      called = 0
      [1, 2, 3, 4, 4].skip_while do |i|
        called += 1
        i < 3
      end
      assert called == 3
    end
  end

  describe "sum" do
    it { assert ([] of Int32).sum == 0 }
    it { assert [1, 2, 3].sum == 6 }
    it { assert [1, 2, 3].sum(4) == 10 }
    it { assert [1, 2, 3].sum(4.5) == 10.5 }
    it { assert (1..3).sum { |x| x * 2 } == 12 }
    it { assert (1..3).sum(1.5) { |x| x * 2 } == 13.5 }

    it "uses zero from type" do
      assert typeof([1, 2, 3].sum) == Int32
      assert typeof([1.5, 2.5, 3.5].sum) == Float64
      assert typeof([1, 2, 3].sum(&.to_f)) == Float64
    end
  end

  describe "product" do
    it { assert ([] of Int32).product == 1 }
    it { assert [1, 2, 3].product == 6 }
    it { assert [1, 2, 3].product(4) == 24 }
    it { assert [1, 2, 3].product(4.5) == 27 }
    it { assert (1..3).product { |x| x * 2 } == 48 }
    it { assert (1..3).product(1.5) { |x| x * 2 } == 72 }

    it "uses zero from type" do
      assert typeof([1, 2, 3].product) == Int32
      assert typeof([1.5, 2.5, 3.5].product) == Float64
      assert typeof([1, 2, 3].product(&.to_f)) == Float64
    end
  end

  describe "first" do
    it { assert (1..3).first(1) == [1] }
    it { assert (1..3).first(4) == [1, 2, 3] }

    it "raises if count is negative" do
      expect_raises(ArgumentError) do
        (1..2).first(-1)
      end
    end
  end

  describe "take_while" do
    it "keeps elements while the block returns true" do
      assert [1, 2, 3, 4, 5, 0].take_while { |i| i < 3 } == [1, 2]
    end

    it "returns the full Array if the condition is always true" do
      assert [1, 2, 3, -3].take_while { true } == [1, 2, 3, -3]
    end

    it "returns an empty Array if the block is false for the first element" do
      assert [1, 2, -1, 0].take_while { |i| i <= 0 } == [] of Int32
    end

    it "does not call the block again once it returned false" do
      called = 0
      [1, 2, 3, 4, 0].take_while do |i|
        called += 1
        i < 3
      end
      assert called == 3
    end
  end

  describe "to_a" do
    it "converts to an Array" do
      assert (1..3).to_a == [1, 2, 3]
    end
  end

  describe "to_h" do
    it "for tuples" do
      hash = Tuple.new({:a, 1}, {:c, 2}).to_h
      assert hash.is_a?(Hash(Symbol, Int32))
      assert hash == {:a => 1, :c => 2}
    end

    it "for array" do
      assert [[:a, :b], [:c, :d]].to_h == {:a => :b, :c => :d}
    end
  end
end
