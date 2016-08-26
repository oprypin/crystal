require "spec"

module HashSpec
  alias RecursiveHash = Hash(RecursiveHash, RecursiveHash)

  class HashBreaker
    getter x : Int32

    def initialize(@x)
    end
  end

  class NeverInstantiated
  end

  alias RecursiveType = String | Int32 | Array(RecursiveType) | Hash(Symbol, RecursiveType)
end

describe "Hash" do
  describe "empty" do
    it "size should be zero" do
      h = {} of Int32 => Int32
      assert h.size == 0
      assert h.empty? == true
    end
  end

  it "sets and gets" do
    a = {} of Int32 => Int32
    a[1] = 2
    assert a[1] == 2
  end

  it "gets from literal" do
    a = {1 => 2}
    assert a[1] == 2
  end

  it "gets from union" do
    a = {1 => 2, :foo => 1.1}
    assert a[1] == 2
  end

  it "gets nilable" do
    a = {1 => 2}
    assert a[1]? == 2
    assert a[2]?.nil?
  end

  it "gets array of keys" do
    a = {} of Symbol => Int32
    assert a.keys == [] of Symbol
    a[:foo] = 1
    a[:bar] = 2
    assert a.keys == [:foo, :bar]
  end

  it "gets array of values" do
    a = {} of Symbol => Int32
    assert a.values == [] of Int32
    a[:foo] = 1
    a[:bar] = 2
    assert a.values == [1, 2]
  end

  describe "==" do
    it do
      a = {1 => 2, 3 => 4}
      b = {3 => 4, 1 => 2}
      c = {2 => 3}
      d = {5 => 6, 7 => 8}
      assert a == a
      assert a == b
      assert b == a
      assert a != c
      assert c != a
      assert d != a
    end

    it do
      a = {1 => nil}
      b = {3 => 4}
      assert a != b
    end

    it "compares hash of nested hash" do
      a = { {1 => 2} => 3 }
      b = { {1 => 2} => 3 }
      assert a == b
    end
  end

  describe "[]" do
    it "gets" do
      a = {1 => 2}
      assert a[1] == 2
      # a[2].should raise_exception
      assert a == {1 => 2}
    end
  end

  describe "[]=" do
    it "overrides value" do
      a = {1 => 2}
      a[1] = 3
      assert a[1] == 3
    end
  end

  describe "fetch" do
    it "fetches with one argument" do
      a = {1 => 2}
      assert a.fetch(1) == 2
      assert a == {1 => 2}
    end

    it "fetches with default value" do
      a = {1 => 2}
      assert a.fetch(1, 3) == 2
      assert a.fetch(2, 3) == 3
      assert a == {1 => 2}
    end

    it "fetches with block" do
      a = {1 => 2}
      assert a.fetch(1) { |k| k * 3 } == 2
      assert a.fetch(2) { |k| k * 3 } == 6
      assert a == {1 => 2}
    end

    it "fetches and raises" do
      a = {1 => 2}
      expect_raises KeyError, "Missing hash key: 2" do
        a.fetch(2)
      end
    end
  end

  describe "values_at" do
    it "returns the given keys" do
      assert {"a" => 1, "b" => 2, "c" => 3, "d" => 4}.values_at("b", "a", "c") == {2, 1, 3}
    end

    it "raises when passed an invalid key" do
      expect_raises KeyError do
        {"a" => 1}.values_at("b")
      end
    end

    it "works with mixed types" do
      assert {1 => :a, "a" => 1, 1.0 => "a", :a => 1.0}.values_at(1, "a", 1.0, :a) == {:a, 1, "a", 1.0}
    end
  end

  describe "key" do
    it "returns the first key with the given value" do
      hash = {"foo" => "bar", "baz" => "qux"}
      assert hash.key("bar") == "foo"
      assert hash.key("qux") == "baz"
    end

    it "raises when no key pairs with the given value" do
      expect_raises KeyError do
        {"foo" => "bar"}.key("qux")
      end
    end

    describe "if block is given," do
      it "returns the first key with the given value" do
        hash = {"foo" => "bar", "baz" => "bar"}
        assert hash.key("bar") { |value| value.upcase } == "foo"
      end

      it "yields the argument if no hash key pairs with the value" do
        hash = {"foo" => "bar"}
        assert hash.key("qux") { |value| value.upcase } == "QUX"
      end
    end
  end

  describe "key?" do
    it "returns the first key with the given value" do
      hash = {"foo" => "bar", "baz" => "qux"}
      assert hash.key?("bar") == "foo"
      assert hash.key?("qux") == "baz"
    end

    it "returns nil if no key pairs with the given value" do
      hash = {"foo" => "bar", "baz" => "qux"}
      assert hash.key?("foobar") == nil
      assert hash.key?("bazqux") == nil
    end
  end

  describe "has_key?" do
    it "doesn't have key" do
      a = {1 => 2}
      assert a.has_key?(2) == false
    end

    it "has key" do
      a = {1 => 2}
      assert a.has_key?(1) == true
    end
  end

  describe "has_value?" do
    it "returns true if contains the value" do
      a = {1 => 2, 3 => 4, 5 => 6}
      assert a.has_value?(4) == true
    end

    it "returns false if does not contain the value" do
      a = {1 => 2, 3 => 4, 5 => 6}
      assert a.has_value?(3) == false
    end
  end

  describe "delete" do
    it "deletes key in the beginning" do
      a = {1 => 2, 3 => 4, 5 => 6}
      assert a.delete(1) == 2
      assert a.has_key?(1) == false
      assert a.has_key?(3) == true
      assert a.has_key?(5) == true
      assert a.size == 2
      assert a == {3 => 4, 5 => 6}
    end

    it "deletes key in the middle" do
      a = {1 => 2, 3 => 4, 5 => 6}
      assert a.delete(3) == 4
      assert a.has_key?(1) == true
      assert a.has_key?(3) == false
      assert a.has_key?(5) == true
      assert a.size == 2
      assert a == {1 => 2, 5 => 6}
    end

    it "deletes key in the end" do
      a = {1 => 2, 3 => 4, 5 => 6}
      assert a.delete(5) == 6
      assert a.has_key?(1) == true
      assert a.has_key?(3) == true
      assert a.has_key?(5) == false
      assert a.size == 2
      assert a == {1 => 2, 3 => 4}
    end

    it "deletes only remaining entry" do
      a = {1 => 2}
      assert a.delete(1) == 2
      assert a.has_key?(1) == false
      assert a.size == 0
      assert a == {} of Int32 => Int32
    end

    it "deletes not found" do
      a = {1 => 2}
      assert a.delete(2).nil?
    end
  end

  describe "size" do
    it "is the same as size" do
      a = {} of Int32 => Int32
      assert a.size == a.size

      a = {1 => 2}
      assert a.size == a.size

      a = {1 => 2, 3 => 4, 5 => 6, 7 => 8}
      assert a.size == a.size
    end
  end

  it "maps" do
    hash = {1 => 2, 3 => 4}
    array = hash.map { |k, v| k + v }
    assert array == [3, 7]
  end

  describe "to_s" do
    it { assert {1 => 2, 3 => 4}.to_s == "{1 => 2, 3 => 4}" }

    it do
      h = {} of HashSpec::RecursiveHash => HashSpec::RecursiveHash
      h[h] = h
      assert h.to_s == "{{...} => {...}}"
    end
  end

  it "does to_h" do
    h = {:a => 1}
    assert h.to_h.same?(h)
  end

  it "clones" do
    h1 = {1 => 2, 3 => 4}
    h2 = h1.clone
    assert !h1.same?(h2)
    assert h1 == h2
  end

  it "initializes with block" do
    h1 = Hash(String, Array(Int32)).new { |h, k| h[k] = [] of Int32 }
    assert h1["foo"] == [] of Int32
    h1["bar"].push 2
    assert h1["bar"] == [2]
  end

  it "initializes with default value" do
    h = Hash(Int32, Int32).new(10)
    assert h[0] == 10
    assert h.has_key?(0) == false
    h[1] += 2
    assert h[1] == 12
    assert h.has_key?(1) == true
  end

  it "merges" do
    h1 = {1 => 2, 3 => 4}
    h2 = {1 => 5, 2 => 3}
    h3 = {"1" => "5", "2" => "3"}

    h4 = h1.merge(h2)
    assert !h4.same?(h1)
    assert h4 == {1 => 5, 3 => 4, 2 => 3}

    h5 = h1.merge(h3)
    assert !h5.same?(h1)
    assert h5 == {1 => 2, 3 => 4, "1" => "5", "2" => "3"}
  end

  it "merges with block" do
    h1 = {1 => 5, 2 => 3}
    h2 = {1 => 5, 3 => 4, 2 => 3}

    h3 = h2.merge(h1) { |k, v1, v2| k + v1 + v2 }
    assert !h3.same?(h2)
    assert h3 == {1 => 11, 3 => 4, 2 => 8}
  end

  it "merges recursive type (#1693)" do
    hash = {:foo => "bar"} of Symbol => HashSpec::RecursiveType
    result = hash.merge({:foobar => "foo"})
    assert result == {:foo => "bar", :foobar => "foo"}
  end

  it "merges!" do
    h1 = {1 => 2, 3 => 4}
    h2 = {1 => 5, 2 => 3}

    h3 = h1.merge!(h2)
    assert h3.same?(h1)
    assert h3 == {1 => 5, 3 => 4, 2 => 3}
  end

  it "merges! with block" do
    h1 = {1 => 5, 2 => 3}
    h2 = {1 => 5, 3 => 4, 2 => 3}

    h3 = h2.merge!(h1) { |k, v1, v2| k + v1 + v2 }
    assert h3.same?(h2)
    assert h3 == {1 => 11, 3 => 4, 2 => 8}
  end

  it "merges! with block and nilable keys" do
    h1 = {1 => nil, 2 => 4, 3 => "x"}
    h2 = {1 => 2, 2 => nil, 3 => "y"}

    h3 = h1.merge!(h2) { |k, v1, v2| (v1 || v2).to_s }
    assert h3.same?(h1)
    assert h3 == {1 => "2", 2 => "4", 3 => "x"}
  end

  it "selects" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.select { |k, v| k == :b }
    assert h2 == {:b => 2}
    assert !h2.same?(h1)
  end

  it "selects!" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.select! { |k, v| k == :b }
    assert h2 == {:b => 2}
    assert h2.same?(h1)
  end

  it "returns nil when using select! and no changes were made" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.select! { true }
    assert h2 == nil
    assert h1 == {:a => 1, :b => 2, :c => 3}
  end

  it "rejects" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.reject { |k, v| k == :b }
    assert h2 == {:a => 1, :c => 3}
    assert !h2.same?(h1)
  end

  it "rejects!" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.reject! { |k, v| k == :b }
    assert h2 == {:a => 1, :c => 3}
    assert h2.same?(h1)
  end

  it "returns nil when using reject! and no changes were made" do
    h1 = {:a => 1, :b => 2, :c => 3}

    h2 = h1.reject! { false }
    assert h2 == nil
    assert h1 == {:a => 1, :b => 2, :c => 3}
  end

  it "zips" do
    ary1 = [1, 2, 3]
    ary2 = ['a', 'b', 'c']
    hash = Hash.zip(ary1, ary2)
    assert hash == {1 => 'a', 2 => 'b', 3 => 'c'}
  end

  it "gets first" do
    h = {1 => 2, 3 => 4}
    assert h.first == {1, 2}
  end

  it "gets first key" do
    h = {1 => 2, 3 => 4}
    assert h.first_key == 1
  end

  it "gets first value" do
    h = {1 => 2, 3 => 4}
    assert h.first_value == 2
  end

  it "shifts" do
    h = {1 => 2, 3 => 4}
    assert h.shift == {1, 2}
    assert h == {3 => 4}
    assert h.shift == {3, 4}
    assert h.empty? == true
  end

  it "shifts?" do
    h = {1 => 2}
    assert h.shift? == {1, 2}
    assert h.empty? == true
    assert h.shift?.nil?
  end

  it "gets key index" do
    h = {1 => 2, 3 => 4}
    assert h.key_index(3) == 1
    assert h.key_index(2).nil?
  end

  it "inserts many" do
    times = 1000
    h = {} of Int32 => Int32
    times.times do |i|
      h[i] = i
      assert h.size == i + 1
    end
    times.times do |i|
      assert h[i] == i
    end
    assert h.first_key == 0
    assert h.first_value == 0
    times.times do |i|
      assert h.delete(i) == i
      assert h.has_key?(i) == false
      assert h.size == times - i - 1
    end
  end

  it "inserts in one bucket and deletes from the same one" do
    h = {11 => 1}
    assert h.delete(0).nil?
    assert h.has_key?(11) == true
    assert h.size == 1
  end

  it "does to_a" do
    h = {1 => "hello", 2 => "bye"}
    assert h.to_a == [{1, "hello"}, {2, "bye"}]
  end

  it "clears" do
    h = {1 => 2, 3 => 4}
    h.clear
    assert h.empty? == true
    assert h.to_a.size == 0
  end

  it "computes hash" do
    h = { {1 => 2} => {3 => 4} }
    assert h.hash != h.object_id

    h2 = { {1 => 2} => {3 => 4} }
    assert h.hash == h2.hash

    h3 = {1 => 2, 3 => 4}
    h4 = {3 => 4, 1 => 2}
    assert h3.hash == h4.hash
  end

  it "fetches from empty hash with default value" do
    x = {} of Int32 => HashSpec::HashBreaker
    breaker = x.fetch(10) { HashSpec::HashBreaker.new(1) }
    assert breaker.x == 1
  end

  it "does to to_s with instance that was never instantiated" do
    x = {} of Int32 => HashSpec::NeverInstantiated
    assert x.to_s == "{}"
  end

  it "inverts" do
    h1 = {"one" => 1, "two" => 2, "three" => 3}
    h2 = {"a" => 1, "b" => 2, "c" => 1}

    assert h1.invert == {1 => "one", 2 => "two", 3 => "three"}

    h3 = h2.invert
    assert h3.size == 2
    assert %w(a c).includes? h3[1]
  end

  it "gets each iterator" do
    iter = {:a => 1, :b => 2}.each
    assert iter.next == {:a, 1}
    assert iter.next == {:b, 2}
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == {:a, 1}
  end

  it "gets each key iterator" do
    iter = {:a => 1, :b => 2}.each_key
    assert iter.next == :a
    assert iter.next == :b
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == :a
  end

  it "gets each value iterator" do
    iter = {:a => 1, :b => 2}.each_value
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1
  end

  describe "each_with_index" do
    it "pass key, value, index values into block" do
      hash = {2 => 4, 5 => 10, 7 => 14}
      results = [] of Int32
      hash.each_with_index { |(k, v), i| results << k + v + i }
      assert results == [6, 16, 23]
    end

    it "can be used with offset" do
      hash = {2 => 4, 5 => 10, 7 => 14}
      results = [] of Int32
      hash.each_with_index(3) { |(k, v), i| results << k + v + i }
      assert results == [9, 19, 26]
    end
  end

  describe "each_with_object" do
    it "passes memo, key and value into block" do
      hash = {:a => 'b'}
      hash.each_with_object(:memo) do |(k, v), memo|
        assert memo == :memo
        assert k == :a
        assert v == 'b'
      end
    end

    it "reduces the hash to the accumulated value of memo" do
      hash = {:a => 'b', :c => 'd', :e => 'f'}
      result = nil
      result = hash.each_with_object({} of Char => Symbol) do |(k, v), memo|
        memo[v] = k
      end
      assert result == {'b' => :a, 'd' => :c, 'f' => :e}
    end
  end

  describe "all?" do
    it "passes key and value into block" do
      hash = {:a => 'b'}
      hash.all? do |k, v|
        assert k == :a
        assert v == 'b'
      end
    end

    it "returns true if the block evaluates truthy for every kv pair" do
      hash = {:a => 'b', :c => 'd'}
      result = hash.all? { |k, v| v < 'e' ? "truthy" : nil }
      assert result == true
      hash[:d] = 'e'
      result = hash.all? { |k, v| v < 'e' ? "truthy" : nil }
      assert result == false
    end

    it "evaluates the block for only for as many kv pairs as necessary" do
      hash = {:a => 'b', :c => 'd'}
      hash.all? do |k, v|
        raise Exception.new("continued iterating") if v == 'd'
        v == 'a' # this is false for the first kv pair
      end
    end
  end

  describe "any?" do
    it "passes key and value into block" do
      hash = {:a => 'b'}
      hash.any? do |k, v|
        assert k == :a
        assert v == 'b'
      end
    end

    it "returns true if the block evaluates truthy for at least one kv pair" do
      hash = {:a => 'b', :c => 'd'}
      result = hash.any? { |k, v| v > 'b' ? "truthy" : nil }
      assert result == true
      hash[:d] = 'e'
      result = hash.any? { |k, v| v > 'e' ? "truthy" : nil }
      assert result == false
    end

    it "evaluates the block for only for as many kv pairs as necessary" do
      hash = {:a => 'b', :c => 'd'}
      hash.any? do |k, v|
        raise Exception.new("continued iterating") if v == 'd'
        v == 'b' # this is true for the first kv pair
      end
    end

    it "returns true if the hash contains at least one kv pair and no block is given" do
      hash = {:a => 'b'}
      result = hash.any?
      assert result == true

      hash = {} of Symbol => Char
      result = hash.any?
      assert result == false
    end
  end

  describe "reduce" do
    it "passes memo, key and value into block" do
      hash = {:a => 'b'}
      hash.reduce(:memo) do |memo, (k, v)|
        assert memo == :memo
        assert k == :a
        assert v == 'b'
      end
    end

    it "reduces the hash to the accumulated value of memo" do
      hash = {:a => 'b', :c => 'd', :e => 'f'}
      result = hash.reduce("") do |memo, (k, v)|
        memo + v
      end
      assert result == "bdf"
    end
  end

  describe "reject" do
    it { assert {:a => 2, :b => 3}.reject(:b, :d) == {:a => 2} }
    it { assert {:a => 2, :b => 3}.reject(:b, :a) == {} of Symbol => Int32 }
    it { assert {:a => 2, :b => 3}.reject([:b, :a]) == {} of Symbol => Int32 }
    it "does not change currrent hash" do
      h = {:a => 3, :b => 6, :c => 9}
      h2 = h.reject(:b, :c)
      assert h == {:a => 3, :b => 6, :c => 9}
    end
  end

  describe "reject!" do
    it { assert {:a => 2, :b => 3}.reject!(:b, :d) == {:a => 2} }
    it { assert {:a => 2, :b => 3}.reject!(:b, :a) == {} of Symbol => Int32 }
    it { assert {:a => 2, :b => 3}.reject!([:b, :a]) == {} of Symbol => Int32 }
    it "changes currrent hash" do
      h = {:a => 3, :b => 6, :c => 9}
      h.reject!(:b, :c)
      assert h == {:a => 3}
    end
  end

  describe "select" do
    it { assert {:a => 2, :b => 3}.select(:b, :d) == {:b => 3} }
    it { assert {:a => 2, :b => 3}.select == {} of Symbol => Int32 }
    it { assert {:a => 2, :b => 3}.select(:b, :a) == {:a => 2, :b => 3} }
    it { assert {:a => 2, :b => 3}.select([:b, :a]) == {:a => 2, :b => 3} }
    it "does not change currrent hash" do
      h = {:a => 3, :b => 6, :c => 9}
      h2 = h.select(:b, :c)
      assert h == {:a => 3, :b => 6, :c => 9}
    end
  end

  describe "select!" do
    it { assert {:a => 2, :b => 3}.select!(:b, :d) == {:b => 3} }
    it { assert {:a => 2, :b => 3}.select! == {} of Symbol => Int32 }
    it { assert {:a => 2, :b => 3}.select!(:b, :a) == {:a => 2, :b => 3} }
    it { assert {:a => 2, :b => 3}.select!([:b, :a]) == {:a => 2, :b => 3} }
    it "does change currrent hash" do
      h = {:a => 3, :b => 6, :c => 9}
      h.select!(:b, :c)
      assert h == {:b => 6, :c => 9}
    end
  end

  it "doesn't generate a negative index for the bucket index (#2321)" do
    items = (0..100000).map { rand(100000).to_i16 }
    items.uniq.size
  end

  it "creates with initial capacity" do
    hash = Hash(Int32, Int32).new(initial_capacity: 1234)
    assert hash.@buckets_size == 1234
  end

  it "creates with initial capacity and default value" do
    hash = Hash(Int32, Int32).new(default_value: 3, initial_capacity: 1234)
    assert hash[1] == 3
    assert hash.@buckets_size == 1234
  end

  it "creates with initial capacity and block" do
    hash = Hash(Int32, Int32).new(initial_capacity: 1234) { |h, k| h[k] = 3 }
    assert hash[1] == 3
    assert hash.@buckets_size == 1234
  end
end
