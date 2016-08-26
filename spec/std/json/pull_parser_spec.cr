require "spec"
require "json"

class JSON::PullParser
  def check(event_kind : Symbol)
    assert kind == event_kind
    read_next
  end

  def check(value : Nil)
    assert kind == :null
    read_next
  end

  def check(value : Int)
    assert kind == :int
    assert int_value == value
    read_next
  end

  def check(value : Float)
    assert kind == :float
    assert float_value == value
    read_next
  end

  def check(value : Bool)
    assert kind == :bool
    assert bool_value == value
    read_next
  end

  def check(value : String)
    assert kind == :string
    assert string_value == value
    read_next
  end

  def check(value : String)
    assert kind == :string
    assert string_value == value
    read_next
    yield
  end

  def check(array : Array)
    check_array do
      array.each do |x|
        check x
      end
    end
  end

  def check(hash : Hash)
    check_object do
      hash.each do |key, value|
        check(key.as(String)) do
          check value
        end
      end
    end
  end

  def check_array
    assert kind == :begin_array
    read_next
    yield
    assert kind == :end_array
    read_next
  end

  def check_array
    check_array { }
  end

  def check_object
    assert kind == :begin_object
    read_next
    yield
    assert kind == :end_object
    read_next
  end

  def check_object
    check_object { }
  end

  def check_error
    expect_raises JSON::ParseException do
      read_next
    end
  end
end

private def check_pull_parse(string)
  it "parses #{string}" do
    parser = JSON::PullParser.new string
    parser.check JSON.parse(string).raw
    assert parser.kind == :EOF
  end
end

private def check_pull_parse_error(string)
  it "errors on #{string}" do
    expect_raises JSON::ParseException do
      parser = JSON::PullParser.new string
      while parser.kind != :EOF
        parser.read_next
      end
    end
  end
end

private def check_raw(string, file = __FILE__, line = __LINE__)
  it "parses raw #{string.inspect}", file, line do
    pull = JSON::PullParser.new(string)
    assert pull.read_raw == string
  end
end

