require "spec"
require "yaml"

describe YAML::Any do
  describe "casts" do
    it "gets nil" do
      assert YAML.parse("").as_nil.nil?
    end

    it "gets string" do
      assert YAML.parse("hello").as_s == "hello"
    end

    it "gets array" do
      assert YAML.parse("- foo\n- bar\n").as_a == ["foo", "bar"]
    end

    it "gets hash" do
      assert YAML.parse("foo: bar").as_h == {"foo" => "bar"}
    end
  end

  describe "#size" do
    it "of array" do
      assert YAML.parse("- foo\n- bar\n").size == 2
    end

    it "of hash" do
      assert YAML.parse("foo: bar").size == 1
    end
  end

  describe "#[]" do
    it "of array" do
      assert YAML.parse("- foo\n- bar\n")[1].raw == "bar"
    end

    it "of hash" do
      assert YAML.parse("foo: bar")["foo"].raw == "bar"
    end
  end

  describe "#[]?" do
    it "of array" do
      assert YAML.parse("- foo\n- bar\n")[1]?.not_nil!.raw == "bar"
      assert YAML.parse("- foo\n- bar\n")[3]?.nil?
    end

    it "of hash" do
      assert YAML.parse("foo: bar")["foo"]?.not_nil!.raw == "bar"
      assert YAML.parse("foo: bar")["fox"]?.nil?
    end
  end

  describe "each" do
    it "of array" do
      elems = [] of String
      YAML.parse("- foo\n- bar\n").each do |any|
        elems << any.as_s
      end
      assert elems == %w(foo bar)
    end

    it "of hash" do
      elems = [] of String
      YAML.parse("foo: bar").each do |key, value|
        elems << key.to_s << value.to_s
      end
      assert elems == %w(foo bar)
    end
  end

  it "traverses big structure" do
    obj = YAML.parse("--- \nfoo: \n  bar: \n    baz: \n      - qux\n      - fox")
    assert obj["foo"]["bar"]["baz"][1].as_s == "fox"
  end

  it "compares to other objects" do
    obj = YAML.parse("- foo\n- bar \n")
    assert obj == %w(foo bar)
    assert obj[0] == "foo"
  end

  it "returns array of any when doing parse all" do
    docs = YAML.parse_all("---\nfoo\n---\nbar\n")
    assert docs[0].as_s == "foo"
    assert docs[1].as_s == "bar"
  end

  it "can compare with ===" do
    assert "1" === YAML.parse("1")
  end

  it "exposes $~ when doing Regex#===" do
    assert /o+/ === YAML.parse(%("foo"))
    assert $~[0] == "oo"
  end

  it "is enumerable" do
    nums = YAML.parse("[1, 2, 3]")
    nums.each_with_index do |x, i|
      assert x.is_a?(YAML::Any)
      assert x.raw == (i + 1).to_s
    end
  end
end
