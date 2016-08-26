require "spec"

module ObjectSpec
  class StringWrapper
    delegate downcase, to: @string
    delegate upcase, capitalize, at, scan, to: @string

    @string : String

    def initialize(@string)
    end
  end

  class TestObject
    getter getter1
    getter getter2 : Int32
    getter getter3 : Int32 = 3
    getter getter4 = 4

    getter! getter5
    @getter5 : Int32?

    getter! getter6 : Int32

    getter? getter7
    getter? getter8 : Bool
    getter? getter9 : Bool = true
    getter? getter10 = true

    getter(getter11) { 11 }

    @@getter12_value = 12
    getter getter12 : Int32 { @@getter12_value }

    def self.getter12_value=(@@getter12_value)
    end

    setter setter1
    setter setter2 : Int32
    setter setter3 : Int32 = 3
    setter setter4 = 4

    property property1
    property property2 : Int32
    property property3 : Int32 = 3
    property property4 = 4

    property! property5
    @property5 : Int32?

    property! property6 : Int32

    property? property7
    property? property8 : Bool
    property? property9 : Bool = true
    property? property10 = true

    property(property11) { 11 }
    property property12 : Int32 { 10 + 2 }

    def initialize
      @getter1 = 1
      @getter2 = 2

      @getter7 = true
      @getter8 = true

      @setter1 = 1
      @setter2 = 2

      @property1 = 1
      @property2 = 2

      @property7 = true
      @property8 = true
    end

    def getter5=(@getter5)
    end

    def getter6=(@getter6)
    end

    def setter1
      @setter1
    end

    def setter2
      @setter2
    end

    def setter3
      @setter3
    end

    def setter4
      @setter4
    end
  end
end

describe Object do
  describe "delegate" do
    it "delegates" do
      wrapper = ObjectSpec::StringWrapper.new("HellO")
      assert wrapper.downcase == "hello"
      assert wrapper.upcase == "HELLO"
      assert wrapper.capitalize == "Hello"

      assert wrapper.at(0) == 'H'
      assert wrapper.at(index: 1) == 'e'

      assert wrapper.at(10) { 20 } == 20

      matches = [] of String
      wrapper.scan(/l/) do |match|
        matches << match[0]
      end
      assert matches == ["l", "l"]
    end
  end

  describe "getter" do
    it "uses simple getter" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter1 == 1
      assert typeof(obj.@getter1) == Int32
      assert typeof(obj.getter1) == Int32
    end

    it "uses getter with type declaration" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter2 == 2
      assert typeof(obj.@getter2) == Int32
      assert typeof(obj.getter2) == Int32
    end

    it "uses getter with type declaration and default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter3 == 3
      assert typeof(obj.@getter3) == Int32
      assert typeof(obj.getter3) == Int32
    end

    it "uses getter with assignment" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter4 == 4
      assert typeof(obj.@getter4) == Int32
      assert typeof(obj.getter4) == Int32
    end

    it "defines lazy getter with block" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter11 == 11
      assert obj.getter12 == 12
      ObjectSpec::TestObject.getter12_value = 24
      assert obj.getter12 == 12

      obj2 = ObjectSpec::TestObject.new
      assert obj2.getter12 == 24
    end
  end

  describe "getter!" do
    it "uses getter!" do
      obj = ObjectSpec::TestObject.new
      expect_raises do
        obj.getter5
      end
      obj.getter5 = 5
      assert obj.getter5 == 5
      assert typeof(obj.@getter5) == Int32 | Nil
      assert typeof(obj.getter5) == Int32
    end

    it "uses getter! with type declaration" do
      obj = ObjectSpec::TestObject.new
      expect_raises do
        obj.getter6
      end
      obj.getter6 = 6
      assert obj.getter6 == 6
      assert typeof(obj.@getter6) == Int32 | Nil
      assert typeof(obj.getter6) == Int32
    end
  end

  describe "getter?" do
    it "uses getter?" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter7? == true
      assert typeof(obj.@getter7) == Bool
      assert typeof(obj.getter7?) == Bool
    end

    it "uses getter? with type declaration" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter8? == true
      assert typeof(obj.@getter8) == Bool
      assert typeof(obj.getter8?) == Bool
    end

    it "uses getter? with type declaration and default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter9? == true
      assert typeof(obj.@getter9) == Bool
      assert typeof(obj.getter9?) == Bool
    end

    it "uses getter? with default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.getter10? == true
      assert typeof(obj.@getter10) == Bool
      assert typeof(obj.getter10?) == Bool
    end
  end

  describe "setter" do
    it "uses setter" do
      obj = ObjectSpec::TestObject.new
      assert obj.setter1 == 1
      obj.setter1 = 2
      assert obj.setter1 == 2
    end

    it "uses setter with type declaration" do
      obj = ObjectSpec::TestObject.new
      assert obj.setter2 == 2
      obj.setter2 = 3
      assert obj.setter2 == 3
    end

    it "uses setter with type declaration and default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.setter3 == 3
      obj.setter3 = 4
      assert obj.setter3 == 4
    end

    it "uses setter with default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.setter4 == 4
      obj.setter4 = 5
      assert obj.setter4 == 5
    end
  end

  describe "property" do
    it "uses property" do
      obj = ObjectSpec::TestObject.new
      assert obj.property1 == 1
      obj.property1 = 2
      assert obj.property1 == 2
    end

    it "uses property with type declaration" do
      obj = ObjectSpec::TestObject.new
      assert obj.property2 == 2
      obj.property2 = 3
      assert obj.property2 == 3
    end

    it "uses property with type declaration and default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.property3 == 3
      obj.property3 = 4
      assert obj.property3 == 4
    end

    it "uses property with default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.property4 == 4
      obj.property4 = 5
      assert obj.property4 == 5
    end

    it "defines lazy property with block" do
      obj = ObjectSpec::TestObject.new
      assert obj.property11 == 11
      obj.property11 = 12
      assert obj.property11 == 12

      assert obj.property12 == 12
      obj.property12 = 13
      assert obj.property12 == 13
    end
  end

  describe "property!" do
    it "uses property!" do
      obj = ObjectSpec::TestObject.new
      expect_raises do
        obj.property5
      end
      obj.property5 = 5
      assert obj.property5 == 5
    end

    it "uses property! with type declaration" do
      obj = ObjectSpec::TestObject.new
      expect_raises do
        obj.property6
      end
      obj.property6 = 6
      assert obj.property6 == 6
    end
  end

  describe "property?" do
    it "uses property?" do
      obj = ObjectSpec::TestObject.new
      assert obj.property7? == true
      obj.property7 = false
      assert obj.property7? == false
    end

    it "uses property? with type declaration" do
      obj = ObjectSpec::TestObject.new
      assert obj.property8? == true
      obj.property8 = false
      assert obj.property8? == false
    end

    it "uses property? with type declaration and default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.property9? == true
      obj.property9 = false
      assert obj.property9? == false
    end

    it "uses property? with default value" do
      obj = ObjectSpec::TestObject.new
      assert obj.property10? == true
      obj.property10 = false
      assert obj.property10? == false
    end
  end
end
