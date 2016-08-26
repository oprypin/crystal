require "spec"
require "string_scanner"

describe StringScanner, "#scan" do
  it "returns the string matched and advances the offset" do
    s = StringScanner.new("this is a string")
    assert s.scan(/\w+\s/) == "this "
    assert s.scan(/\w+\s/) == "is "
    assert s.scan(/\w+\s/) == "a "
    assert s.scan(/\w+/) == "string"
  end

  it "returns nil if it can't match from the offset" do
    s = StringScanner.new("test string")
    assert s.scan(/\w+/) # => "test"
    assert s.scan(/\w+/).nil?
    assert s.scan(/\s\w+/) # => " string"
    assert s.scan(/.*/)    # => ""
  end
end

describe StringScanner, "#scan_until" do
  it "returns the string matched and advances the offset" do
    s = StringScanner.new("test string")
    assert s.scan_until(/tr/) == "test str"
    assert s.offset == 8
    assert s.scan_until(/g/) == "ing"
  end

  it "returns nil if it can't match from the offset" do
    s = StringScanner.new("test string")
    s.offset = 8
    assert s.scan_until(/tr/).nil?
  end
end

describe StringScanner, "#skip" do
  it "advances the offset but does not returns the string matched" do
    s = StringScanner.new("this is a string")

    assert s.skip(/\w+\s/) == 5
    assert s.offset == 5
    assert s[0]?

    assert s.skip(/\d+/) == nil
    assert s.offset == 5

    assert s.skip(/\w+\s/) == 3
    assert s.offset == 8

    assert s.skip(/\w+\s/) == 2
    assert s.offset == 10

    assert s.skip(/\w+/) == 6
    assert s.offset == 16
  end
end

describe StringScanner, "#skip_until" do
  it "advances the offset but does not returns the string matched" do
    s = StringScanner.new("this is a string")

    assert s.skip_until(/not/) == nil
    assert s.offset == 0
    assert s[0]?.nil?

    assert s.skip_until(/a\s/) == 10
    assert s.offset == 10
    assert s[0]?

    assert s.skip_until(/ng/) == 6
    assert s.offset == 16
  end
end

describe StringScanner, "#eos" do
  it "it is true when the offset is at the end" do
    s = StringScanner.new("this is a string")
    assert s.eos? == false
    s.skip(/(\w+\s?){4}/)
    assert s.eos? == true
  end
end

describe StringScanner, "#check" do
  it "returns the string matched but does not advances the offset" do
    s = StringScanner.new("this is a string")
    s.offset = 5

    assert s.check(/\w+\s/) == "is "
    assert s.offset == 5
    assert s.check(/\w+\s/) == "is "
    assert s.offset == 5
  end

  it "returns nil if it can't match from the offset" do
    s = StringScanner.new("test string")
    assert s.check(/\d+/).nil?
  end
end

describe StringScanner, "#check_until" do
  it "returns the string matched and advances the offset" do
    s = StringScanner.new("test string")
    assert s.check_until(/tr/) == "test str"
    assert s.offset == 0
    assert s.check_until(/g/) == "test string"
    assert s.offset == 0
  end

  it "returns nil if it can't match from the offset" do
    s = StringScanner.new("test string")
    s.offset = 8
    assert s.check_until(/tr/).nil?
  end
end

describe StringScanner, "#rest" do
  it "returns the remainder of the string from the offset" do
    s = StringScanner.new("this is a string")
    assert s.rest == "this is a string"

    s.scan(/this is a /)
    assert s.rest == "string"

    s.scan(/string/)
    assert s.rest == ""
  end
end

describe StringScanner, "#[]" do
  it "allows access to subgroups of the last match" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    regex = /(?<wday>\w+) (?<month>\w+) (?<day>\d+)/
    assert s.scan(regex) == "Fri Dec 12"
    assert s[0] == "Fri Dec 12"
    assert s[1] == "Fri"
    assert s[2] == "Dec"
    assert s[3] == "12"
    assert s["wday"] == "Fri"
    assert s["month"] == "Dec"
    assert s["day"] == "12"
  end

  it "raises when there is no last match" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/this is not there/)

    expect_raises { s[0] }
  end

  it "raises when there is no subgroup" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    regex = /(?<wday>\w+) (?<month>\w+) (?<day>\d+)/
    s.scan(regex)

    assert s[0]
    expect_raises { s[5] }
    expect_raises { s["something"] }
  end
end

describe StringScanner, "#[]?" do
  it "allows access to subgroups of the last match" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    result = s.scan(/(?<wday>\w+) (?<month>\w+) (?<day>\d+)/)

    assert result == "Fri Dec 12"
    assert s[0]? == "Fri Dec 12"
    assert s[1]? == "Fri"
    assert s[2]? == "Dec"
    assert s[3]? == "12"
    assert s["wday"]? == "Fri"
    assert s["month"]? == "Dec"
    assert s["day"]? == "12"
  end

  it "returns nil when there is no last match" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/this is not there/)

    assert s[0]?.nil?
  end

  it "raises when there is no subgroup" do
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/(?<wday>\w+) (?<month>\w+) (?<day>\d+)/)

    assert s[0]
    assert s[5]?.nil?
    assert s["something"]?.nil?
  end
end

describe StringScanner, "#string" do
  it { assert StringScanner.new("foo").string == "foo" }
end

describe StringScanner, "#offset" do
  it "returns the current position" do
    s = StringScanner.new("this is a string")
    assert s.offset == 0
    s.scan(/\w+/)
    assert s.offset == 4
  end
end

describe StringScanner, "#offset=" do
  it "sets the current position" do
    s = StringScanner.new("this is a string")
    s.offset = 5
    assert s.scan(/\w+/) == "is"
  end

  it "raises on negative positions" do
    s = StringScanner.new("this is a string")
    expect_raises(IndexError) { s.offset = -2 }
  end
end

describe StringScanner, "#inspect" do
  it "has information on the scanner" do
    s = StringScanner.new("this is a string")
    assert s.inspect == %(#<StringScanner 0/16 "this " >)
    s.scan(/\w+\s/)
    assert s.inspect == %(#<StringScanner 5/16 "s is " >)
    s.scan(/\w+\s/)
    assert s.inspect == %(#<StringScanner 8/16 "s a s" >)
    s.scan(/\w+\s\w+/)
    assert s.inspect == %(#<StringScanner 16/16 "tring" >)
  end
end

describe StringScanner, "#peek" do
  it "shows the next len characters without advancing the offset" do
    s = StringScanner.new("this is a string")
    assert s.offset == 0
    assert s.peek(4) == "this"
    assert s.offset == 0
    assert s.peek(7) == "this is"
    assert s.offset == 0
  end
end

describe StringScanner, "#reset" do
  it "resets the scan offset to the beginning and clears the last match" do
    s = StringScanner.new("this is a string")
    s.scan_until(/str/)
    assert s[0]?
    assert s.offset != 0

    s.reset
    assert s[0]?.nil?
    assert s.offset == 0
  end
end

describe StringScanner, "#terminate" do
  it "moves the scan offset to the end of the string and clears the last match" do
    s = StringScanner.new("this is a string")
    s.scan_until(/str/)
    assert s[0]?
    assert s.eos? == false

    s.terminate
    assert s[0]?.nil?
    assert s.eos? == true
  end
end
