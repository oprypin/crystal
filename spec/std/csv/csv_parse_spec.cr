require "spec"
require "csv"

describe CSV do
  describe "parse" do
    it "parses empty string" do
      assert CSV.parse("") == [] of String
    end

    it "parses one simple row" do
      assert CSV.parse("hello,world") == [["hello", "world"]]
    end

    it "parses one row with spaces" do
      assert CSV.parse("   hello   ,   world  ") == [["   hello   ", "   world  "]]
    end

    it "parses two rows" do
      assert CSV.parse("hello,world\ngood,bye") == [
        ["hello", "world"],
        ["good", "bye"],
      ]
    end

    it "parses two rows with the last one having a newline" do
      assert CSV.parse("hello,world\ngood,bye\n") == [
        ["hello", "world"],
        ["good", "bye"],
      ]
    end

    it "parses with quote" do
      assert CSV.parse(%("hello","world")) == [["hello", "world"]]
    end

    it "parses with quote and newline" do
      assert CSV.parse(%("hello","world"\nfoo)) == [["hello", "world"], ["foo"]]
    end

    it "parses with double quote" do
      assert CSV.parse(%("hel""lo","wor""ld")) == [[%(hel"lo), %(wor"ld)]]
    end

    it "parses some commas" do
      assert CSV.parse(%(,,)) == [["", "", ""]]
    end

    it "parses empty quoted string" do
      assert CSV.parse(%("","")) == [["", ""]]
    end

    it "raises if single quote in the middle" do
      expect_raises CSV::MalformedCSVError, "unexpected quote at 1:4" do
        CSV.parse(%(hel"lo))
      end
    end

    it "raises if command, newline or end doesn't follow quote" do
      expect_raises CSV::MalformedCSVError, "expecting comma, newline or end, not 'a' at 2:6" do
        CSV.parse(%(foo\n"hel"a))
      end
    end

    it "raises if command, newline or end doesn't follow quote (2)" do
      expect_raises CSV::MalformedCSVError, "expecting comma, newline or end, not 'a' at 2:6" do
        CSV.parse(%(\n"hel"a))
      end
    end

    it "parses from IO" do
      assert CSV.parse(MemoryIO.new(%("hel""lo",world))) == [[%(hel"lo), %(world)]]
    end

    it "takes an optional separator argument" do
      assert CSV.parse("foo;bar", separator: ';') == [["foo", "bar"]]
    end

    it "takes an optional quote char argument" do
      assert CSV.parse("'foo,bar'", quote_char: '\'') == [["foo,bar"]]
    end
  end

  it "parses row by row" do
    parser = CSV::Parser.new("hello,world\ngood,bye\n")
    assert parser.next_row == %w(hello world)
    assert parser.next_row == %w(good bye)
    assert parser.next_row.nil?
  end

  it "does CSV.each_row" do
    sum = 0
    CSV.each_row("1,2\n3,4\n") do |row|
      sum += row.map(&.to_i).sum
    end
    assert sum == 10
  end

  it "gets row iterator" do
    iter = CSV.each_row("1,2\n3,4\n")
    assert iter.next == ["1", "2"]
    assert iter.next == ["3", "4"]
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == ["1", "2"]
  end
end
