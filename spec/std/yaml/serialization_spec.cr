require "spec"
require "yaml"
require "big"
require "big/yaml"

enum YAMLSpecEnum
  Zero
  One
  Two
end

describe "YAML serialization" do
  describe "from_yaml" do
    it "does Nil#from_yaml" do
      assert Nil.from_yaml("--- \n...\n").nil?
    end

    it "does Bool#from_yaml" do
      assert Bool.from_yaml("true") == true
      assert Bool.from_yaml("false") == false
    end

    it "does Int32#from_yaml" do
      assert Int32.from_yaml("123") == 123
    end

    it "does Int64#from_yaml" do
      assert Int64.from_yaml("123456789123456789") == 123456789123456789
    end

    it "does String#from_yaml" do
      assert String.from_yaml("hello") == "hello"
    end

    it "does Float32#from_yaml" do
      assert Float32.from_yaml("1.5") == 1.5
    end

    it "does Float64#from_yaml" do
      value = Float64.from_yaml("1.5")
      assert value == 1.5
      assert value.is_a?(Float64)
    end

    it "does Array#from_yaml" do
      assert Array(Int32).from_yaml("---\n- 1\n- 2\n- 3\n") == [1, 2, 3]
    end

    it "does Array#from_yaml with block" do
      elements = [] of Int32
      Array(Int32).from_yaml("---\n- 1\n- 2\n- 3\n") do |element|
        elements << element
      end
      assert elements == [1, 2, 3]
    end

    it "does Hash#from_yaml" do
      assert Hash(Int32, Bool).from_yaml("---\n1: true\n2: false\n") == {1 => true, 2 => false}
    end

    it "does Tuple#from_yaml" do
      assert Tuple(Int32, String, Bool).from_yaml("---\n- 1\n- foo\n- true\n") == {1, "foo", true}
    end

    it "does for named tuple" do
      tuple = NamedTuple(x: Int32, y: String).from_yaml(%({"y": "hello", "x": 1}))
      assert tuple == {x: 1, y: "hello"}
      assert tuple.is_a?(NamedTuple(x: Int32, y: String))
    end

    it "does for BigInt" do
      big = BigInt.from_yaml("123456789123456789123456789123456789123456789")
      assert big.is_a?(BigInt)
      assert big == BigInt.new("123456789123456789123456789123456789123456789")
    end

    it "does for BigFloat" do
      big = BigFloat.from_yaml("1234.567891011121314")
      assert big.is_a?(BigFloat)
      assert big == BigFloat.new("1234.567891011121314")
    end

    it "does for Enum with number" do
      assert YAMLSpecEnum.from_yaml(%("1")) == YAMLSpecEnum::One

      expect_raises do
        YAMLSpecEnum.from_yaml(%("3"))
      end
    end

    it "does for Enum with string" do
      assert YAMLSpecEnum.from_yaml(%("One")) == YAMLSpecEnum::One

      expect_raises do
        YAMLSpecEnum.from_yaml(%("Three"))
      end
    end

    it "does Time::Format#from_yaml" do
      pull = YAML::PullParser.new("--- 2014-01-02\n...\n")
      pull.read_stream do
        pull.read_document do
          assert Time::Format.new("%F").from_yaml(pull) == Time.new(2014, 1, 2)
        end
      end
    end

    it "deserializes union" do
      assert Array(Int32 | String).from_yaml(%([1, "hello"])) == [1, "hello"]
    end
  end

  describe "to_yaml" do
    it "does for Nil" do
      assert Nil.from_yaml(nil.to_yaml) == nil
    end

    it "does for Bool" do
      assert Bool.from_yaml(true.to_yaml) == true
      assert Bool.from_yaml(false.to_yaml) == false
    end

    it "does for Int32" do
      assert Int32.from_yaml(1.to_yaml) == 1
    end

    it "does for Float64" do
      assert Float64.from_yaml(1.5.to_yaml) == 1.5
    end

    it "does for String" do
      assert String.from_yaml("hello".to_yaml) == "hello"
    end

    it "does for String with quote" do
      assert String.from_yaml("hel\"lo".to_yaml) == "hel\"lo"
    end

    it "does for String with slash" do
      assert String.from_yaml("hel\\lo".to_yaml) == "hel\\lo"
    end

    it "does for Array" do
      assert Array(Int32).from_yaml([1, 2, 3].to_yaml) == [1, 2, 3]
    end

    it "does for Set" do
      assert Array(Int32).from_yaml(Set(Int32).new([1, 1, 2]).to_yaml) == [1, 2]
    end

    it "does for Hash" do
      assert Hash(String, Int32).from_yaml({"foo" => 1, "bar" => 2}.to_yaml) == {"foo" => 1, "bar" => 2}
    end

    it "does for Hash with symbol keys" do
      assert Hash(String, Int32).from_yaml({:foo => 1, :bar => 2}.to_yaml) == {"foo" => 1, "bar" => 2}
    end

    it "does for Tuple" do
      assert Tuple(Int32, String).from_yaml({1, "hello"}.to_yaml) == {1, "hello"}
    end

    it "does for NamedTuple" do
      assert {x: 1, y: "hello"}.to_yaml == {:x => 1, :y => "hello"}.to_yaml
    end

    it "does for BigInt" do
      big = BigInt.new("123456789123456789123456789123456789123456789")
      assert BigInt.from_yaml(big.to_yaml) == big
    end

    it "does for BigFloat" do
      big = BigFloat.new("1234.567891011121314")
      assert BigFloat.from_yaml(big.to_yaml) == big
    end

    it "does for Enum" do
      assert YAMLSpecEnum.from_yaml(YAMLSpecEnum::One.to_yaml) == YAMLSpecEnum::One
    end

    it "does a full document" do
      data = {
        :hello   => "World",
        :integer => 2,
        :float   => 3.5,
        :hash    => {
          :a => 1,
          :b => 2,
        },
        :array => [1, 2, 3],
        :null  => nil,
      }

      expected = "--- \nhello: World\ninteger: 2\nfloat: 3.5\nhash: \n  a: 1\n  b: 2\narray: \n  - 1\n  - 2\n  - 3\nnull: "

      assert data.to_yaml == expected
    end

    it "writes to a stream" do
      string = String.build do |str|
        %w(a b c).to_yaml(str)
      end
      assert string == "--- \n- a\n- b\n- c"
    end
  end
end
