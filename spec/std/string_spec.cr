require "spec"

describe "String" do
  describe "[]" do
    it "gets with positive index" do
      c = "hello!"[1]
      assert c.is_a?(Char)
      assert c == 'e'
    end

    it "gets with negative index" do
      assert "hello!"[-1] == '!'
    end

    it "gets with inclusive range" do
      assert "hello!"[1..4] == "ello"
    end

    it "gets with inclusive range with negative indices" do
      assert "hello!"[-5..-2] == "ello"
    end

    it "gets with exclusive range" do
      assert "hello!"[1...4] == "ell"
    end

    it "gets with start and count" do
      assert "hello"[1, 3] == "ell"
    end

    it "gets with exclusive range with unicode" do
      assert "há日本語"[1..3] == "á日本"
    end

    it "gets when index is last and count is zero" do
      assert "foo"[3, 0] == ""
    end

    it "gets when index is last and count is positive" do
      assert "foo"[3, 10] == ""
    end

    it "gets when index is last and count is negative at last" do
      expect_raises(ArgumentError) do
        "foo"[3, -1]
      end
    end

    it { assert "foo"[3..-10] == "" }

    it "gets when index is last and count is negative at last with utf-8" do
      expect_raises(ArgumentError) do
        "há日本語"[5, -1]
      end
    end

    it "gets when index is last and count is zero in utf-8" do
      assert "há日本語"[5, 0] == ""
    end

    it "gets when index is last and count is positive in utf-8" do
      assert "há日本語"[5, 10] == ""
    end

    it "raises index out of bound on index out of range with range" do
      expect_raises(IndexError) do
        "foo"[4..1]
      end
    end

    it "raises index out of bound on index out of range with range and utf-8" do
      expect_raises(IndexError) do
        "há日本語"[6..1]
      end
    end

    it "gets with exclusive with start and count" do
      assert "há日本語"[1, 3] == "á日本"
    end

    it "gets with exclusive with start and count to end" do
      assert "há日本語"[1, 4] == "á日本語"
    end

    it "gets with start and count with negative start" do
      assert "こんいちは"[-3, 2] == "いち"
    end

    it "raises if index out of bounds" do
      expect_raises(IndexError) do
        "foo"[4, 1]
      end
    end

    it "raises if index out of bounds with utf-8" do
      expect_raises(IndexError) do
        "こんいちは"[6, 1]
      end
    end

    it "raises if count is negative" do
      expect_raises(ArgumentError) do
        "foo"[1, -1]
      end
    end

    it "raises if count is negative with utf-8" do
      expect_raises(ArgumentError) do
        "こんいちは"[3, -1]
      end
    end

    it "gets with single char" do
      assert ";"[0..-2] == ""
    end

    it "raises on too negative left bound" do
      expect_raises IndexError do
        "foo"[-4..0]
      end
    end

    describe "with a regex" do
      it { assert "FooBar"[/o+/] == "oo" }
      it { assert "FooBar"[/([A-Z])/, 1] == "F" }
      it { assert "FooBar"[/x/]?.nil? }
      it { assert "FooBar"[/x/, 1]?.nil? }
      it { assert "FooBar"[/(x)/, 1]?.nil? }
      it { assert "FooBar"[/o(o)/, 2]?.nil? }
      it { assert "FooBar"[/o(?<this>o)/, "this"] == "o" }
      it { assert "FooBar"[/(?<this>x)/, "that"]?.nil? }
    end

    it "gets with a string" do
      assert "FooBar"["Bar"] == "Bar"
      expect_raises { "FooBar"["Baz"] }
      assert "FooBar"["Bar"]? == "Bar"
      assert "FooBar"["Baz"]?.nil?
    end

    it "gets with index and []?" do
      assert "hello"[1]? == 'e'
      assert "hello"[5]?.nil?
      assert "hello"[-1]? == 'o'
      assert "hello"[-6]?.nil?
    end
  end

  describe "byte_slice" do
    it "gets byte_slice" do
      assert "hello".byte_slice(1, 3) == "ell"
    end

    it "gets byte_slice with negative count" do
      expect_raises(ArgumentError) do
        "hello".byte_slice(1, -10)
      end
    end

    it "gets byte_slice with negative count at last" do
      expect_raises(ArgumentError) do
        "hello".byte_slice(5, -1)
      end
    end

    it "gets byte_slice with start out of bounds" do
      expect_raises(IndexError) do
        "hello".byte_slice(10, 3)
      end
    end

    it "gets byte_slice with large count" do
      assert "hello".byte_slice(1, 10) == "ello"
    end

    it "gets byte_slice with negative index" do
      assert "hello".byte_slice(-2, 3) == "lo"
    end
  end

  describe "i" do
    it { assert "1234".to_i == 1234 }
    it { assert "   +1234   ".to_i == 1234 }
    it { assert "   -1234   ".to_i == -1234 }
    it { assert "   +1234   ".to_i == 1234 }
    it { assert "   -00001234".to_i == -1234 }
    it { assert "1_234".to_i(underscore: true) == 1234 }
    it { assert "1101".to_i(base: 2) == 13 }
    it { assert "12ab".to_i(16) == 4779 }
    it { assert "0x123abc".to_i(prefix: true) == 1194684 }
    it { assert "0b1101".to_i(prefix: true) == 13 }
    it { assert "0b001101".to_i(prefix: true) == 13 }
    it { assert "0123".to_i(prefix: true) == 83 }
    it { assert "123hello".to_i(strict: false) == 123 }
    it { assert "99 red balloons".to_i(strict: false) == 99 }
    it { assert "   99 red balloons".to_i(strict: false) == 99 }
    it { expect_raises(ArgumentError) { "hello".to_i } }
    it { expect_raises(ArgumentError) { "1__234".to_i } }
    it { expect_raises(ArgumentError) { "1_234".to_i } }
    it { expect_raises(ArgumentError) { "   1234   ".to_i(whitespace: false) } }
    it { expect_raises(ArgumentError) { "0x123".to_i } }
    it { expect_raises(ArgumentError) { "0b123".to_i } }
    it { expect_raises(ArgumentError) { "000b123".to_i(prefix: true) } }
    it { expect_raises(ArgumentError) { "000x123".to_i(prefix: true) } }
    it { expect_raises(ArgumentError) { "123hello".to_i } }
    it { assert "z".to_i(36) == 35 }
    it { assert "Z".to_i(36) == 35 }
    it { assert "0".to_i(62) == 0 }
    it { assert "1".to_i(62) == 1 }
    it { assert "a".to_i(62) == 10 }
    it { assert "z".to_i(62) == 35 }
    it { assert "A".to_i(62) == 36 }
    it { assert "Z".to_i(62) == 61 }
    it { assert "10".to_i(62) == 62 }
    it { assert "1z".to_i(62) == 97 }
    it { assert "ZZ".to_i(62) == 3843 }

    describe "to_i8" do
      it { assert "127".to_i8 == 127 }
      it { assert "-128".to_i8 == -128 }
      it { expect_raises(ArgumentError) { "128".to_i8 } }
      it { expect_raises(ArgumentError) { "-129".to_i8 } }

      it { assert "127".to_i8? == 127 }
      it { assert "128".to_i8?.nil? }
      it { assert "128".to_i8 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_i8 } }
    end

    describe "to_u8" do
      it { assert "255".to_u8 == 255 }
      it { assert "0".to_u8 == 0 }
      it { expect_raises(ArgumentError) { "256".to_u8 } }
      it { expect_raises(ArgumentError) { "-1".to_u8 } }

      it { assert "255".to_u8? == 255 }
      it { assert "256".to_u8?.nil? }
      it { assert "256".to_u8 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_u8 } }
    end

    describe "to_i16" do
      it { assert "32767".to_i16 == 32767 }
      it { assert "-32768".to_i16 == -32768 }
      it { expect_raises(ArgumentError) { "32768".to_i16 } }
      it { expect_raises(ArgumentError) { "-32769".to_i16 } }

      it { assert "32767".to_i16? == 32767 }
      it { assert "32768".to_i16?.nil? }
      it { assert "32768".to_i16 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_i16 } }
    end

    describe "to_u16" do
      it { assert "65535".to_u16 == 65535 }
      it { assert "0".to_u16 == 0 }
      it { expect_raises(ArgumentError) { "65536".to_u16 } }
      it { expect_raises(ArgumentError) { "-1".to_u16 } }

      it { assert "65535".to_u16? == 65535 }
      it { assert "65536".to_u16?.nil? }
      it { assert "65536".to_u16 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_u16 } }
    end

    describe "to_i32" do
      it { assert "2147483647".to_i32 == 2147483647 }
      it { assert "-2147483648".to_i32 == -2147483648 }
      it { expect_raises(ArgumentError) { "2147483648".to_i32 } }
      it { expect_raises(ArgumentError) { "-2147483649".to_i32 } }

      it { assert "2147483647".to_i32? == 2147483647 }
      it { assert "2147483648".to_i32?.nil? }
      it { assert "2147483648".to_i32 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_i32 } }
    end

    describe "to_u32" do
      it { assert "4294967295".to_u32 == 4294967295 }
      it { assert "0".to_u32 == 0 }
      it { expect_raises(ArgumentError) { "4294967296".to_u32 } }
      it { expect_raises(ArgumentError) { "-1".to_u32 } }

      it { assert "4294967295".to_u32? == 4294967295 }
      it { assert "4294967296".to_u32?.nil? }
      it { assert "4294967296".to_u32 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_u32 } }
    end

    describe "to_i64" do
      it { assert "9223372036854775807".to_i64 == 9223372036854775807 }
      it { assert "-9223372036854775808".to_i64 == -9223372036854775808 }
      it { expect_raises(ArgumentError) { "9223372036854775808".to_i64 } }
      it { expect_raises(ArgumentError) { "-9223372036854775809".to_i64 } }

      it { assert "9223372036854775807".to_i64? == 9223372036854775807 }
      it { assert "9223372036854775808".to_i64?.nil? }
      it { assert "9223372036854775808".to_i64 { 0 } == 0 }

      it { expect_raises(ArgumentError) { "18446744073709551616".to_i64 } }
    end

    describe "to_u64" do
      it { assert "18446744073709551615".to_u64 == 18446744073709551615 }
      it { assert "0".to_u64 == 0 }
      it { expect_raises(ArgumentError) { "18446744073709551616".to_u64 } }
      it { expect_raises(ArgumentError) { "-1".to_u64 } }

      it { assert "18446744073709551615".to_u64? == 18446744073709551615 }
      it { assert "18446744073709551616".to_u64?.nil? }
      it { assert "18446744073709551616".to_u64 { 0 } == 0 }
    end

    it { assert "1234".to_i32 == 1234 }
    it { assert "1234123412341234".to_i64 == 1234123412341234_i64 }
    it { assert "9223372036854775808".to_u64 == 9223372036854775808_u64 }

    it { expect_raises(ArgumentError, "invalid base 1") { "12ab".to_i(1) } }
    it { expect_raises(ArgumentError, "invalid base 37") { "12ab".to_i(37) } }

    it { expect_raises { "1Y2P0IJ32E8E7".to_i(36) } }
    it { assert "1Y2P0IJ32E8E7".to_i64(36) == 9223372036854775807 }
  end

  it "does to_f" do
    expect_raises(ArgumentError) { "".to_f }
    assert "".to_f?.nil?
    expect_raises(ArgumentError) { " ".to_f }
    assert " ".to_f?.nil?
    assert "0".to_f == 0_f64
    assert "0.0".to_f == 0_f64
    assert "+0.0".to_f == 0_f64
    assert "-0.0".to_f == 0_f64
    assert "1234.56".to_f == 1234.56_f64
    assert "1234.56".to_f? == 1234.56_f64
    assert "+1234.56".to_f? == 1234.56_f64
    assert "-1234.56".to_f? == -1234.56_f64
    expect_raises(ArgumentError) { "foo".to_f }
    assert "foo".to_f?.nil?
    assert "  1234.56  ".to_f == 1234.56_f64
    assert "  1234.56  ".to_f? == 1234.56_f64
    expect_raises(ArgumentError) { "  1234.56  ".to_f(whitespace: false) }
    assert "  1234.56  ".to_f?(whitespace: false).nil?
    expect_raises(ArgumentError) { "  1234.56foo".to_f }
    assert "  1234.56foo".to_f?.nil?
    assert "123.45 x".to_f64(strict: false) == 123.45_f64
    expect_raises(ArgumentError) { "x1.2".to_f64 }
    assert "x1.2".to_f64?.nil?
    expect_raises(ArgumentError) { "x1.2".to_f64(strict: false) }
    assert "x1.2".to_f64?(strict: false).nil?
  end

  it "does to_f32" do
    expect_raises(ArgumentError) { "".to_f32 }
    assert "".to_f32?.nil?
    expect_raises(ArgumentError) { " ".to_f32 }
    assert " ".to_f32?.nil?
    assert "0".to_f32 == 0_f32
    assert "0.0".to_f32 == 0_f32
    assert "+0.0".to_f32 == 0_f32
    assert "-0.0".to_f32 == 0_f32
    assert "1234.56".to_f32 == 1234.56_f32
    assert "1234.56".to_f32? == 1234.56_f32
    assert "+1234.56".to_f32? == 1234.56_f32
    assert "-1234.56".to_f32? == -1234.56_f32
    expect_raises(ArgumentError) { "foo".to_f32 }
    assert "foo".to_f32?.nil?
    assert "  1234.56  ".to_f32 == 1234.56_f32
    assert "  1234.56  ".to_f32? == 1234.56_f32
    expect_raises(ArgumentError) { "  1234.56  ".to_f32(whitespace: false) }
    assert "  1234.56  ".to_f32?(whitespace: false).nil?
    expect_raises(ArgumentError) { "  1234.56foo".to_f32 }
    assert "  1234.56foo".to_f32?.nil?
    assert "123.45 x".to_f32(strict: false) == 123.45_f32
    expect_raises(ArgumentError) { "x1.2".to_f32 }
    assert "x1.2".to_f32?.nil?
    expect_raises(ArgumentError) { "x1.2".to_f32(strict: false) }
    assert "x1.2".to_f32?(strict: false).nil?
  end

  it "does to_f64" do
    expect_raises(ArgumentError) { "".to_f64 }
    assert "".to_f64?.nil?
    expect_raises(ArgumentError) { " ".to_f64 }
    assert " ".to_f64?.nil?
    assert "0".to_f64 == 0_f64
    assert "0.0".to_f64 == 0_f64
    assert "+0.0".to_f64 == 0_f64
    assert "-0.0".to_f64 == 0_f64
    assert "1234.56".to_f64 == 1234.56_f64
    assert "1234.56".to_f64? == 1234.56_f64
    assert "+1234.56".to_f? == 1234.56_f64
    assert "-1234.56".to_f? == -1234.56_f64
    expect_raises(ArgumentError) { "foo".to_f64 }
    assert "foo".to_f64?.nil?
    assert "  1234.56  ".to_f64 == 1234.56_f64
    assert "  1234.56  ".to_f64? == 1234.56_f64
    expect_raises(ArgumentError) { "  1234.56  ".to_f64(whitespace: false) }
    assert "  1234.56  ".to_f64?(whitespace: false).nil?
    expect_raises(ArgumentError) { "  1234.56foo".to_f64 }
    assert "  1234.56foo".to_f64?.nil?
    assert "123.45 x".to_f64(strict: false) == 123.45_f64
    expect_raises(ArgumentError) { "x1.2".to_f64 }
    assert "x1.2".to_f64?.nil?
    expect_raises(ArgumentError) { "x1.2".to_f64(strict: false) }
    assert "x1.2".to_f64?(strict: false).nil?
  end

  it "compares strings: different size" do
    assert "foo" != "fo"
  end

  it "compares strings: same object" do
    f = "foo"
    assert f == f
  end

  it "compares strings: same size, same string" do
    assert "foo" == "fo" + "o"
  end

  it "compares strings: same size, different string" do
    assert "foo" != "bar"
  end

  it "interpolates string" do
    foo = "<foo>"
    bar = 123
    assert "foo #{bar}" == "foo 123"
    assert "foo #{bar}" == "foo 123"
    assert "#{foo} bar" == "<foo> bar"
  end

  it "multiplies" do
    str = "foo"
    assert (str * 0) == ""
    assert (str * 3) == "foofoofoo"
  end

  it "multiplies with size one" do
    str = "f"
    assert (str * 0) == ""
    assert (str * 10) == "ffffffffff"
  end

  it "multiplies with negative size" do
    expect_raises(ArgumentError, "negative argument") do
      "f" * -1
    end
  end

  describe "downcase" do
    it { assert "HELLO!".downcase == "hello!" }
    it { assert "HELLO MAN!".downcase == "hello man!" }
  end

  describe "upcase" do
    it { assert "hello!".upcase == "HELLO!" }
    it { assert "hello man!".upcase == "HELLO MAN!" }
  end

  describe "capitalize" do
    it { assert "HELLO!".capitalize == "Hello!" }
    it { assert "HELLO MAN!".capitalize == "Hello man!" }
    it { assert "".capitalize == "" }
  end

  describe "chomp" do
    it { assert "hello\n".chomp == "hello" }
    it { assert "hello\r".chomp == "hello" }
    it { assert "hello\r\n".chomp == "hello" }
    it { assert "hello".chomp == "hello" }
    it { assert "hello".chomp == "hello" }
    it { assert "かたな\n".chomp == "かたな" }
    it { assert "かたな\r".chomp == "かたな" }
    it { assert "かたな\r\n".chomp == "かたな" }
    it { assert "hello\n\n".chomp == "hello\n" }
    it { assert "hello\r\n\n".chomp == "hello\r\n" }

    it { assert "hello".chomp('a') == "hello" }
    it { assert "hello".chomp('o') == "hell" }
    it { assert "かたな".chomp('な') == "かた" }

    it { assert "hello".chomp("good") == "hello" }
    it { assert "hello".chomp("llo") == "he" }
    it { assert "かたな".chomp("たな") == "か" }

    it { assert "hello\n\n\n\n".chomp("") == "hello\n\n\n\n" }
  end

  describe "chop" do
    it { assert "foo".chop == "fo" }
    it { assert "foo\n".chop == "foo" }
    it { assert "foo\r".chop == "foo" }
    it { assert "foo\r\n".chop == "foo" }
    it { assert "\r\n".chop == "" }
    it { assert "かたな".chop == "かた" }
    it { assert "かたな\n".chop == "かたな" }
    it { assert "かたな\r\n".chop == "かたな" }
  end

  describe "strip" do
    it { assert "  hello  \n\t\f\v\r".strip == "hello" }
    it { assert "hello".strip == "hello" }
    it { assert "かたな \n\f\v".strip == "かたな" }
    it { assert "  \n\t かたな \n\f\v".strip == "かたな" }
    it { assert "  \n\t かたな".strip == "かたな" }
    it { assert "かたな".strip == "かたな" }
    it { assert "".strip == "" }
    it { assert "\n".strip == "" }
    it { assert "\n\t  ".strip == "" }
  end

  describe "rstrip" do
    it { assert "  hello  ".rstrip == "  hello" }
    it { assert "hello".rstrip == "hello" }
    it { assert "  かたな \n\f\v".rstrip == "  かたな" }
    it { assert "かたな".rstrip == "かたな" }
  end

  describe "lstrip" do
    it { assert "  hello  ".lstrip == "hello  " }
    it { assert "hello".lstrip == "hello" }
    it { assert "  \n\v かたな  ".lstrip == "かたな  " }
    it { assert "  かたな".lstrip == "かたな" }
  end

  describe "empty?" do
    it { assert "a".empty? == false }
    it { assert "".empty? == true }
  end

  describe "index" do
    describe "by char" do
      it { assert "foo".index('o') == 1 }
      it { assert "foo".index('g').nil? }
      it { assert "bar".index('r') == 2 }
      it { assert "日本語".index('本') == 1 }
      it { assert "bar".index('あ').nil? }

      describe "with offset" do
        it { assert "foobarbaz".index('a', 5) == 7 }
        it { assert "foobarbaz".index('a', -4) == 7 }
        it { assert "foo".index('g', 1).nil? }
        it { assert "foo".index('g', -20).nil? }
        it { assert "日本語日本語".index('本', 2) == 4 }
      end
    end

    describe "by string" do
      it { assert "foo bar".index("o b") == 2 }
      it { assert "foo".index("fg").nil? }
      it { assert "foo".index("") == 0 }
      it { assert "foo".index("foo") == 0 }
      it { assert "日本語日本語".index("本語") == 1 }

      describe "with offset" do
        it { assert "foobarbaz".index("ba", 4) == 6 }
        it { assert "foobarbaz".index("ba", -5) == 6 }
        it { assert "foo".index("ba", 1).nil? }
        it { assert "foo".index("ba", -20).nil? }
        it { assert "日本語日本語".index("本語", 2) == 4 }
      end
    end
  end

  describe "rindex" do
    describe "by char" do
      it { assert "foobar".rindex('a') == 4 }
      it { assert "foobar".rindex('g').nil? }
      it { assert "日本語日本語".rindex('本') == 4 }

      describe "with offset" do
        it { assert "faobar".rindex('a', 3) == 1 }
        it { assert "faobarbaz".rindex('a', -3) == 4 }
        it { assert "日本語日本語".rindex('本', 3) == 1 }
      end
    end

    describe "by string" do
      it { assert "foo baro baz".rindex("o b") == 7 }
      it { assert "foo baro baz".rindex("fg").nil? }
      it { assert "日本語日本語".rindex("日本") == 3 }

      describe "with offset" do
        it { assert "foo baro baz".rindex("o b", 6) == 2 }
        it { assert "foo baro baz".rindex("fg").nil? }
        it { assert "日本語日本語".rindex("日本", 2) == 0 }
      end
    end
  end

  describe "byte_index" do
    it { assert "foo".byte_index('o'.ord) == 1 }
    it { assert "foo bar booz".byte_index('o'.ord, 3) == 9 }
    it { assert "foo".byte_index('a'.ord).nil? }

    it "gets byte index of string" do
      assert "hello world".byte_index("lo") == 3
    end
  end

  describe "includes?" do
    describe "by char" do
      it { assert "foo".includes?('o') == true }
      it { assert "foo".includes?('g') == false }
    end

    describe "by string" do
      it { assert "foo bar".includes?("o b") == true }
      it { assert "foo".includes?("fg") == false }
      it { assert "foo".includes?("") == true }
    end
  end

  describe "split" do
    describe "by char" do
      it { assert "".split(',') == [""] }
      it { assert "foo,bar,,baz,".split(',') == ["foo", "bar", "", "baz", ""] }
      it { assert "foo,bar,,baz".split(',') == ["foo", "bar", "", "baz"] }
      it { assert "foo".split(',') == ["foo"] }
      it { assert "foo".split(' ') == ["foo"] }
      it { assert "   foo".split(' ') == ["", "", "", "foo"] }
      it { assert "foo   ".split(' ') == ["foo", "", "", ""] }
      it { assert "   foo  bar".split(' ') == ["", "", "", "foo", "", "bar"] }
      it { assert "   foo   bar\n\t  baz   ".split(' ') == ["", "", "", "foo", "", "", "bar\n\t", "", "baz", "", "", ""] }
      it { assert "   foo   bar\n\t  baz   ".split == ["foo", "bar", "baz"] }
      it { assert "   foo   bar\n\t  baz   ".split(2) == ["foo", "bar\n\t  baz   "] }
      it { assert "   foo   bar\n\t  baz   ".split(" ") == ["", "", "", "foo", "", "", "bar\n\t", "", "baz", "", "", ""] }
      it { assert "foo,bar,baz,qux".split(',', 1) == ["foo,bar,baz,qux"] }
      it { assert "foo,bar,baz,qux".split(',', 3) == ["foo", "bar", "baz,qux"] }
      it { assert "foo,bar,baz,qux".split(',', 30) == ["foo", "bar", "baz", "qux"] }
      it { assert "foo bar baz qux".split(' ', 1) == ["foo bar baz qux"] }
      it { assert "foo bar baz qux".split(' ', 3) == ["foo", "bar", "baz qux"] }
      it { assert "foo bar baz qux".split(' ', 30) == ["foo", "bar", "baz", "qux"] }
      it { assert "a,b,".split(',', 3) == ["a", "b", ""] }
      it { assert "日本語 \n\t 日本 \n\n 語".split == ["日本語", "日本", "語"] }
      it { assert "日本ん語日本ん語".split('ん') == ["日本", "語日本", "語"] }
      it { assert "=".split('=') == ["", ""] }
      it { assert "a=".split('=') == ["a", ""] }
      it { assert "=b".split('=') == ["", "b"] }
      it { assert "=".split('=', 2) == ["", ""] }
    end

    describe "by string" do
      it { assert "".split(",") == [""] }
      it { assert "".split(":-") == [""] }
      it { assert "foo:-bar:-:-baz:-".split(":-") == ["foo", "bar", "", "baz", ""] }
      it { assert "foo:-bar:-:-baz".split(":-") == ["foo", "bar", "", "baz"] }
      it { assert "foo".split(":-") == ["foo"] }
      it { assert "foo".split("") == ["f", "o", "o"] }
      it { assert "日本さん語日本さん語".split("さん") == ["日本", "語日本", "語"] }
      it { assert "foo,bar,baz,qux".split(",", 1) == ["foo,bar,baz,qux"] }
      it { assert "foo,bar,baz,qux".split(",", 3) == ["foo", "bar", "baz,qux"] }
      it { assert "foo,bar,baz,qux".split(",", 30) == ["foo", "bar", "baz", "qux"] }
      it { assert "a b c".split(" ", 2) == ["a", "b c"] }
      it { assert "=".split("=") == ["", ""] }
      it { assert "a=".split("=") == ["a", ""] }
      it { assert "=b".split("=") == ["", "b"] }
      it { assert "=".split("=", 2) == ["", ""] }
    end

    describe "by regex" do
      it { assert "".split(/\n\t/) == [""] of String }
      it { assert "foo\n\tbar\n\t\n\tbaz".split(/\n\t/) == ["foo", "bar", "", "baz"] }
      it { assert "foo\n\tbar\n\t\n\tbaz".split(/(?:\n\t)+/) == ["foo", "bar", "baz"] }
      it { assert "foo,bar".split(/,/, 1) == ["foo,bar"] }
      it { assert "foo,bar,".split(/,/) == ["foo", "bar", ""] }
      it { assert "foo,bar,baz,qux".split(/,/, 1) == ["foo,bar,baz,qux"] }
      it { assert "foo,bar,baz,qux".split(/,/, 3) == ["foo", "bar", "baz,qux"] }
      it { assert "foo,bar,baz,qux".split(/,/, 30) == ["foo", "bar", "baz", "qux"] }
      it { assert "a b c".split(Regex.new(" "), 2) == ["a", "b c"] }
      it { assert "日本ん語日本ん語".split(/ん/) == ["日本", "語日本", "語"] }
      it { assert "hello world".split(/\b/) == ["hello", " ", "world", ""] }
      it { assert "abc".split(//) == ["a", "b", "c"] }
      it { assert "hello".split(/\w+/) == ["", ""] }
      it { assert "foo".split(/o/) == ["f", "", ""] }
      it { assert "=".split(/\=/) == ["", ""] }
      it { assert "a=".split(/\=/) == ["a", ""] }
      it { assert "=b".split(/\=/) == ["", "b"] }
      it { assert "=".split(/\=/, 2) == ["", ""] }

      it "keeps groups" do
        s = "split on the word on okay?"
        assert s.split(/(on)/) == ["split ", "on", " the word ", "on", " okay?"]
      end
    end
  end

  describe "starts_with?" do
    it { assert "foobar".starts_with?("foo") == true }
    it { assert "foobar".starts_with?("") == true }
    it { assert "foobar".starts_with?("foobarbaz") == false }
    it { assert "foobar".starts_with?("foox") == false }
    it { assert "foobar".starts_with?('f') == true }
    it { assert "foobar".starts_with?('g') == false }
    it { assert "よし".starts_with?('よ') == true }
    it { assert "よし!".starts_with?("よし") == true }
  end

  describe "ends_with?" do
    it { assert "foobar".ends_with?("bar") == true }
    it { assert "foobar".ends_with?("") == true }
    it { assert "foobar".ends_with?("foobarbaz") == false }
    it { assert "foobar".ends_with?("xbar") == false }
    it { assert "foobar".ends_with?('r') == true }
    it { assert "foobar".ends_with?('x') == false }
    it { assert "よし".ends_with?('し') == true }
    it { assert "よし".ends_with?('な') == false }
  end

  describe "=~" do
    it "matches with group" do
      "foobar" =~ /(o+)ba(r?)/
      assert $1 == "oo"
      assert $2 == "r"
    end

    it "returns nil with string" do
      assert ("foo" =~ "foo").nil?
    end

    it "returns nil with regex and regex" do
      assert (/foo/ =~ /foo/).nil?
    end
  end

  describe "delete" do
    it { assert "foobar".delete { |char| char == 'o' } == "fbar" }
    it { assert "hello world".delete("lo") == "he wrd" }
    it { assert "hello world".delete("lo", "o") == "hell wrld" }
    it { assert "hello world".delete("hello", "^l") == "ll wrld" }
    it { assert "hello world".delete("ej-m") == "ho word" }
    it { assert "hello^world".delete("\\^aeiou") == "hllwrld" }
    it { assert "hello-world".delete("a\\-eo") == "hllwrld" }
    it { assert "hello world\\r\\n".delete("\\") == "hello worldrn" }
    it { assert "hello world\\r\\n".delete("\\A") == "hello world\\r\\n" }
    it { assert "hello world\\r\\n".delete("X-\\w") == "hello orldrn" }

    it "deletes one char" do
      deleted = "foobar".delete('o')
      assert deleted.bytesize == 4
      assert deleted == "fbar"

      deleted = "foobar".delete('x')
      assert deleted.bytesize == 6
      assert deleted == "foobar"
    end
  end

  it "reverses string" do
    reversed = "foobar".reverse
    assert reversed.bytesize == 6
    assert reversed == "raboof"
  end

  it "reverses utf-8 string" do
    reversed = "こんいちは".reverse
    assert reversed.bytesize == 15
    assert reversed.size == 5
    assert reversed == "はちいんこ"
  end

  describe "sub" do
    it "subs char with char" do
      replaced = "foobar".sub('o', 'e')
      assert replaced.bytesize == 6
      assert replaced == "feobar"
    end

    it "subs char with string" do
      replaced = "foobar".sub('o', "ex")
      assert replaced.bytesize == 7
      assert replaced == "fexobar"
    end

    it "subs char with string" do
      replaced = "foobar".sub { |char|
        assert char == 'f'
        "some"
      }
      assert replaced.bytesize == 9
      assert replaced == "someoobar"

      empty = ""
      assert empty.sub { 'f' }.same?(empty)
    end

    it "subs with regex and block" do
      actual = "foo booor booooz".sub(/o+/) { |str|
        "#{str}#{str.size}"
      }
      assert actual == "foo2 booor booooz"
    end

    it "subs with regex and block with group" do
      actual = "foo booor booooz".sub(/(o+).*?(o+)/) { |str, match|
        "#{match[1].size}#{match[2].size}"
      }
      assert actual == "f23r booooz"
    end

    it "subs with regex and string" do
      assert "foo boor booooz".sub(/o+/, "a") == "fa boor booooz"
    end

    it "subs with regex and string, returns self if no match" do
      str = "hello"
      assert str.sub(/a/, "b").same?(str)
    end

    it "subs with regex and string (utf-8)" do
      assert "fここ bここr bここここz".sub(/こ+/, "そこ") == "fそこ bここr bここここz"
    end

    it "subs with empty string" do
      assert "foo".sub("", "x") == "xfoo"
    end

    it "subs with empty regex" do
      assert "foo".sub(//, "x") == "xfoo"
    end

    it "subs null character" do
      null = "\u{0}"
      assert "f\u{0}\u{0}".sub(/#{null}/, "o") == "fo\u{0}"
    end

    it "subs with string and string" do
      assert "foo boor booooz".sub("oo", "a") == "fa boor booooz"
    end

    it "subs with string and string return self if no match" do
      str = "hello"
      assert str.sub("a", "b").same?(str)
    end

    it "subs with string and string (utf-8)" do
      assert "fここ bここr bここここz".sub("ここ", "そこ") == "fそこ bここr bここここz"
    end

    it "subs with string and block" do
      result = "foo boo".sub("oo") { |value|
        assert value == "oo"
        "a"
      }
      assert result == "fa boo"
    end

    it "subs with char hash" do
      str = "hello"
      assert str.sub({'e' => 'a', 'l' => 'd'}) == "hallo"

      empty = ""
      assert empty.sub({'a' => 'b'}).same?(empty)
    end

    it "subs with regex and hash" do
      str = "hello"
      assert str.sub(/(he|l|o)/, {"he" => "ha", "l" => "la"}) == "hallo"
      assert str.sub(/(he|l|o)/, {"l" => "la"}).same?(str)
    end

    it "subs using $~" do
      assert "foo".sub(/(o)/) { "x#{$1}x" } == "fxoxo"
    end

    it "subs using with \\" do
      assert "foo".sub(/(o)/, "\\") == "f\\o"
    end

    it "subs using with z\\w" do
      assert "foo".sub(/(o)/, "z\\w") == "fz\\wo"
    end

    it "replaces with numeric back-reference" do
      assert "foo".sub(/o/, "x\\0x") == "fxoxo"
      assert "foo".sub(/(o)/, "x\\1x") == "fxoxo"
      assert "foo".sub(/(o)/, "\\\\1") == "f\\1o"
      assert "hello".sub(/[aeiou]/, "(\\0)") == "h(e)llo"
    end

    it "replaces with incomplete named back-reference (1)" do
      assert "foo".sub(/(oo)/, "|\\k|") == "f|\\k|"
    end

    it "replaces with incomplete named back-reference (2)" do
      assert "foo".sub(/(oo)/, "|\\k\\1|") == "f|\\koo|"
    end

    it "replaces with named back-reference" do
      assert "foo".sub(/(?<bar>oo)/, "|\\k<bar>|") == "f|oo|"
    end

    it "replaces with multiple named back-reference" do
      assert "fooxx".sub(/(?<bar>oo)(?<baz>x+)/, "|\\k<bar>|\\k<baz>|") == "f|oo|xx|"
    end

    it "replaces with \\a" do
      assert "foo".sub(/(oo)/, "|\\a|") == "f|\\a|"
    end

    it "replaces with \\\\\\1" do
      assert "foo".sub(/(oo)/, "|\\\\\\1|") == "f|\\oo|"
    end

    it "ignores if backreferences: false" do
      assert "foo".sub(/o/, "x\\0x", backreferences: false) == "fx\\0xo"
    end

    it "subs at index with char" do
      string = "hello".sub(1, 'a')
      assert string == "hallo"
      assert string.bytesize == 5
      assert string.size == 5
    end

    it "subs at index with char, non-ascii" do
      string = "あいうえお".sub(2, 'の')
      assert string == "あいのえお"
      assert string.size == 5
      assert string.bytesize == "あいのえお".bytesize
    end

    it "subs at index with string" do
      string = "hello".sub(1, "eee")
      assert string == "heeello"
      assert string.bytesize == 7
      assert string.size == 7
    end

    it "subs at index with string, non-ascii" do
      string = "あいうえお".sub(2, "けくこ")
      assert string == "あいけくこえお"
      assert string.bytesize == "あいけくこえお".bytesize
      assert string.size == 7
    end

    it "subs range with char" do
      string = "hello".sub(1..2, 'a')
      assert string == "halo"
      assert string.bytesize == 4
      assert string.size == 4
    end

    it "subs range with char, non-ascii" do
      string = "あいうえお".sub(1..2, 'け')
      assert string == "あけえお"
      assert string.size == 4
      assert string.bytesize == "あけえお".bytesize
    end

    it "subs range with string" do
      string = "hello".sub(1..2, "eee")
      assert string == "heeelo"
      assert string.size == 6
      assert string.bytesize == 6
    end

    it "subs range with string, non-ascii" do
      string = "あいうえお".sub(1..2, "けくこ")
      assert string == "あけくこえお"
      assert string.size == 6
      assert string.bytesize == "あけくこえお".bytesize
    end
  end

  describe "gsub" do
    it "gsubs char with char" do
      replaced = "foobar".gsub('o', 'e')
      assert replaced.bytesize == 6
      assert replaced == "feebar"
    end

    it "gsubs char with string" do
      replaced = "foobar".gsub('o', "ex")
      assert replaced.bytesize == 8
      assert replaced == "fexexbar"
    end

    it "gsubs char with string depending on the char" do
      replaced = "foobar".gsub do |char|
        case char
        when 'f'
          "some"
        when 'o'
          "thing"
        when 'a'
          "ex"
        else
          char
        end
      end
      assert replaced.bytesize == 18
      assert replaced == "somethingthingbexr"
    end

    it "gsubs with regex and block" do
      actual = "foo booor booooz".gsub(/o+/) do |str|
        "#{str}#{str.size}"
      end
      assert actual == "foo2 booo3r boooo4z"
    end

    it "gsubs with regex and block with group" do
      actual = "foo booor booooz".gsub(/(o+).*?(o+)/) do |str, match|
        "#{match[1].size}#{match[2].size}"
      end
      assert actual == "f23r b31z"
    end

    it "gsubs with regex and string" do
      assert "foo boor booooz".gsub(/o+/, "a") == "fa bar baz"
    end

    it "gsubs with regex and string, returns self if no match" do
      str = "hello"
      assert str.gsub(/a/, "b").same?(str)
    end

    it "gsubs with regex and string (utf-8)" do
      assert "fここ bここr bここここz".gsub(/こ+/, "そこ") == "fそこ bそこr bそこz"
    end

    it "gsubs with empty string" do
      assert "foo".gsub("", "x") == "xfxoxox"
    end

    it "gsubs with empty regex" do
      assert "foo".gsub(//, "x") == "xfxoxox"
    end

    it "gsubs null character" do
      null = "\u{0}"
      assert "f\u{0}\u{0}".gsub(/#{null}/, "o") == "foo"
    end

    it "gsubs with string and string" do
      assert "foo boor booooz".gsub("oo", "a") == "fa bar baaz"
    end

    it "gsubs with string and string return self if no match" do
      str = "hello"
      assert str.gsub("a", "b").same?(str)
    end

    it "gsubs with string and string (utf-8)" do
      assert "fここ bここr bここここz".gsub("ここ", "そこ") == "fそこ bそこr bそこそこz"
    end

    it "gsubs with string and block" do
      i = 0
      result = "foo boo".gsub("oo") do |value|
        assert value == "oo"
        i += 1
        i == 1 ? "a" : "e"
      end
      assert result == "fa be"
    end

    it "gsubs with char hash" do
      str = "hello"
      assert str.gsub({'e' => 'a', 'l' => 'd'}) == "haddo"
    end

    it "gsubs with char named tuple" do
      str = "hello"
      assert str.gsub({e: 'a', l: 'd'}) == "haddo"
    end

    it "gsubs with regex and hash" do
      str = "hello"
      assert str.gsub(/(he|l|o)/, {"he" => "ha", "l" => "la"}) == "halala"
    end

    it "gsubs with regex and named tuple" do
      str = "hello"
      assert str.gsub(/(he|l|o)/, {he: "ha", l: "la"}) == "halala"
    end

    it "gsubs using $~" do
      assert "foo".gsub(/(o)/) { "x#{$1}x" } == "fxoxxox"
    end

    it "replaces with numeric back-reference" do
      assert "foo".gsub(/o/, "x\\0x") == "fxoxxox"
      assert "foo".gsub(/(o)/, "x\\1x") == "fxoxxox"
      assert "foo".gsub(/(ここ)|(oo)/, "x\\1\\2x") == "fxoox"
    end

    it "replaces with named back-reference" do
      assert "foo".gsub(/(?<bar>oo)/, "|\\k<bar>|") == "f|oo|"
      assert "foo".gsub(/(?<x>ここ)|(?<bar>oo)/, "|\\k<bar>|") == "f|oo|"
    end

    it "replaces with incomplete back-reference (1)" do
      assert "foo".gsub(/o/, "\\") == "f\\\\"
    end

    it "replaces with incomplete back-reference (2)" do
      assert "foo".gsub(/o/, "\\\\") == "f\\\\"
    end

    it "replaces with incomplete back-reference (3)" do
      assert "foo".gsub(/o/, "\\k") == "f\\k\\k"
    end

    it "raises with incomplete back-reference (1)" do
      expect_raises(ArgumentError) do
        "foo".gsub(/(?<bar>oo)/, "|\\k<bar|")
      end
    end

    it "raises with incomplete back-reference (2)" do
      expect_raises(ArgumentError, "missing ending '>' for '\\\\k<...") do
        "foo".gsub(/o/, "\\k<")
      end
    end

    it "replaces with back-reference to missing capture group" do
      assert "foo".gsub(/o/, "\\1") == "f"

      expect_raises(IndexError, "undefined group name reference: \"bar\"") do
        assert "foo".gsub(/o/, "\\k<bar>") == "f"
      end

      expect_raises(IndexError, "undefined group name reference: \"\"") do
        "foo".gsub(/o/, "\\k<>")
      end
    end

    it "replaces with escaped back-reference" do
      assert "foo".gsub(/o/, "\\\\0") == "f\\0\\0"
      assert "foo".gsub(/oo/, "\\\\k<bar>") == "f\\k<bar>"
    end

    it "ignores if backreferences: false" do
      assert "foo".gsub(/o/, "x\\0x", backreferences: false) == "fx\\0xx\\0x"
    end
  end

  it "scans using $~" do
    str = String.build do |str|
      "fooxooo".scan(/(o+)/) { str << $1 }
    end
    assert str == "ooooo"
  end

  it "dumps" do
    assert "a".dump == "\"a\""
    assert "\\".dump == "\"\\\\\""
    assert "\"".dump == "\"\\\"\""
    assert "\b".dump == "\"\\b\""
    assert "\e".dump == "\"\\e\""
    assert "\f".dump == "\"\\f\""
    assert "\n".dump == "\"\\n\""
    assert "\r".dump == "\"\\r\""
    assert "\t".dump == "\"\\t\""
    assert "\v".dump == "\"\\v\""
    assert "\#{".dump == "\"\\\#{\""
    assert "á".dump == "\"\\u{e1}\""
    assert "\u{81}".dump == "\"\\u{81}\""
  end

  it "dumps unquoted" do
    assert "a".dump_unquoted == "a"
    assert "\\".dump_unquoted == "\\\\"
    assert "á".dump_unquoted == "\\u{e1}"
    assert "\u{81}".dump_unquoted == "\\u{81}"
  end

  it "inspects" do
    assert "a".inspect == "\"a\""
    assert "\\".inspect == "\"\\\\\""
    assert "\"".inspect == "\"\\\"\""
    assert "\b".inspect == "\"\\b\""
    assert "\e".inspect == "\"\\e\""
    assert "\f".inspect == "\"\\f\""
    assert "\n".inspect == "\"\\n\""
    assert "\r".inspect == "\"\\r\""
    assert "\t".inspect == "\"\\t\""
    assert "\v".inspect == "\"\\v\""
    assert "\#{".inspect == "\"\\\#{\""
    assert "á".inspect == "\"á\""
    assert "\u{81}".inspect == "\"\\u{81}\""
  end

  it "inspects unquoted" do
    assert "a".inspect_unquoted == "a"
    assert "\\".inspect_unquoted == "\\\\"
    assert "á".inspect_unquoted == "á"
    assert "\u{81}".inspect_unquoted == "\\u{81}"
  end

  it "does *" do
    str = "foo" * 10
    assert str.bytesize == 30
    assert str == "foofoofoofoofoofoofoofoofoofoo"
  end

  describe "+" do
    it "does for both ascii" do
      str = "foo" + "bar"
      assert str.bytesize == 6
      assert str.@length == 6
      assert str == "foobar"
    end

    it "does for both unicode" do
      str = "青い" + "旅路"
      assert str.@length == 4
      assert str == "青い旅路"
    end

    it "does with ascii char" do
      str = "foo"
      str2 = str + '/'
      assert str2 == "foo/"
      assert str2.bytesize == 4
      assert str2.size == 4
    end

    it "does with unicode char" do
      str = "fooba"
      str2 = str + 'る'
      assert str2 == "foobaる"
      assert str2.bytesize == 8
      assert str2.size == 6
    end

    it "does when right is empty" do
      str1 = "foo"
      str2 = ""
      assert (str1 + str2).same?(str1)
    end

    it "does when left is empty" do
      str1 = ""
      str2 = "foo"
      assert (str1 + str2).same?(str2)
    end
  end

  it "does %" do
    assert ("foo" % 1) == "foo"
    assert ("foo %d" % 1) == "foo 1"
    assert ("%d" % 123) == "123"
    assert ("%+d" % 123) == "+123"
    assert ("%+d" % -123) == "-123"
    assert ("% d" % 123) == " 123"
    assert ("%i" % 123) == "123"
    assert ("%+i" % 123) == "+123"
    assert ("%+i" % -123) == "-123"
    assert ("% i" % 123) == " 123"
    assert ("%20d" % 123) == "                 123"
    assert ("%+20d" % 123) == "                +123"
    assert ("%+20d" % -123) == "                -123"
    assert ("% 20d" % 123) == "                 123"
    assert ("%020d" % 123) == "00000000000000000123"
    assert ("%+020d" % 123) == "+0000000000000000123"
    assert ("% 020d" % 123) == " 0000000000000000123"
    assert ("%-d" % 123) == "123"
    assert ("%-20d" % 123) == "123                 "
    assert ("%-+20d" % 123) == "+123                "
    assert ("%-+20d" % -123) == "-123                "
    assert ("%- 20d" % 123) == " 123                "
    assert ("%s" % 'a') == "a"
    assert ("%-s" % 'a') == "a"
    assert ("%20s" % 'a') == "                   a"
    assert ("%-20s" % 'a') == "a                   "
    assert ("%*s" % [10, 123]) == "       123"
    assert ("%.5s" % "foo bar baz") == "foo b"
    assert ("%.*s" % [5, "foo bar baz"]) == "foo b"
    assert ("%*.*s" % [20, 5, "foo bar baz"]) == "               foo b"
    assert ("%-*.*s" % [20, 5, "foo bar baz"]) == "foo b               "

    assert ("%%%d" % 1) == "%1"
    assert ("foo %d bar %s baz %d goo" % [1, "hello", 2]) == "foo 1 bar hello baz 2 goo"

    assert ("%b" % 123) == "1111011"
    assert ("%+b" % 123) == "+1111011"
    assert ("% b" % 123) == " 1111011"
    assert ("%-b" % 123) == "1111011"
    assert ("%10b" % 123) == "   1111011"
    assert ("%-10b" % 123) == "1111011   "

    assert ("%o" % 123) == "173"
    assert ("%+o" % 123) == "+173"
    assert ("% o" % 123) == " 173"
    assert ("%-o" % 123) == "173"
    assert ("%6o" % 123) == "   173"
    assert ("%-6o" % 123) == "173   "

    assert ("%x" % 123) == "7b"
    assert ("%+x" % 123) == "+7b"
    assert ("% x" % 123) == " 7b"
    assert ("%-x" % 123) == "7b"
    assert ("%6x" % 123) == "    7b"
    assert ("%-6x" % 123) == "7b    "

    assert ("%X" % 123) == "7B"
    assert ("%+X" % 123) == "+7B"
    assert ("% X" % 123) == " 7B"
    assert ("%-X" % 123) == "7B"
    assert ("%6X" % 123) == "    7B"
    assert ("%-6X" % 123) == "7B    "

    assert ("こんに%xちは" % 123) == "こんに7bちは"
    assert ("こんに%Xちは" % 123) == "こんに7Bちは"

    assert ("%f" % 123) == "123.000000"

    assert ("%g" % 123) == "123"
    assert ("%12f" % 123.45) == "  123.450000"
    assert ("%-12f" % 123.45) == "123.450000  "
    assert ("% f" % 123.45) == " 123.450000"
    assert ("%+f" % 123) == "+123.000000"
    assert ("%012f" % 123) == "00123.000000"
    assert ("%.f" % 1234.56) == "1235"
    assert ("%.2f" % 1234.5678) == "1234.57"
    assert ("%10.2f" % 1234.5678) == "   1234.57"
    assert ("%*.2f" % [10, 1234.5678]) == "   1234.57"
    assert ("%0*.2f" % [10, 1234.5678]) == "0001234.57"
    assert ("%e" % 123.45) == "1.234500e+02"
    assert ("%E" % 123.45) == "1.234500E+02"
    assert ("%G" % 12345678.45) == "1.23457E+07"
    assert ("%a" % 12345678.45) == "0x1.78c29ce666666p+23"
    assert ("%A" % 12345678.45) == "0X1.78C29CE666666P+23"
    assert ("%100.50g" % 123.45) == "                                                  123.4500000000000028421709430404007434844970703125"

    span = 1.second
    assert ("%s" % span) == span.to_s

    assert ("%.2f" % 2.536_f32) == "2.54"
    assert ("%0*.*f" % [10, 2, 2.536_f32]) == "0000002.54"
    expect_raises(ArgumentError, "expected dynamic value '*' to be an Int - \"not a number\" (String)") do
      "%*f" % ["not a number", 2.536_f32]
    end
  end

  it "escapes chars" do
    assert "\b"[0] == '\b'
    assert "\t"[0] == '\t'
    assert "\n"[0] == '\n'
    assert "\v"[0] == '\v'
    assert "\f"[0] == '\f'
    assert "\r"[0] == '\r'
    assert "\e"[0] == '\e'
    assert "\""[0] == '"'
    assert "\\"[0] == '\\'
  end

  it "escapes with octal" do
    assert "\3"[0].ord == 3
    assert "\23"[0].ord == (2 * 8) + 3
    assert "\123"[0].ord == (1 * 8 * 8) + (2 * 8) + 3
    assert "\033"[0].ord == (3 * 8) + 3
    assert "\033a"[1] == 'a'
  end

  it "escapes with unicode" do
    assert "\u{12}".codepoint_at(0) == 1 * 16 + 2
    assert "\u{A}".codepoint_at(0) == 10
    assert "\u{AB}".codepoint_at(0) == 10 * 16 + 11
    assert "\u{AB}1".codepoint_at(1) == '1'.ord
  end

  it "does char_at" do
    assert "いただきます".char_at(2) == 'だ'
  end

  it "does byte_at" do
    assert "hello".byte_at(1) == 'e'.ord
    expect_raises(IndexError) { "hello".byte_at(5) }
  end

  it "does byte_at?" do
    assert "hello".byte_at?(1) == 'e'.ord
    assert "hello".byte_at?(5).nil?
  end

  it "does chars" do
    assert "ぜんぶ".chars == ['ぜ', 'ん', 'ぶ']
  end

  it "allows creating a string with zeros" do
    p = Pointer(UInt8).malloc(3)
    p[0] = 'a'.ord.to_u8
    p[1] = '\0'.ord.to_u8
    p[2] = 'b'.ord.to_u8
    s = String.new(p, 3)
    assert s[0] == 'a'
    assert s[1] == '\0'
    assert s[2] == 'b'
    assert s.bytesize == 3
  end

  describe "tr" do
    it "translates" do
      assert "bla".tr("a", "h") == "blh"
      assert "bla".tr("a", "⊙") == "bl⊙"
      assert "bl⊙a".tr("⊙", "a") == "blaa"
      assert "bl⊙a".tr("⊙", "ⓧ") == "blⓧa"
      assert "bl⊙a⊙asdfd⊙dsfsdf⊙⊙⊙".tr("a⊙", "ⓧt") == "bltⓧtⓧsdfdtdsfsdfttt"
      assert "hello".tr("aeiou", "*") == "h*ll*"
      assert "hello".tr("el", "ip") == "hippo"
      assert "Lisp".tr("Lisp", "Crys") == "Crys"
      assert "hello".tr("helo", "1212") == "12112"
      assert "this".tr("this", "ⓧ") == "ⓧⓧⓧⓧ"
      assert "über".tr("ü", "u") == "uber"
    end

    context "given no replacement characters" do
      it "acts as #delete" do
        assert "foo".tr("o", "") == "foo".delete("o")
      end
    end
  end

  describe "compare" do
    it "compares with == when same string" do
      assert "foo" == "foo"
    end

    it "compares with == when different strings same contents" do
      s1 = "foo#{1}"
      s2 = "foo#{1}"
      assert s1 == s2
    end

    it "compares with == when different contents" do
      s1 = "foo#{1}"
      s2 = "foo#{2}"
      assert s1 != s2
    end

    it "sorts strings" do
      s1 = "foo1"
      s2 = "foo"
      s3 = "bar"
      assert [s1, s2, s3].sort == ["bar", "foo", "foo1"]
    end
  end

  it "does underscore" do
    assert "Foo".underscore == "foo"
    assert "FooBar".underscore == "foo_bar"
    assert "ABCde".underscore == "ab_cde"
    assert "FOO_bar".underscore == "foo_bar"
    assert "Char_S".underscore == "char_s"
    assert "Char_".underscore == "char_"
    assert "C_".underscore == "c_"
    assert "HTTP".underscore == "http"
    assert "HTTP_CLIENT".underscore == "http_client"
  end

  it "does camelcase" do
    assert "foo".camelcase == "Foo"
    assert "foo_bar".camelcase == "FooBar"
  end

  it "answers ascii_only?" do
    assert "a".ascii_only? == true
    assert "あ".ascii_only? == false

    str = String.new(1) do |buffer|
      buffer.value = 'a'.ord.to_u8
      {1, 0}
    end
    assert str.ascii_only? == true

    str = String.new(4) do |buffer|
      count = 0
      'あ'.each_byte do |byte|
        buffer[count] = byte
        count += 1
      end
      {count, 0}
    end
    assert str.ascii_only? == false
  end

  describe "scan" do
    it "does without block" do
      a = "cruel world"
      assert a.scan(/\w+/).map(&.[0]) == ["cruel", "world"]
      assert a.scan(/.../).map(&.[0]) == ["cru", "el ", "wor"]
      assert a.scan(/(...)/).map(&.[1]) == ["cru", "el ", "wor"]
      assert a.scan(/(..)(..)/).map { |m| {m[1], m[2]} } == [{"cr", "ue"}, {"l ", "wo"}]
    end

    it "does with block" do
      a = "foo goo"
      i = 0
      a.scan(/\w(o+)/) do |match|
        case i
        when 0
          assert match[0] == "foo"
          assert match[1] == "oo"
        when 1
          assert match[0] == "goo"
          assert match[1] == "oo"
        else
          fail "expected two matches"
        end
        i += 1
      end
    end

    it "does with utf-8" do
      a = "こん こん"
      assert a.scan(/こ/).map(&.[0]) == ["こ", "こ"]
    end

    it "works when match is empty" do
      r = %r([\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*))
      assert "hello".scan(r).map(&.[0]) == ["hello", ""]
    end

    it "works with strings with block" do
      res = [] of String
      "bla bla ablf".scan("bl") { |s| res << s }
      assert res == ["bl", "bl", "bl"]
    end

    it "works with strings" do
      assert "bla bla ablf".scan("bl") == ["bl", "bl", "bl"]
      assert "hello".scan("world") == [] of String
      assert "bbb".scan("bb") == ["bb"]
      assert "ⓧⓧⓧ".scan("ⓧⓧ") == ["ⓧⓧ"]
      assert "ⓧ".scan("ⓧ") == ["ⓧ"]
      assert "ⓧ ⓧ ⓧ".scan("ⓧ") == ["ⓧ", "ⓧ", "ⓧ"]
      assert "".scan("") == [] of String
      assert "a".scan("") == [] of String
      assert "".scan("a") == [] of String
    end

    it "does with number and string" do
      assert "1ab4".scan(/\d+/).map(&.[0]) == ["1", "4"]
    end
  end

  it "has match" do
    assert "FooBar".match(/oo/).not_nil![0] == "oo"
  end

  it "matches with position" do
    assert "こんにちは".match(/./, 1).not_nil![0] == "ん"
  end

  it "matches empty string" do
    match = "".match(/.*/).not_nil!
    assert match.size == 0
    assert match[0] == ""
  end

  it "has size (same as size)" do
    assert "テスト".size == 3
  end

  describe "count" do
    it { assert "hello world".count("lo") == 5 }
    it { assert "hello world".count("lo", "o") == 2 }
    it { assert "hello world".count("hello", "^l") == 4 }
    it { assert "hello world".count("ej-m") == 4 }
    it { assert "hello^world".count("\\^aeiou") == 4 }
    it { assert "hello-world".count("a\\-eo") == 4 }
    it { assert "hello world\\r\\n".count("\\") == 2 }
    it { assert "hello world\\r\\n".count("\\A") == 0 }
    it { assert "hello world\\r\\n".count("X-\\w") == 3 }
    it { assert "aabbcc".count('a') == 2 }
    it { assert "aabbcc".count { |c| ['a', 'b'].includes?(c) } == 4 }
  end

  describe "squeeze" do
    it { assert "aaabbbccc".squeeze { |c| ['a', 'b'].includes?(c) } == "abccc" }
    it { assert "aaabbbccc".squeeze { |c| ['a', 'c'].includes?(c) } == "abbbc" }
    it { assert "a       bbb".squeeze == "a b" }
    it { assert "a    bbb".squeeze(' ') == "a bbb" }
    it { assert "aaabbbcccddd".squeeze("b-d") == "aaabcd" }
  end

  describe "ljust" do
    it { assert "123".ljust(2) == "123" }
    it { assert "123".ljust(5) == "123  " }
    it { assert "12".ljust(7, '-') == "12-----" }
    it { assert "12".ljust(7, 'あ') == "12あああああ" }
  end

  describe "rjust" do
    it { assert "123".rjust(2) == "123" }
    it { assert "123".rjust(5) == "  123" }
    it { assert "12".rjust(7, '-') == "-----12" }
    it { assert "12".rjust(7, 'あ') == "あああああ12" }
  end

  describe "succ" do
    it "returns an empty string for empty strings" do
      assert "".succ == ""
    end

    it "returns the successor by increasing the rightmost alphanumeric (digit => digit, letter => letter with same case)" do
      assert "abcd".succ == "abce"
      assert "THX1138".succ == "THX1139"

      assert "<<koala>>".succ == "<<koalb>>"
      assert "==A??".succ == "==B??"
    end

    it "increases non-alphanumerics (via ascii rules) if there are no alphanumerics" do
      assert "***".succ == "**+"
      assert "**`".succ == "**a"
    end

    it "increases the next best alphanumeric (jumping over non-alphanumerics) if there is a carry" do
      assert "dz".succ == "ea"
      assert "HZ".succ == "IA"
      assert "49".succ == "50"

      assert "izz".succ == "jaa"
      assert "IZZ".succ == "JAA"
      assert "699".succ == "700"

      assert "6Z99z99Z".succ == "7A00a00A"

      assert "1999zzz".succ == "2000aaa"
      assert "NZ/[]ZZZ9999".succ == "OA/[]AAA0000"
    end

    it "adds an additional character (just left to the last increased one) if there is a carry and no character left to increase" do
      assert "z".succ == "aa"
      assert "Z".succ == "AA"
      assert "9".succ == "10"

      assert "zz".succ == "aaa"
      assert "ZZ".succ == "AAA"
      assert "99".succ == "100"

      assert "9Z99z99Z".succ == "10A00a00A"

      assert "ZZZ9999".succ == "AAAA0000"
      assert "/[]ZZZ9999".succ == "/[]AAAA0000"
      assert "Z/[]ZZZ9999".succ == "AA/[]AAA0000"
    end
  end

  it "uses sprintf from top-level" do
    assert sprintf("Hello %d world", 123) == "Hello 123 world"
    assert sprintf("Hello %d world", [123]) == "Hello 123 world"
  end

  it "formats floats (#1562)" do
    assert sprintf("%12.2f %12.2f %6.2f %.2f" % {2.0, 3.0, 4.0, 5.0}) == "        2.00         3.00   4.00 5.00"
  end

  it "gets each_char iterator" do
    iter = "abc".each_char
    assert iter.next == 'a'
    assert iter.next == 'b'
    assert iter.next == 'c'
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 'a'
  end

  it "gets each_char with empty string" do
    iter = "".each_char
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next.is_a?(Iterator::Stop)
  end

  it "cycles chars" do
    assert "abc".each_char.cycle.first(8).join == "abcabcab"
  end

  it "gets each_byte iterator" do
    iter = "abc".each_byte
    assert iter.next == 'a'.ord
    assert iter.next == 'b'.ord
    assert iter.next == 'c'.ord
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 'a'.ord
  end

  it "cycles bytes" do
    assert "abc".each_byte.cycle.first(8).join == "9798999798999798"
  end

  it "gets lines" do
    assert "foo".lines == ["foo"]
    assert "foo\nbar\nbaz\n".lines == ["foo\n", "bar\n", "baz\n"]
  end

  it "gets each_line" do
    lines = [] of String
    "foo\n\nbar\nbaz\n".each_line do |line|
      lines << line
    end
    assert lines == ["foo\n", "\n", "bar\n", "baz\n"]
  end

  it "gets each_line iterator" do
    iter = "foo\nbar\nbaz\n".each_line
    assert iter.next == "foo\n"
    assert iter.next == "bar\n"
    assert iter.next == "baz\n"
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == "foo\n"
  end

  it "has yields to each_codepoint" do
    codepoints = [] of Int32
    "ab☃".each_codepoint do |codepoint|
      codepoints << codepoint
    end
    assert codepoints == [97, 98, 9731]
  end

  it "has the each_codepoint iterator" do
    iter = "ab☃".each_codepoint
    assert iter.next == 97
    assert iter.next == 98
    assert iter.next == 9731
  end

  it "has codepoints" do
    assert "ab☃".codepoints == [97, 98, 9731]
  end

  it "gets size of \0 string" do
    assert "\0\0".size == 2
  end

  describe "char_index_to_byte_index" do
    it "with ascii" do
      assert "foo".char_index_to_byte_index(0) == 0
      assert "foo".char_index_to_byte_index(1) == 1
      assert "foo".char_index_to_byte_index(2) == 2
      assert "foo".char_index_to_byte_index(3) == 3
      assert "foo".char_index_to_byte_index(4).nil?
    end

    it "with utf-8" do
      assert "これ".char_index_to_byte_index(0) == 0
      assert "これ".char_index_to_byte_index(1) == 3
      assert "これ".char_index_to_byte_index(2) == 6
      assert "これ".char_index_to_byte_index(3).nil?
    end
  end

  describe "byte_index_to_char_index" do
    it "with ascii" do
      assert "foo".byte_index_to_char_index(0) == 0
      assert "foo".byte_index_to_char_index(1) == 1
      assert "foo".byte_index_to_char_index(2) == 2
      assert "foo".byte_index_to_char_index(3) == 3
      assert "foo".byte_index_to_char_index(4).nil?
    end

    it "with utf-8" do
      assert "これ".byte_index_to_char_index(0) == 0
      assert "これ".byte_index_to_char_index(3) == 1
      assert "これ".byte_index_to_char_index(6) == 2
      assert "これ".byte_index_to_char_index(7).nil?
      assert "これ".byte_index_to_char_index(1).nil?
    end
  end

  context "%" do
    it "substitutes one placeholder" do
      res = "change %{this}" % {"this" => "nothing"}
      assert res == "change nothing"

      res = "change %{this}" % {this: "nothing"}
      assert res == "change nothing"
    end

    it "substitutes multiple placeholder" do
      res = "change %{this} and %{more}" % {"this" => "nothing", "more" => "something"}
      assert res == "change nothing and something"

      res = "change %{this} and %{more}" % {this: "nothing", more: "something"}
      assert res == "change nothing and something"
    end

    it "throws an error when the key is not found" do
      expect_raises KeyError do
        "change %{this}" % {"that" => "wrong key"}
      end

      expect_raises KeyError do
        "change %{this}" % {that: "wrong key"}
      end
    end

    it "raises if expecting hash or named tuple but not given" do
      expect_raises(ArgumentError, "one hash or named tuple required") do
        "change %{this}" % "this"
      end
    end

    it "raises on unbalanced curly" do
      expect_raises(ArgumentError, "malformed name - unmatched parenthesis") do
        "change %{this" % {"this" => 1}
      end
    end

    it "applies formatting to %<...> placeholder" do
      res = "change %<this>.2f" % {"this" => 23.456}
      assert res == "change 23.46"

      res = "change %<this>.2f" % {this: 23.456}
      assert res == "change 23.46"
    end
  end

  it "raises if string capacity is negative" do
    expect_raises(ArgumentError, "negative capacity") do
      String.new(-1) { |buf| {0, 0} }
    end
  end

  it "raises if capacity too big on new with UInt32::MAX" do
    expect_raises(ArgumentError, "capacity too big") do
      String.new(UInt32::MAX) { {0, 0} }
    end
  end

  it "raises if capacity too big on new with UInt64::MAX" do
    expect_raises(ArgumentError, "capacity too big") do
      String.new(UInt64::MAX) { {0, 0} }
    end
  end

  it "compares non-case insensitive" do
    assert "fo".compare("foo") == -1
    assert "foo".compare("fo") == 1
    assert "foo".compare("foo") == 0
    assert "foo".compare("fox") == -1
    assert "fox".compare("foo") == 1
    assert "foo".compare("Foo") == 1
  end

  it "compares case insensitive" do
    assert "fo".compare("FOO", case_insensitive: true) == -1
    assert "foo".compare("FO", case_insensitive: true) == 1
    assert "foo".compare("FOO", case_insensitive: true) == 0
    assert "foo".compare("FOX", case_insensitive: true) == -1
    assert "fox".compare("FOO", case_insensitive: true) == 1
    assert "fo\u{0000}".compare("FO", case_insensitive: true) == 1
  end

  it "raises if String.build negative capacity" do
    expect_raises(ArgumentError, "negative capacity") do
      String.build(-1) { }
    end
  end

  it "raises if String.build capacity too big" do
    expect_raises(ArgumentError, "capacity too big") do
      String.build(UInt32::MAX) { }
    end
  end

  describe "encode" do
    it "encodes" do
      bytes = "Hello".encode("UCS-2LE")
      assert bytes.to_a == [72, 0, 101, 0, 108, 0, 108, 0, 111, 0]
    end

    it "raises if wrong encoding" do
      expect_raises ArgumentError, "invalid encoding: FOO" do
        "Hello".encode("FOO")
      end
    end

    it "raises if wrong encoding with skip" do
      expect_raises ArgumentError, "invalid encoding: FOO" do
        "Hello".encode("FOO", invalid: :skip)
      end
    end

    it "raises if illegal byte sequence" do
      expect_raises ArgumentError, "invalid multibyte sequence" do
        "ñ".encode("GB2312")
      end
    end

    it "doesn't raise on invalid byte sequence" do
      assert "好ñ是".encode("GB2312", invalid: :skip).to_a == [186, 195, 202, 199]
    end

    it "raises if incomplete byte sequence" do
      expect_raises ArgumentError, "incomplete multibyte sequence" do
        "好".byte_slice(0, 1).encode("GB2312")
      end
    end

    it "doesn't raise if incomplete byte sequence" do
      assert ("好".byte_slice(0, 1) + "是").encode("GB2312", invalid: :skip).to_a == [202, 199]
    end

    it "decodes" do
      bytes = "Hello".encode("UTF-16LE")
      assert String.new(bytes, "UTF-16LE") == "Hello"
    end

    it "decodes with skip" do
      bytes = Bytes[186, 195, 140, 202, 199]
      assert String.new(bytes, "GB2312", invalid: :skip) == "好是"
    end
  end

  it "inserts" do
    assert "bar".insert(0, "foo") == "foobar"
    assert "bar".insert(1, "foo") == "bfooar"
    assert "bar".insert(2, "foo") == "bafoor"
    assert "bar".insert(3, "foo") == "barfoo"

    assert "bar".insert(-1, "foo") == "barfoo"
    assert "bar".insert(-2, "foo") == "bafoor"

    assert "ともだち".insert(0, "ねこ") == "ねこともだち"
    assert "ともだち".insert(1, "ねこ") == "とねこもだち"
    assert "ともだち".insert(2, "ねこ") == "ともねこだち"
    assert "ともだち".insert(4, "ねこ") == "ともだちねこ"

    assert "ともだち".insert(0, 'ね') == "ねともだち"
    assert "ともだち".insert(1, 'ね') == "とねもだち"
    assert "ともだち".insert(2, 'ね') == "ともねだち"
    assert "ともだち".insert(4, 'ね') == "ともだちね"

    assert "ともだち".insert(-1, 'ね') == "ともだちね"
    assert "ともだち".insert(-2, 'ね') == "ともだねち"

    expect_raises(IndexError) { "bar".insert(4, "foo") }
    expect_raises(IndexError) { "bar".insert(-5, "foo") }
    expect_raises(IndexError) { "bar".insert(4, 'f') }
    expect_raises(IndexError) { "bar".insert(-5, 'f') }

    assert "barbar".insert(0, "foo").size == 9
    assert "ともだち".insert(0, "ねこ").size == 6
  end

  it "dups" do
    string = "foo"
    dup = string.dup
    assert string.same?(dup)
  end

  it "clones" do
    string = "foo"
    clone = string.clone
    assert string.same?(clone)
  end

  it "#at" do
    assert "foo".at(0) == 'f'
    assert "foo".at(4) { 'x' } == 'x'

    expect_raises(IndexError) do
      "foo".at(4)
    end
  end
end
