require "spec"
require "json"

describe JSON::Any do
  describe "casts" do
    it "gets nil" do
      assert JSON.parse("null").as_nil.nil?
    end

    it "gets bool" do
      assert JSON.parse("true").as_bool == true
      assert JSON.parse("false").as_bool == false
      assert JSON.parse("true").as_bool? == true
      assert JSON.parse("false").as_bool? == false
      assert JSON.parse("2").as_bool?.nil?
    end

    it "gets int" do
      assert JSON.parse("123").as_i == 123
      assert JSON.parse("123456789123456").as_i64 == 123456789123456
      assert JSON.parse("123").as_i? == 123
      assert JSON.parse("123456789123456").as_i64? == 123456789123456
      assert JSON.parse("true").as_i?.nil?
      assert JSON.parse("true").as_i64?.nil?
    end

    it "gets float" do
      assert JSON.parse("123.45").as_f == 123.45
      assert JSON.parse("123.45").as_f32 == 123.45_f32
      assert JSON.parse("123.45").as_f? == 123.45
      assert JSON.parse("123.45").as_f32? == 123.45_f32
      assert JSON.parse("true").as_f?.nil?
      assert JSON.parse("true").as_f32?.nil?
    end

    it "gets string" do
      assert JSON.parse(%("hello")).as_s == "hello"
      assert JSON.parse(%("hello")).as_s? == "hello"
      assert JSON.parse("true").as_s?.nil?
    end

    it "gets array" do
      assert JSON.parse(%([1, 2, 3])).as_a == [1, 2, 3]
      assert JSON.parse(%([1, 2, 3])).as_a? == [1, 2, 3]
      assert JSON.parse("true").as_a?.nil?
    end

    it "gets hash" do
      assert JSON.parse(%({"foo": "bar"})).as_h == {"foo" => "bar"}
      assert JSON.parse(%({"foo": "bar"})).as_h? == {"foo" => "bar"}
      assert JSON.parse("true").as_h?.nil?
    end
  end

  describe "#size" do
    it "of array" do
      assert JSON.parse("[1, 2, 3]").size == 3
    end

    it "of hash" do
      assert JSON.parse(%({"foo": "bar"})).size == 1
    end
  end

  describe "#[]" do
    it "of array" do
      assert JSON.parse("[1, 2, 3]")[1].raw == 2
    end

    it "of hash" do
      assert JSON.parse(%({"foo": "bar"}))["foo"].raw == "bar"
    end
  end

  describe "#[]?" do
    it "of array" do
      assert JSON.parse("[1, 2, 3]")[1]?.not_nil!.raw == 2
      assert JSON.parse("[1, 2, 3]")[3]?.nil?
    end

    it "of hash" do
      assert JSON.parse(%({"foo": "bar"}))["foo"]?.not_nil!.raw == "bar"
      assert JSON.parse(%({"foo": "bar"}))["fox"]?.nil?
    end
  end

  describe "each" do
    it "of array" do
      elems = [] of Int32
      JSON.parse("[1, 2, 3]").each do |any|
        elems << any.as_i
      end
      assert elems == [1, 2, 3]
    end

    it "of hash" do
      elems = [] of String
      JSON.parse(%({"foo": "bar"})).each do |key, value|
        elems << key.to_s << value.to_s
      end
      assert elems == %w(foo bar)
    end
  end

  it "traverses big structure" do
    obj = JSON.parse(%({"foo": [1, {"bar": [2, 3]}]}))
    assert obj["foo"][1]["bar"][1].as_i == 3
  end

  it "compares to other objects" do
    obj = JSON.parse(%([1, 2]))
    assert obj == [1, 2]
    assert obj[0] == 1
  end

  it "can compare with ===" do
    assert 1 === JSON.parse("1")
  end

  it "exposes $~ when doing Regex#===" do
    assert /o+/ === JSON.parse(%("foo"))
    assert $~[0] == "oo"
  end

  it "is enumerable" do
    nums = JSON.parse("[1, 2, 3]")
    nums.each_with_index do |x, i|
      assert x.is_a?(JSON::Any)
      assert x.raw == i + 1
    end
  end
end
