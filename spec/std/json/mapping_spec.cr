require "spec"
require "json"

class JSONPerson
  JSON.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  })

  def_equals name, age

  def initialize(@name : String)
  end
end

class StrictJSONPerson
  JSON.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  }, true)
end

class JSONPersonEmittingNull
  JSON.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true, emit_null: true},
  })
end

class JSONWithBool
  JSON.mapping value: Bool
end

class JSONWithTime
  JSON.mapping({
    value: {type: Time, converter: Time::Format.new("%F %T")},
  })
end

class JSONWithNilableTime
  JSON.mapping({
    value: {type: Time, nilable: true, converter: Time::Format.new("%F")},
  })

  def initialize
  end
end

class JSONWithNilableTimeEmittingNull
  JSON.mapping({
    value: {type: Time, nilable: true, converter: Time::Format.new("%F"), emit_null: true},
  })

  def initialize
  end
end

class JSONWithSimpleMapping
  JSON.mapping({name: String, age: Int32})
end

class JSONWithKeywordsMapping
  JSON.mapping({end: Int32, abstract: Int32})
end

class JSONWithAny
  JSON.mapping({name: String, any: JSON::Any})
end

class JsonWithProblematicKeys
  JSON.mapping({
    key:  Int32,
    pull: Int32,
  })
end

class JsonWithSet
  JSON.mapping({set: Set(String)})
end

class JsonWithDefaults
  JSON.mapping({
    a: {type: Int32, default: 11},
    b: {type: String, default: "Haha"},
    c: {type: Bool, default: true},
    d: {type: Bool, default: false},
    e: {type: Bool, nilable: true, default: false},
    f: {type: Int32, nilable: true, default: 1},
    g: {type: Int32, nilable: true, default: nil},
    h: {type: Array(Int32), default: [1, 2, 3]},
  })
end

class JSONWithSmallIntegers
  JSON.mapping({
    foo: Int16,
    bar: Int8,
  })
end

class JSONWithTimeEpoch
  JSON.mapping({
    value: {type: Time, converter: Time::EpochConverter},
  })
end

class JSONWithTimeEpochMillis
  JSON.mapping({
    value: {type: Time, converter: Time::EpochMillisConverter},
  })
end

class JSONWithRaw
  JSON.mapping({
    value: {type: String, converter: String::RawConverter},
  })
end

class JSONWithRoot
  JSON.mapping({
    result: {type: Array(JSONPerson), root: "heroes"},
  })
end

class JSONWithNilableRoot
  JSON.mapping({
    result: {type: Array(JSONPerson), root: "heroes", nilable: true},
  })
end

class JSONWithNilableRootEmitNull
  JSON.mapping({
    result: {type: Array(JSONPerson), root: "heroes", nilable: true, emit_null: true},
  })
end

class JSONWithNilableUnion
  JSON.mapping({
    value: Int32 | Nil,
  })
end

class JSONWithNilableUnion2
  JSON.mapping({
    value: Int32?,
  })
end

