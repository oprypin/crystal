require "spec"
require "json"
require "big"
require "big/json"

enum JSONSpecEnum
  Zero
  One
  Two
end

describe "JSON serialization" do
  describe "from_json" do
    it "does Array(Nil)#from_json" do
      assert Array(Nil).from_json("[null, null]") == [nil, nil]
    end

    it "does Array(Bool)#from_json" do
      assert Array(Bool).from_json("[true, false]") == [true, false]
    end

    it "does Array(Int32)#from_json" do
      assert Array(Int32).from_json("[1, 2, 3]") == [1, 2, 3]
    end

    it "does Array(Int64)#from_json" do
      assert Array(Int64).from_json("[1, 2, 3]") == [1, 2, 3]
    end

    it "does Array(Float32)#from_json" do
      assert Array(Float32).from_json("[1.5, 2, 3.5]") == [1.5, 2.0, 3.5]
    end

    it "does Array(Float64)#from_json" do
      assert Array(Float64).from_json("[1.5, 2, 3.5]") == [1.5, 2, 3.5]
    end

    it "does Hash(String, String)#from_json" do
      assert Hash(String, String).from_json(%({"foo": "x", "bar": "y"})) == {"foo" => "x", "bar" => "y"}
    end

    it "does Hash(String, Int32)#from_json" do
      assert Hash(String, Int32).from_json(%({"foo": 1, "bar": 2})) == {"foo" => 1, "bar" => 2}
    end

    it "does Hash(String, Int32)#from_json and skips null" do
      assert Hash(String, Int32).from_json(%({"foo": 1, "bar": 2, "baz": null})) == {"foo" => 1, "bar" => 2}
    end

    it "does for Array(Int32) from IO" do
      io = MemoryIO.new "[1, 2, 3]"
      assert Array(Int32).from_json(io) == [1, 2, 3]
    end

    it "does for Array(Int32) with block" do
      elements = [] of Int32
      ret = Array(Int32).from_json("[1, 2, 3]") do |element|
        elements << element
      end
      assert ret.nil?
      assert elements == [1, 2, 3]
    end

    it "does for tuple" do
      tuple = Tuple(Int32, String).from_json(%([1, "hello"]))
      assert tuple == {1, "hello"}
      assert tuple.is_a?(Tuple(Int32, String))
    end

    it "does for named tuple" do
      tuple = NamedTuple(x: Int32, y: String).from_json(%({"y": "hello", "x": 1}))
      assert tuple == {x: 1, y: "hello"}
      assert tuple.is_a?(NamedTuple(x: Int32, y: String))
    end

    it "does for BigInt" do
      big = BigInt.from_json("123456789123456789123456789123456789123456789")
      assert big.is_a?(BigInt)
      assert big == BigInt.new("123456789123456789123456789123456789123456789")
    end

    it "does for BigFloat" do
      big = BigFloat.from_json("1234.567891011121314")
      assert big.is_a?(BigFloat)
      assert big == BigFloat.new("1234.567891011121314")
    end

    it "does for BigFloat from int" do
      big = BigFloat.from_json("1234")
      assert big.is_a?(BigFloat)
      assert big == BigFloat.new("1234")
    end

    it "does for Enum with number" do
      assert JSONSpecEnum.from_json("1") == JSONSpecEnum::One

      expect_raises do
        JSONSpecEnum.from_json("3")
      end
    end

    it "does for Enum with string" do
      assert JSONSpecEnum.from_json(%("One")) == JSONSpecEnum::One

      expect_raises do
        JSONSpecEnum.from_json(%("Three"))
      end
    end

    it "deserializes with root" do
      assert Int32.from_json(%({"foo": 1}), root: "foo") == 1
      assert Array(Int32).from_json(%({"foo": [1, 2]}), root: "foo") == [1, 2]
    end

    it "deserializes union" do
      assert Array(Int32 | String).from_json(%([1, "hello"])) == [1, "hello"]
    end

    it "deserializes union with bool (fast path)" do
      assert Union(Bool, Array(Int32)).from_json(%(true)) == true
    end

    {% for type in %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64).map(&.id) %}
        it "deserializes union with {{type}} (fast path)" do
          Union({{type}}, Array(Int32)).from_json(%(#{ {{type}}::MAX })).should eq({{type}}::MAX)
        end
      {% end %}

    it "deserializes union with Float32 (fast path)" do
      assert Union(Float32, Array(Int32)).from_json(%(1)) == 1
      assert Union(Float32, Array(Int32)).from_json(%(1.23)) == 1.23_f32
    end

    it "deserializes union with Float64 (fast path)" do
      assert Union(Float64, Array(Int32)).from_json(%(1)) == 1
      assert Union(Float64, Array(Int32)).from_json(%(1.23)) == 1.23
    end
  end

  describe "to_json" do
    it "does for Nil" do
      assert nil.to_json == "null"
    end

    it "does for Bool" do
      assert true.to_json == "true"
    end

    it "does for Int32" do
      assert 1.to_json == "1"
    end

    it "does for Float64" do
      assert 1.5.to_json == "1.5"
    end

    it "does for String" do
      assert "hello".to_json == "\"hello\""
    end

    it "does for String with quote" do
      assert "hel\"lo".to_json == "\"hel\\\"lo\""
    end

    it "does for String with slash" do
      assert "hel\\lo".to_json == "\"hel\\\\lo\""
    end

    it "does for String with control codes" do
      assert "\b".to_json == "\"\\b\""
      assert "\f".to_json == "\"\\f\""
      assert "\n".to_json == "\"\\n\""
      assert "\r".to_json == "\"\\r\""
      assert "\t".to_json == "\"\\t\""
      assert "\u{19}".to_json == "\"\\u0019\""
    end

    it "does for Array" do
      assert [1, 2, 3].to_json == "[1,2,3]"
    end

    it "does for Set" do
      assert Set(Int32).new([1, 1, 2]).to_json == "[1,2]"
    end

    it "does for Hash" do
      assert {"foo" => 1, "bar" => 2}.to_json == %({"foo":1,"bar":2})
    end

    it "does for Hash with non-string keys" do
      assert {:foo => 1, :bar => 2}.to_json == %({"foo":1,"bar":2})
    end

    it "does for Hash with newlines" do
      assert {"foo\nbar" => "baz\nqux"}.to_json == %({"foo\\nbar":"baz\\nqux"})
    end

    it "does for Tuple" do
      assert {1, "hello"}.to_json == %([1,"hello"])
    end

    it "does for NamedTuple" do
      assert {x: 1, y: "hello"}.to_json == %({"x":1,"y":"hello"})
    end

    it "does for Enum" do
      assert JSONSpecEnum::One.to_json == "1"
    end

    it "does for BigInt" do
      big = BigInt.new("123456789123456789123456789123456789123456789")
      assert big.to_json == "123456789123456789123456789123456789123456789"
    end

    it "does for BigFloat" do
      big = BigFloat.new("1234.567891011121314")
      assert big.to_json == "1234.567891011121314"
    end
  end

  describe "to_pretty_json" do
    it "does for Nil" do
      assert nil.to_pretty_json == "null"
    end

    it "does for Bool" do
      assert true.to_pretty_json == "true"
    end

    it "does for Int32" do
      assert 1.to_pretty_json == "1"
    end

    it "does for Float64" do
      assert 1.5.to_pretty_json == "1.5"
    end

    it "does for String" do
      assert "hello".to_pretty_json == "\"hello\""
    end

    it "does for Array" do
      assert [1, 2, 3].to_pretty_json == "[\n  1,\n  2,\n  3\n]"
    end

    it "does for nested Array" do
      assert [[1, 2, 3]].to_pretty_json == "[\n  [\n    1,\n    2,\n    3\n  ]\n]"
    end

    it "does for empty Array" do
      assert ([] of Nil).to_pretty_json == "[]"
    end

    it "does for Hash" do
      assert {"foo" => 1, "bar" => 2}.to_pretty_json == %({\n  "foo": 1,\n  "bar": 2\n})
    end

    it "does for nested Hash" do
      assert {"foo" => {"bar" => 1}}.to_pretty_json == %({\n  "foo": {\n    "bar": 1\n  }\n})
    end

    it "does for empty Hash" do
      assert ({} of Nil => Nil).to_pretty_json == %({})
    end

    it "does for Array with indent" do
      assert [1, 2, 3].to_pretty_json(indent: " ") == "[\n 1,\n 2,\n 3\n]"
    end

    it "does for nested Hash with indent" do
      assert {"foo" => {"bar" => 1}}.to_pretty_json(indent: " ") == %({\n "foo": {\n  "bar": 1\n }\n})
    end
  end

  it "generates an array with JSON::Builder" do
    result = String.build do |io|
      io.json_array do |array|
        array.push 1
        array.push do
          io.json_array do |array2|
            array2 << 2
            array2 << 3
          end
        end
      end
    end
    assert result == "[1,[2,3]]"
  end
end
