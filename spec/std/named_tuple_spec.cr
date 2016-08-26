require "spec"

describe "NamedTuple" do
  it "does new" do
    assert NamedTuple.new(x: 1, y: 2) == {x: 1, y: 2}
  end

  it "does NamedTuple.from" do
    t = NamedTuple(foo: Int32, bar: Int32).from({:foo => 1, :bar => 2})
    assert t == {foo: 1, bar: 2}
    assert t.class == NamedTuple(foo: Int32, bar: Int32)

    t = NamedTuple(foo: Int32, bar: Int32).from({"foo" => 1, "bar" => 2})
    assert t == {foo: 1, bar: 2}
    assert t.class == NamedTuple(foo: Int32, bar: Int32)

    t = NamedTuple("foo bar": Int32, "baz qux": Int32).from({"foo bar" => 1, "baz qux" => 2})
    assert t == {"foo bar": 1, "baz qux": 2}
    assert t.class == NamedTuple("foo bar": Int32, "baz qux": Int32)

    expect_raises ArgumentError do
      NamedTuple(foo: Int32, bar: Int32).from({:foo => 1})
    end

    expect_raises KeyError do
      NamedTuple(foo: Int32, bar: Int32).from({:foo => 1, :baz => 2})
    end

    expect_raises(TypeCastError, /cast from String to Int32 failed/) do
      NamedTuple(foo: Int32, bar: Int32).from({:foo => 1, :bar => "foo"})
    end
  end

  it "does NamedTuple#from" do
    t = {foo: Int32, bar: Int32}.from({:foo => 1, :bar => 2})
    assert t == {foo: 1, bar: 2}
    assert t.class == NamedTuple(foo: Int32, bar: Int32)

    t = {foo: Int32, bar: Int32}.from({"foo" => 1, "bar" => 2})
    assert t == {foo: 1, bar: 2}
    assert t.class == NamedTuple(foo: Int32, bar: Int32)

    expect_raises ArgumentError do
      {foo: Int32, bar: Int32}.from({:foo => 1})
    end

    expect_raises KeyError do
      {foo: Int32, bar: Int32}.from({:foo => 1, :baz => 2})
    end

    expect_raises(TypeCastError, /cast from String to Int32 failed/) do
      {foo: Int32, bar: Int32}.from({:foo => 1, :bar => "foo"})
    end
  end

  it "gets size" do
    assert {a: 1, b: 3}.size == 2
  end

  it "does [] with runtime key" do
    tup = {a: 1, b: 'a'}

    key = :a
    val = tup[key]
    assert typeof(val) == Int32 | Char
    assert val == 1

    key = :b
    val = tup[key]
    assert typeof(val) == Int32 | Char
    assert val == 'a'

    expect_raises(KeyError) do
      key = :c
      tup[key]
    end
  end

  it "does []? with runtime key" do
    tup = {a: 1, b: 'a'}

    key = :a
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val == 1

    key = :b
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val == 'a'

    key = :c
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val.nil?
  end

  it "does [] with string" do
    tup = {a: 1, b: 'a'}

    key = "a"
    val = tup[key]
    assert typeof(val) == Int32 | Char
    assert val == 1

    key = "b"
    val = tup[key]
    assert typeof(val) == Int32 | Char
    assert val == 'a'

    expect_raises(KeyError) do
      key = "c"
      tup[key]
    end
  end

  it "does []? with string" do
    tup = {a: 1, b: 'a'}

    key = "a"
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val == 1

    key = "b"
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val == 'a'

    key = "c"
    val = tup[key]?
    assert typeof(val) == Int32 | Char | Nil
    assert val.nil?
  end

  it "computes a hash value" do
    tup1 = {a: 1, b: 'a'}
    assert tup1.hash != 0

    tup2 = {b: 'a', a: 1}
    assert tup2.hash == tup1.hash
  end

  it "does each" do
    tup = {a: 1, b: "hello"}
    i = 0
    tup.each do |key, value|
      case i
      when 0
        assert key == :a
        assert value == 1
      when 1
        assert key == :b
        assert value == "hello"
      end
      i += 1
    end
    assert i == 2
  end

  it "does each_key" do
    tup = {a: 1, b: "hello"}
    i = 0
    tup.each_key do |key|
      case i
      when 0
        assert key == :a
      when 1
        assert key == :b
      end
      i += 1
    end
    assert i == 2
  end

  it "does each_value" do
    tup = {a: 1, b: "hello"}
    i = 0
    tup.each_value do |value|
      case i
      when 0
        assert value == 1
      when 1
        assert value == "hello"
      end
      i += 1
    end
    assert i == 2
  end

  it "does each_with_index" do
    tup = {a: 1, b: "hello"}
    i = 0
    tup.each_with_index do |key, value, index|
      case i
      when 0
        assert key == :a
        assert value == 1
        assert index == 0
      when 1
        assert key == :b
        assert value == "hello"
        assert index == 1
      end
      i += 1
    end
    assert i == 2
  end

  it "does has_key?" do
    tup = {a: 1, b: 'a'}
    assert tup.has_key?(:a) == true
    assert tup.has_key?(:b) == true
    assert tup.has_key?(:c) == false
  end

  it "does empty" do
    assert {a: 1}.empty? == false
  end

  it "does to_a" do
    tup = {a: 1, b: 'a'}
    assert tup.to_a == [{:a, 1}, {:b, 'a'}]
  end

  it "does key_index" do
    tup = {a: 1, b: 'a'}
    assert tup.to_a == [{:a, 1}, {:b, 'a'}]
  end

  it "does map" do
    tup = {a: 1, b: 'a'}
    strings = tup.map { |k, v| "#{k.inspect}-#{v.inspect}" }
    assert strings == [":a-1", ":b-'a'"]
  end

  it "compares with same named tuple type" do
    tup1 = {a: 1, b: 'a'}
    tup2 = {b: 'a', a: 1}
    tup3 = {a: 1, b: 'b'}
    assert tup1 == tup2
    assert tup1 != tup3
  end

  it "compares with other named tuple type" do
    tup1 = {a: 1, b: 'a'}
    tup2 = {b: 'a', a: 1.0}
    tup3 = {b: 'a', a: 1.1}
    assert tup1 == tup2
    assert tup1 != tup3
  end

  it "does to_h" do
    tup1 = {a: 1, b: "hello"}
    hash = tup1.to_h
    assert hash == {:a => 1, :b => "hello"}
  end

  it "does to_s" do
    tup = {a: 1, b: "hello"}
    assert tup.to_s == %({a: 1, b: "hello"})
  end

  it "dups" do
    tup1 = {a: 1, b: [1, 2, 3]}
    tup2 = tup1.dup

    tup1[:b] << 4
    assert tup2[:b].same?(tup1[:b])
  end

  it "clones" do
    tup1 = {a: 1, b: [1, 2, 3]}
    tup2 = tup1.clone

    tup1[:b] << 4
    assert tup2[:b] == [1, 2, 3]

    tup2 = {"foo bar": 1}
    assert tup2.clone == tup2
  end

  it "does keys" do
    tup = {a: 1, b: 2}
    assert tup.keys == {:a, :b}
  end

  it "does values" do
    tup = {a: 1, b: 'a'}
    assert tup.values == {1, 'a'}
  end
end