describe JSON::PullParser do
  check_pull_parse "null"
  check_pull_parse "false"
  check_pull_parse "true"
  check_pull_parse "1"
  check_pull_parse "1.5"
  check_pull_parse %("hello")
  check_pull_parse "[]"
  check_pull_parse "[[]]"
  check_pull_parse "[1]"
  check_pull_parse "[1.5]"
  check_pull_parse "[null]"
  check_pull_parse "[true]"
  check_pull_parse "[false]"
  check_pull_parse %(["hello"])
  check_pull_parse "[1, 2]"
  check_pull_parse "{}"
  check_pull_parse %({"foo": 1})
  check_pull_parse %({"foo": "bar"})
  check_pull_parse %({"foo": [1, 2]})
  check_pull_parse %({"foo": 1, "bar": 2})
  check_pull_parse %({"foo": "foo1", "bar": "bar1"})

  check_pull_parse_error "[null 2]"
  check_pull_parse_error "[false 2]"
  check_pull_parse_error "[true 2]"
  check_pull_parse_error "[1 2]"
  check_pull_parse_error "[1.5 2]"
  check_pull_parse_error %(["hello" 2])
  check_pull_parse_error "[,1]"
  check_pull_parse_error "[}]"
  check_pull_parse_error "["
  check_pull_parse_error %({,"foo": 1})
  check_pull_parse_error "[]]"
  check_pull_parse_error "{}}"
  check_pull_parse_error %({"foo",1})
  check_pull_parse_error %({"foo"::1})
  check_pull_parse_error %(["foo":1])
  check_pull_parse_error %({"foo": []:1})
  check_pull_parse_error "[[]"
  check_pull_parse_error %({"foo": {})
  check_pull_parse_error %({"name": "John", "age", 1})
  check_pull_parse_error %({"name": "John", "age": "foo", "bar"})

  describe "skip" do
    [
      {"null", "null"},
      {"bool", "false"},
      {"int", "3"},
      {"float", "3.5"},
      {"string", %("hello")},
      {"array", %([10, 20, [30], [40]])},
      {"object", %({"foo": [1, 2], "bar": {"baz": [3]}})},
    ].each do |(desc, obj)|
      it "skips #{desc}" do
        pull = JSON::PullParser.new("[1, #{obj}, 2]")
        pull.read_array do
          assert pull.read_int == 1
          pull.skip
          assert pull.read_int == 2
        end
      end
    end
  end

  it "reads bool or null" do
    assert JSON::PullParser.new("null").read_bool_or_null.nil?
    assert JSON::PullParser.new("false").read_bool_or_null == false
  end

  it "reads int or null" do
    assert JSON::PullParser.new("null").read_int_or_null.nil?
    assert JSON::PullParser.new("1").read_int_or_null == 1
  end

  it "reads float or null" do
    assert JSON::PullParser.new("null").read_float_or_null.nil?
    assert JSON::PullParser.new("1.5").read_float_or_null == 1.5
  end

  it "reads string or null" do
    assert JSON::PullParser.new("null").read_string_or_null.nil?
    assert JSON::PullParser.new(%("hello")).read_string_or_null == "hello"
  end

  it "reads array or null" do
    JSON::PullParser.new("null").read_array_or_null { fail "expected block not to be called" }

    pull = JSON::PullParser.new(%([1]))
    pull.read_array_or_null do
      assert pull.read_int == 1
    end
  end

  it "reads object or null" do
    JSON::PullParser.new("null").read_object_or_null { fail "expected block not to be called" }

    pull = JSON::PullParser.new(%({"foo": 1}))
    pull.read_object_or_null do |key|
      assert key == "foo"
      assert pull.read_int == 1
    end
  end

  describe "on key" do
    it "finds key" do
      pull = JSON::PullParser.new(%({"foo": 1, "bar": 2}))

      bar = nil
      pull.on_key("bar") do
        bar = pull.read_int
      end

      assert bar == 2
    end

    it "finds key" do
      pull = JSON::PullParser.new(%({"foo": 1, "bar": 2}))

      bar = nil
      pull.on_key("bar") do
        bar = pull.read_int
      end

      assert bar == 2
    end

    it "doesn't find key" do
      pull = JSON::PullParser.new(%({"foo": 1, "baz": 2}))

      bar = nil
      pull.on_key("bar") do
        bar = pull.read_int
      end

      assert bar.nil?
    end

    it "finds key with bang" do
      pull = JSON::PullParser.new(%({"foo": 1, "bar": 2}))

      bar = nil
      pull.on_key!("bar") do
        bar = pull.read_int
      end

      assert bar == 2
    end

    it "doesn't find key with bang" do
      pull = JSON::PullParser.new(%({"foo": 1, "baz": 2}))

      expect_raises Exception, "json key not found: bar" do
        pull.on_key!("bar") do
        end
      end
    end

    it "reads float when it is an int" do
      pull = JSON::PullParser.new(%(1))
      f = pull.read_float
      assert f.is_a?(Float64)
      assert f == 1.0
    end

    ["1", "[1]", %({"x": [1]})].each do |value|
      it "yields all keys when skipping #{value}" do
        pull = JSON::PullParser.new(%({"foo": #{value}, "bar": 2}))
        pull.read_object do |key|
          assert key != ""
          pull.skip
        end
      end
    end
  end

  describe "raw" do
    check_raw "null"
    check_raw "true"
    check_raw "false"
    check_raw "1234"
    check_raw "1234.5678"
    check_raw %("hello")
    check_raw %([1,"hello",true,false,null,[1,2,3]])
    check_raw %({"foo":[1,2,{"bar":[1,"hello",true,false,1.5]}]})
    check_raw %({"foo":"bar"})
  end
end
