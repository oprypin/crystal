require "spec"
require "simple_hash"

describe "SimpleHash" do
  describe "[]" do
    it "returns the value corresponding to the given key" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      assert a[1] == 2
      assert a[3] == 4
      assert a[5] == 6
      assert a[7] == 8

      a = SimpleHash{:one => :two, :three => :four, :five => :six}
      assert a[:three] == :four
    end

    it "raises on a missing key" do
      a = SimpleHash{:one => :two, :three => :four}
      expect_raises KeyError do
        a[:five]
      end
    end
  end

  describe "[]?" do
    it "returns nil if the key is missing" do
      a = SimpleHash{"one" => 1, "two" => 2}
      assert a["three"]? == nil
      assert a[:one]? == nil
    end
  end

  describe "fetch" do
    it "returns the value corresponding to the given key, yields otherwise" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      assert a.fetch(1) { 10 } == 2
      assert a.fetch(3) { 10 } == 4
      assert a.fetch(5) { 10 } == 6
      assert a.fetch(7) { 10 } == 8
      assert a.fetch(9) { 10 } == 10
    end
  end

  describe "[]=" do
    it "adds a new key-value pair if the key is missing" do
      a = SimpleHash(Int32, Int32).new
      a[1] = 2
      assert a[1] == 2
    end

    it "replaces the value if the key already exists" do
      a = SimpleHash(Int32, Int32).new
      a[1] = 2
      a[1] = 3
      assert a[1] == 3
    end
  end

  describe "has_key?" do
    it "returns true if the given key is present, false otherwise" do
      a = SimpleHash{"one" => 1, "two" => 2}
      assert a.has_key?("one") == true
      assert a.has_key?("two") == true
      assert a.has_key?(:one) == false
    end
  end

  describe "delete" do
    it "deletes the key-value pair corresponding to the given key" do
      a = SimpleHash{"one" => 1, "two" => 2}
      a.delete("two")
      assert a["two"]? == nil
      assert a["one"] == 1
    end
  end

  describe "dup" do
    it "returns a duplicate of the SimpleHash" do
      a = SimpleHash{"one" => "1", "two" => "2"}
      assert a == a.dup
    end
  end

  describe "each" do
    it "yields the key and value of each key-value pair" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      count = 0
      a.each { |k, v| count += k - v }
      assert count == -4

      count = 0
      a.each { |k, v| count += v - k }
      assert count == 4
    end
  end

  describe "each_key" do
    it "yields every key" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      count = 0
      a.each_key { |k| count += k }
      assert count == 16
    end
  end

  describe "each_value" do
    it "yields every value" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      count = 0
      a.each_value { |v| count += v }
      assert count == 20
    end
  end

  describe "each_with_object" do
    it "passes memo, key and value into block" do
      hash = SimpleHash{:a => 'b'}
      hash.each_with_object(:memo) do |memo, k, v|
        assert memo == :memo
        assert k == :a
        assert v == 'b'
      end
    end

    it "reduces the hash to the accumulated value of memo" do
      hash = SimpleHash{:a => 'b', :c => 'd', :e => 'f'}
      result = hash.each_with_object(SimpleHash(Char, Symbol).new) do |memo, k, v|
        memo[v] = k
      end
      assert result == SimpleHash{'b' => :a, 'd' => :c, 'f' => :e}
    end
  end

  describe "keys" do
    it "returns an array of all the keys" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      b = [1, 3, 5, 7]
      assert a.keys == b
    end
  end

  describe "values" do
    it "returns an array of all the values" do
      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      b = [2, 4, 6, 8]
      assert a.values == b
    end
  end

  it "selects" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.select { |k, v| k == :b }
    assert h2 == SimpleHash{:b => 2}
    assert h2.object_id != h1.object_id
  end

  it "selects!" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.select! { |k, v| k == :b }
    assert h2 == SimpleHash{:b => 2}
    assert h2.object_id == h1.object_id
  end

  it "returns nil when using select! and no changes were made" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.select! { true }
    assert h2 == nil
    assert h1 == SimpleHash{:a => 1, :b => 2, :c => 3}
  end

  it "rejects" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.reject { |k, v| k == :b }
    assert h2 == SimpleHash{:a => 1, :c => 3}
    assert h2.object_id != h1.object_id
  end

  it "rejects!" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.reject! { |k, v| k == :b }
    assert h2 == SimpleHash{:a => 1, :c => 3}
    assert h2.object_id == h1.object_id
  end

  it "returns nil when using reject! and no changes were made" do
    h1 = SimpleHash{:a => 1, :b => 2, :c => 3}

    h2 = h1.reject! { false }
    assert h2 == nil
    assert h1 == SimpleHash{:a => 1, :b => 2, :c => 3}
  end

  describe "size" do
    it "returns the number of key-value pairs" do
      a = SimpleHash(Int32, Int32).new
      assert a.size == 0

      a = SimpleHash{1 => 2}
      assert a.size == 1

      a = SimpleHash{1 => 2, 3 => 4, 5 => 6, 7 => 8}
      assert a.size == 4
    end
  end

  describe "to_s" do
    it "returns a string representation" do
      a = SimpleHash(Int32, Int32).new
      assert a.to_s == "{}"

      a = SimpleHash{1 => 2}
      assert a.to_s == "{1 => 2}"

      a = SimpleHash{:one => 1, :two => 2, :three => 3}
      assert a.to_s == "{:one => 1, :two => 2, :three => 3}"
    end
  end
end