describe "JSON mapping" do
  it "parses person" do
    person = JSONPerson.from_json(%({"name": "John", "age": 30}))
    assert person.is_a?(JSONPerson)
    assert person.name == "John"
    assert person.age == 30
  end

  it "parses person without age" do
    person = JSONPerson.from_json(%({"name": "John"}))
    assert person.is_a?(JSONPerson)
    assert person.name == "John"
    assert person.name.size == 4 # This verifies that name is not nilable
    assert person.age.nil?
  end

  it "parses array of people" do
    people = Array(JSONPerson).from_json(%([{"name": "John"}, {"name": "Doe"}]))
    assert people.size == 2
  end

  it "does to_json" do
    person = JSONPerson.from_json(%({"name": "John", "age": 30}))
    person2 = JSONPerson.from_json(person.to_json)
    assert person2 == person
  end

  it "parses person with unknown attributes" do
    person = JSONPerson.from_json(%({"name": "John", "age": 30, "foo": "bar"}))
    assert person.is_a?(JSONPerson)
    assert person.name == "John"
    assert person.age == 30
  end

  it "parses strict person with unknown attributes" do
    expect_raises JSON::ParseException, "unknown json attribute: foo" do
      StrictJSONPerson.from_json(%({"name": "John", "age": 30, "foo": "bar"}))
    end
  end

  it "raises if non-nilable attribute is nil" do
    expect_raises JSON::ParseException, "missing json attribute: name" do
      JSONPerson.from_json(%({"age": 30}))
    end
  end

  it "doesn't emit null by default when doing to_json" do
    person = JSONPerson.from_json(%({"name": "John"}))
    assert !(person.to_json =~ /age/)
  end

  it "emits null on request when doing to_json" do
    person = JSONPersonEmittingNull.from_json(%({"name": "John"}))
    assert person.to_json =~ /age/
  end

  it "doesn't raises on false value when not-nil" do
    json = JSONWithBool.from_json(%({"value": false}))
    assert json.value == false
  end

  it "parses json with Time::Format converter" do
    json = JSONWithTime.from_json(%({"value": "2014-10-31 23:37:16"}))
    assert json.value.is_a?(Time)
    assert json.value.to_s == "2014-10-31 23:37:16"
    assert json.to_json == %({"value":"2014-10-31 23:37:16"})
  end

  it "allows setting a nilable property to nil" do
    person = JSONPerson.new("John")
    person.age = 1
    person.age = nil
  end

  it "parses simple mapping" do
    person = JSONWithSimpleMapping.from_json(%({"name": "John", "age": 30}))
    assert person.is_a?(JSONWithSimpleMapping)
    assert person.name == "John"
    assert person.age == 30
  end

  it "outputs with converter when nilable" do
    json = JSONWithNilableTime.new
    assert json.to_json == "{}"
  end

  it "outputs with converter when nilable when emit_null is true" do
    json = JSONWithNilableTimeEmittingNull.new
    assert json.to_json == %({"value":null})
  end

  it "parses json with keywords" do
    json = JSONWithKeywordsMapping.from_json(%({"end": 1, "abstract": 2}))
    assert json.end == 1
    assert json.abstract == 2
  end

  it "parses json with any" do
    json = JSONWithAny.from_json(%({"name": "Hi", "any": [{"x": 1}, 2, "hey", true, false, 1.5, null]}))
    assert json.name == "Hi"
    assert json.any.raw == [{"x" => 1}, 2, "hey", true, false, 1.5, nil]
    assert json.to_json == %({"name":"Hi","any":[{"x":1},2,"hey",true,false,1.5,null]})
  end

  it "parses json with problematic keys" do
    json = JsonWithProblematicKeys.from_json(%({"key": 1, "pull": 2}))
    assert json.key == 1
    assert json.pull == 2
  end

  it "parses json array as set" do
    json = JsonWithSet.from_json(%({"set": ["a", "a", "b"]}))
    assert json.set == Set(String){"a", "b"}
  end

  it "allows small types of integer" do
    json = JSONWithSmallIntegers.from_json(%({"foo": 23, "bar": 7}))

    assert json.foo == 23
    assert typeof(json.foo) == Int16

    assert json.bar == 7
    assert typeof(json.bar) == Int8
  end

  describe "parses json with defaults" do
    it "mixed" do
      json = JsonWithDefaults.from_json(%({"a":1,"b":"bla"}))
      assert json.a == 1
      assert json.b == "bla"

      json = JsonWithDefaults.from_json(%({"a":1}))
      assert json.a == 1
      assert json.b == "Haha"

      json = JsonWithDefaults.from_json(%({"b":"bla"}))
      assert json.a == 11
      assert json.b == "bla"

      json = JsonWithDefaults.from_json(%({}))
      assert json.a == 11
      assert json.b == "Haha"

      json = JsonWithDefaults.from_json(%({"a":null,"b":null}))
      assert json.a == 11
      assert json.b == "Haha"
    end

    it "bool" do
      json = JsonWithDefaults.from_json(%({}))
      assert json.c == true
      assert typeof(json.c) == Bool
      assert json.d == false
      assert typeof(json.d) == Bool

      json = JsonWithDefaults.from_json(%({"c":false}))
      assert json.c == false
      json = JsonWithDefaults.from_json(%({"c":true}))
      assert json.c == true

      json = JsonWithDefaults.from_json(%({"d":false}))
      assert json.d == false
      json = JsonWithDefaults.from_json(%({"d":true}))
      assert json.d == true
    end

    it "with nilable" do
      json = JsonWithDefaults.from_json(%({}))

      assert json.e == false
      assert typeof(json.e) == Bool | Nil

      assert json.f == 1
      assert typeof(json.f) == Int32 | Nil

      assert json.g == nil
      assert typeof(json.g) == Int32 | Nil

      json = JsonWithDefaults.from_json(%({"e":false}))
      assert json.e == false
      json = JsonWithDefaults.from_json(%({"e":true}))
      assert json.e == true
    end

    it "create new array every time" do
      json = JsonWithDefaults.from_json(%({}))
      assert json.h == [1, 2, 3]
      json.h << 4
      assert json.h == [1, 2, 3, 4]

      json = JsonWithDefaults.from_json(%({}))
      assert json.h == [1, 2, 3]
    end
  end

  it "uses Time::EpochConverter" do
    string = %({"value":1459859781})
    json = JSONWithTimeEpoch.from_json(string)
    assert json.value.is_a?(Time)
    assert json.value == Time.epoch(1459859781)
    assert json.to_json == string
  end

  it "uses Time::EpochMillisConverter" do
    string = %({"value":1459860483856})
    json = JSONWithTimeEpochMillis.from_json(string)
    assert json.value.is_a?(Time)
    assert json.value == Time.epoch_ms(1459860483856)
    assert json.to_json == string
  end

  it "parses raw value from int" do
    string = %({"value":123456789123456789123456789123456789})
    json = JSONWithRaw.from_json(string)
    assert json.value == "123456789123456789123456789123456789"
    assert json.to_json == string
  end

  it "parses raw value from float" do
    string = %({"value":123456789123456789.123456789123456789})
    json = JSONWithRaw.from_json(string)
    assert json.value == "123456789123456789.123456789123456789"
    assert json.to_json == string
  end

  it "parses raw value from object" do
    string = %({"value":[null,true,false,{"x":[1,1.5]}]})
    json = JSONWithRaw.from_json(string)
    assert json.value == %([null,true,false,{"x":[1,1.5]}])
    assert json.to_json == string
  end

  it "parses with root" do
    json = %({"result":{"heroes":[{"name":"Batman"}]}})
    result = JSONWithRoot.from_json(json)
    assert result.result.is_a?(Array(JSONPerson))
    assert result.result.first.name == "Batman"
    assert result.to_json == json
  end

  it "parses with nilable root" do
    json = %({"result":null})
    result = JSONWithNilableRoot.from_json(json)
    assert result.result.nil?
    assert result.to_json == "{}"
  end

  it "parses with nilable root and emit null" do
    json = %({"result":null})
    result = JSONWithNilableRootEmitNull.from_json(json)
    assert result.result.nil?
    assert result.to_json == json
  end

  it "parses nilable union" do
    obj = JSONWithNilableUnion.from_json(%({"value": 1}))
    assert obj.value == 1
    assert obj.to_json == %({"value":1})

    obj = JSONWithNilableUnion.from_json(%({"value": null}))
    assert obj.value.nil?
    assert obj.to_json == %({})

    obj = JSONWithNilableUnion.from_json(%({}))
    assert obj.value.nil?
    assert obj.to_json == %({})
  end

  it "parses nilable union2" do
    obj = JSONWithNilableUnion2.from_json(%({"value": 1}))
    assert obj.value == 1
    assert obj.to_json == %({"value":1})

    obj = JSONWithNilableUnion2.from_json(%({"value": null}))
    assert obj.value.nil?
    assert obj.to_json == %({})

    obj = JSONWithNilableUnion2.from_json(%({}))
    assert obj.value.nil?
    assert obj.to_json == %({})
  end
end
