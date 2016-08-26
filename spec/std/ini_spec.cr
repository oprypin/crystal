require "spec"
require "ini"

describe "INI" do
  describe "parse from string" do
    it "parses key = value" do
      assert INI.parse("key = value") == {"" => {"key" => "value"}}
    end

    it "ignores whitespaces" do
      assert INI.parse("   key   =   value  ") == {"" => {"key" => "value"}}
    end

    it "parses sections" do
      assert INI.parse("[section]\na = 1") == {"section" => {"a" => "1"}}
    end

    it "empty section" do
      assert INI.parse("[section]") == {"section" => {} of String => String}
    end

    it "parse file" do
      assert INI.parse(File.read "#{__DIR__}/data/test_file.ini") == {
        "general" => {
          "log_level" => "DEBUG",
        },
        "section1" => {
          "foo" => "1",
          "bar" => "2",
        },
        "section2" => {
          "x.y.z" => "coco lala",
        },
      }
    end
  end
end
