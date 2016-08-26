require "spec"
require "yaml"

class YAMLPerson
  YAML.mapping({
    name: String,
    age:  {type: Int32, nilable: true},
  })

  def_equals name, age

  def initialize(@name : String)
  end
end

class StrictYAMLPerson
  YAML.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  }, true)
end

class YAMLWithBool
  YAML.mapping value: Bool
end

class YAMLWithTime
  YAML.mapping({
    value: {type: Time, converter: Time::Format.new("%F %T")},
  })
end

class YAMLWithKey
  YAML.mapping({
    key:   String,
    value: Int32,
    pull:  Int32,
  })
end

class YAMLWithDefaults
  YAML.mapping({
    a: {type: Int32, default: 11},
    b: {type: String, default: "Haha"},
    c: {type: Bool, default: true},
    d: {type: Bool, default: false},
    e: {type: Bool, nilable: true, default: false},
    f: {type: Int32, nilable: true, default: 1},
    g: {type: Int32, nilable: true, default: nil},
    h: {type: Array(Int32), default: [1, 2, 3]},
    i: String?,
  })
end

class YAMLWithAny
  YAML.mapping({
    obj: YAML::Any,
  })

  def initialize(@obj)
  end
end

class YAMLWithSmallIntegers
  YAML.mapping({
    foo: Int16,
    bar: Int8,
  })
end

class YAMLWithTimeEpoch
  YAML.mapping({
    value: {type: Time, converter: Time::EpochConverter},
  })
end

class YAMLWithTimeEpochMillis
  YAML.mapping({
    value: {type: Time, converter: Time::EpochMillisConverter},
  })
end

