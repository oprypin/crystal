require "spec"
require "char/reader"

describe "Char::Reader" do
  it "iterates through empty string" do
    reader = Char::Reader.new("")
    assert reader.pos == 0
    assert reader.current_char.ord == 0
    assert reader.has_next? == false

    expect_raises IndexError do
      reader.next_char
    end
  end

  it "iterates through string of size one" do
    reader = Char::Reader.new("a")
    assert reader.pos == 0
    assert reader.current_char == 'a'
    assert reader.has_next? == true
    assert reader.next_char.ord == 0
    assert reader.has_next? == false

    expect_raises IndexError do
      reader.next_char
    end
  end

  it "iterates through chars" do
    reader = Char::Reader.new("há日本語")
    assert reader.pos == 0
    assert reader.current_char.ord == 104
    assert reader.has_next? == true

    assert reader.next_char.ord == 225

    assert reader.pos == 1
    assert reader.current_char.ord == 225

    assert reader.next_char.ord == 26085
    assert reader.next_char.ord == 26412
    assert reader.next_char.ord == 35486
    assert reader.has_next? == true

    assert reader.next_char.ord == 0
    assert reader.has_next? == false

    expect_raises IndexError do
      reader.next_char
    end
  end

  it "peeks next char" do
    reader = Char::Reader.new("há日本語")
    assert reader.peek_next_char.ord == 225
  end

  it "sets pos" do
    reader = Char::Reader.new("há日本語")
    reader.pos = 1
    assert reader.pos == 1
    assert reader.current_char.ord == 225
  end

  it "is an Enumerable(Char)" do
    reader = Char::Reader.new("abc")
    sum = 0
    reader.each do |char|
      sum += char.ord
    end
    assert sum == 294
  end

  it "is an Enumerable(Char) but doesn't yield if empty" do
    reader = Char::Reader.new("")
    reader.each do |char|
      fail "reader each shouldn't yield on empty string"
    end
  end

  it "errors if 0x80 <= first_byte < 0xC2" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0x80]) }
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xC1]) }
  end

  it "errors if (second_byte & 0xC0) != 0x80" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xd0, 0]) }
  end

  it "errors if first_byte == 0xE0 && second_byte < 0xA0" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xe0, 0x9F, 0xA0]) }
  end

  it "errors if first_byte < 0xF0 && (third_byte & 0xC0) != 0x80" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xe0, 0xA0, 0]) }
  end

  it "errors if first_byte == 0xF0 && second_byte < 0x90" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xf0, 0x8F, 0xA0]) }
  end

  it "errors if first_byte == 0xF4 && second_byte >= 0x90" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xf4, 0x90, 0xA0]) }
  end

  it "errors if first_byte < 0xF5 && (fourth_byte & 0xC0) != 0x80" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xf4, 0x8F, 0xA0, 0]) }
  end

  it "errors if first_byte >= 0xF5" do
    expect_raises(InvalidByteSequenceError) { Char::Reader.new(String.new Bytes[0xf5, 0x8F, 0xA0, 0xA0]) }
  end
end