describe "YAML mapping" do
  it "parses person" do
    person = YAMLPerson.from_yaml("---\nname: John\nage: 30\n")
    assert person.is_a?(YAMLPerson)
    assert person.name == "John"
    assert person.age == 30
  end

  it "parses person without age" do
    person = YAMLPerson.from_yaml("---\nname: John\n")
    assert person.is_a?(YAMLPerson)
    assert person.name == "John"
    assert person.name.size == 4 # This verifies that name is not nilable
    assert person.age.nil?
  end

  it "parses person with blank age" do
    person = YAMLPerson.from_yaml("---\nname: John\nage:\n")
    assert person.is_a?(YAMLPerson)
    assert person.name == "John"
    assert person.name.size == 4 # This verifies that name is not nilable
    assert person.age.nil?
  end

  it "parses array of people" do
    people = Array(YAMLPerson).from_yaml("---\n- name: John\n- name: Doe\n")
    assert people.size == 2
    assert people[0].name == "John"
    assert people[1].name == "Doe"
  end

  it "parses person with unknown attributes" do
    person = YAMLPerson.from_yaml("---\nname: John\nunknown: [1, 2, 3]\nage: 30\n")
    assert person.is_a?(YAMLPerson)
    assert person.name == "John"
    assert person.age == 30
  end

  it "parses strict person with unknown attributes" do
    expect_raises YAML::ParseException, "unknown yaml attribute: foo" do
      StrictYAMLPerson.from_yaml("---\nname: John\nfoo: [1, 2, 3]\nage: 30\n")
    end
  end

  it "raises if non-nilable attribute is nil" do
    expect_raises YAML::ParseException, "missing yaml attribute: name" do
      YAMLPerson.from_yaml("---\nage: 30\n")
    end
  end

  it "doesn't raises on false value when not-nil" do
    yaml = YAMLWithBool.from_yaml("---\nvalue: false\n")
    assert yaml.value == false
  end

  it "parses yaml with Time::Format converter" do
    yaml = YAMLWithTime.from_yaml("---\nvalue: 2014-10-31 23:37:16\n")
    assert yaml.value == Time.new(2014, 10, 31, 23, 37, 16)
  end

  it "parses YAML with mapping key named 'key'" do
    yaml = YAMLWithKey.from_yaml("---\nkey: foo\nvalue: 1\npull: 2")
    assert yaml.key == "foo"
    assert yaml.value == 1
    assert yaml.pull == 2
  end

  it "allows small types of integer" do
    yaml = YAMLWithSmallIntegers.from_yaml(%({"foo": 21, "bar": 7}))

    assert yaml.foo == 21
    assert typeof(yaml.foo) == Int16

    assert yaml.bar == 7
    assert typeof(yaml.bar) == Int8
  end

  describe "parses YAML with defaults" do
    it "mixed" do
      json = YAMLWithDefaults.from_yaml(%({"a":1,"b":"bla"}))
      assert json.a == 1
      assert json.b == "bla"

      json = YAMLWithDefaults.from_yaml(%({"a":1}))
      assert json.a == 1
      assert json.b == "Haha"

      json = YAMLWithDefaults.from_yaml(%({"b":"bla"}))
      assert json.a == 11
      assert json.b == "bla"

      json = YAMLWithDefaults.from_yaml(%({}))
      assert json.a == 11
      assert json.b == "Haha"

      # There's no "null" in YAML? Maybe we should support this eventually
      # json = YAMLWithDefaults.from_yaml(%({"a":null,"b":null}))
      # json.a.should eq 11
      # json.b.should eq "Haha"
    end

    it "bool" do
      json = YAMLWithDefaults.from_yaml(%({}))
      assert json.c == true
      assert typeof(json.c) == Bool
      assert json.d == false
      assert typeof(json.d) == Bool

      json = YAMLWithDefaults.from_yaml(%({"c":false}))
      assert json.c == false
      json = YAMLWithDefaults.from_yaml(%({"c":true}))
      assert json.c == true

      json = YAMLWithDefaults.from_yaml(%({"d":false}))
      assert json.d == false
      json = YAMLWithDefaults.from_yaml(%({"d":true}))
      assert json.d == true
    end

    it "with nilable" do
      json = YAMLWithDefaults.from_yaml(%({}))

      assert json.e == false
      assert typeof(json.e) == Bool | Nil

      assert json.f == 1
      assert typeof(json.f) == Int32 | Nil

      assert json.g == nil
      assert typeof(json.g) == Int32 | Nil

      json = YAMLWithDefaults.from_yaml(%({"e":false}))
      assert json.e == false
      json = YAMLWithDefaults.from_yaml(%({"e":true}))
      assert json.e == true

      json = YAMLWithDefaults.from_yaml(%({}))
      assert json.i.nil?

      json = YAMLWithDefaults.from_yaml(%({"i":"bla"}))
      assert json.i == "bla"
    end

    it "create new array every time" do
      json = YAMLWithDefaults.from_yaml(%({}))
      assert json.h == [1, 2, 3]
      json.h << 4
      assert json.h == [1, 2, 3, 4]

      json = YAMLWithDefaults.from_yaml(%({}))
      assert json.h == [1, 2, 3]
    end
  end

  it "parses YAML with any" do
    yaml = YAMLWithAny.from_yaml("obj: hello")
    assert yaml.obj.as_s == "hello"

    yaml = YAMLWithAny.from_yaml({:obj => %w(foo bar)}.to_yaml)
    assert yaml.obj[1].as_s == "bar"

    yaml = YAMLWithAny.from_yaml({:obj => {:foo => :bar}}.to_yaml)
    assert yaml.obj["foo"].as_s == "bar"
  end

  it "uses Time::EpochConverter" do
    string = %({"value":1459859781})
    yaml = YAMLWithTimeEpoch.from_yaml(string)
    assert yaml.value.is_a?(Time)
    assert yaml.value == Time.epoch(1459859781)
  end

  it "uses Time::EpochMillisConverter" do
    string = %({"value":1459860483856})
    yaml = YAMLWithTimeEpochMillis.from_yaml(string)
    assert yaml.value.is_a?(Time)
    assert yaml.value == Time.epoch_ms(1459860483856)
  end
end
