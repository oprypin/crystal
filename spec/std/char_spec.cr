require "spec"

describe "Char" do
  describe "upcase" do
    it { assert 'a'.upcase == 'A' }
    it { assert '1'.upcase == '1' }
  end

  describe "downcase" do
    it { assert 'A'.downcase == 'a' }
    it { assert '1'.downcase == '1' }
  end

  describe "succ" do
    it { assert 'a'.succ == 'b' }
    it { assert 'あ'.succ == 'ぃ' }
  end

  describe "pred" do
    it { assert 'b'.pred == 'a' }
    it { assert 'ぃ'.pred == 'あ' }
  end

  describe "uppercase?" do
    it { assert 'a'.uppercase? == false }
    it { assert 'A'.uppercase? == true }
    it { assert '1'.uppercase? == false }
    it { assert ' '.uppercase? == false }
  end

  describe "lowercase?" do
    it { assert 'a'.lowercase? == true }
    it { assert 'A'.lowercase? == false }
    it { assert '1'.lowercase? == false }
    it { assert ' '.lowercase? == false }
  end

  describe "alpha?" do
    it { assert 'a'.alpha? == true }
    it { assert 'A'.alpha? == true }
    it { assert '1'.alpha? == false }
    it { assert ' '.alpha? == false }
  end

  describe "alphanumeric?" do
    it { assert 'a'.alphanumeric? == true }
    it { assert 'A'.alphanumeric? == true }
    it { assert '1'.alphanumeric? == true }
    it { assert ' '.alphanumeric? == false }
  end

  describe "whitespace?" do
    [' ', '\t', '\n', '\v', '\f', '\r'].each do |char|
      it { assert char.whitespace? == true }
    end
    it { assert 'A'.whitespace? == false }
  end

  describe "hex?" do
    "0123456789abcdefABCDEF".each_char do |char|
      it { assert char.hex? == true }
    end
    ('g'..'z').each do |char|
      it { assert char.hex? == false }
    end
    [' ', '-', '\0'].each do |char|
      it { assert char.hex? == false }
    end
  end

  it "dumps" do
    assert 'a'.dump == "'a'"
    assert '\\'.dump == "'\\\\'"
    assert '\e'.dump == "'\\e'"
    assert '\f'.dump == "'\\f'"
    assert '\n'.dump == "'\\n'"
    assert '\r'.dump == "'\\r'"
    assert '\t'.dump == "'\\t'"
    assert '\v'.dump == "'\\v'"
    assert 'á'.dump == "'\\u{e1}'"
    assert '\u{81}'.dump == "'\\u{81}'"
  end

  it "inspects" do
    assert 'a'.inspect == "'a'"
    assert '\\'.inspect == "'\\\\'"
    assert '\e'.inspect == "'\\e'"
    assert '\f'.inspect == "'\\f'"
    assert '\n'.inspect == "'\\n'"
    assert '\r'.inspect == "'\\r'"
    assert '\t'.inspect == "'\\t'"
    assert '\v'.inspect == "'\\v'"
    assert 'á'.inspect == "'á'"
    assert '\u{81}'.inspect == "'\\u{81}'"
  end

  it "escapes" do
    assert '\b'.ord == 8
    assert '\t'.ord == 9
    assert '\n'.ord == 10
    assert '\v'.ord == 11
    assert '\f'.ord == 12
    assert '\r'.ord == 13
    assert '\e'.ord == 27
    assert '\''.ord == 39
    assert '\\'.ord == 92
  end

  it "escapes with octal" do
    assert '\0'.ord == 0
    assert '\3'.ord == 3
    assert '\23'.ord == (2 * 8) + 3
    assert '\123'.ord == (1 * 8 * 8) + (2 * 8) + 3
    assert '\033'.ord == (3 * 8) + 3
  end

  it "escapes with unicode" do
    assert '\u{12}'.ord == 1 * 16 + 2
    assert '\u{A}'.ord == 10
    assert '\u{AB}'.ord == 10 * 16 + 11
  end

  it "does to_i without a base" do
    ('0'..'9').each_with_index do |c, i|
      assert c.to_i == i
    end
    expect_raises(ArgumentError) { 'a'.to_i }
    assert 'a'.to_i?.nil?

    assert '1'.to_i8 == 1i8
    assert '1'.to_i16 == 1i16
    assert '1'.to_i32 == 1i32
    assert '1'.to_i64 == 1i64

    expect_raises(ArgumentError) { 'a'.to_i8 }
    expect_raises(ArgumentError) { 'a'.to_i16 }
    expect_raises(ArgumentError) { 'a'.to_i32 }
    expect_raises(ArgumentError) { 'a'.to_i64 }

    assert 'a'.to_i8?.nil?
    assert 'a'.to_i16?.nil?
    assert 'a'.to_i32?.nil?
    assert 'a'.to_i64?.nil?

    assert '1'.to_u8 == 1u8
    assert '1'.to_u16 == 1u16
    assert '1'.to_u32 == 1u32
    assert '1'.to_u64 == 1u64

    expect_raises(ArgumentError) { 'a'.to_u8 }
    expect_raises(ArgumentError) { 'a'.to_u16 }
    expect_raises(ArgumentError) { 'a'.to_u32 }
    expect_raises(ArgumentError) { 'a'.to_u64 }

    assert 'a'.to_u8?.nil?
    assert 'a'.to_u16?.nil?
    assert 'a'.to_u32?.nil?
    assert 'a'.to_u64?.nil?
  end

  it "does to_i with 16 base" do
    ('0'..'9').each_with_index do |c, i|
      assert c.to_i(16) == i
    end
    ('a'..'f').each_with_index do |c, i|
      assert c.to_i(16) == 10 + i
    end
    ('A'..'F').each_with_index do |c, i|
      assert c.to_i(16) == 10 + i
    end
    expect_raises(ArgumentError) { 'Z'.to_i(16) }
    assert 'Z'.to_i?(16).nil?
  end

  it "does to_i with base 36" do
    letters = ('0'..'9').each.chain(('a'..'z').each).chain(('A'..'Z').each)
    nums = (0..9).each.chain((10..35).each).chain((10..35).each)
    letters.zip(nums).each do |(letter, num)|
      assert letter.to_i(36) == num
    end
  end

  it "to_i rejects unsupported base (1)" do
    expect_raises ArgumentError, "invalid base 1" do
      '0'.to_i(1)
    end
  end

  it "to_i rejects unsupported base (37)" do
    expect_raises ArgumentError, "invalid base 37" do
      '0'.to_i(37)
    end
  end

  it "does to_f" do
    ('0'..'9').each.zip((0..9).each).each do |c, i|
      assert c.to_f == i.to_f
    end
    expect_raises(ArgumentError) { 'A'.to_f }
    assert '1'.to_f32 == 1.0f32
    assert '1'.to_f64 == 1.0f64
    assert 'a'.to_f?.nil?
    assert 'a'.to_f32?.nil?
    assert 'a'.to_f64?.nil?
  end

  it "does ord for multibyte char" do
    assert '日'.ord == 26085
  end

  it "does to_s for single-byte char" do
    assert 'a'.to_s == "a"
  end

  it "does to_s for multibyte char" do
    assert '日'.to_s == "日"
  end

  describe "index" do
    it { assert "foo".index('o') == 1 }
    it { assert "foo".index('x').nil? }
  end

  it "does <=>" do
    assert ('a' <=> 'b') < 0
    assert ('a' <=> 'a') == 0
    assert ('b' <=> 'a') > 0
  end

  describe "+" do
    it "does for both ascii" do
      str = 'f' + "oo"
      assert str.bytesize == 3
      assert str.@length == 3
      assert str == "foo"
    end

    it "does for both unicode" do
      str = '青' + "旅路"
      assert str.@length == 3
      assert str == "青旅路"
    end
  end

  describe "bytesize" do
    it "does for ascii" do
      assert 'a'.bytesize == 1
    end

    it "does for unicode" do
      assert '青'.bytesize == 3
    end

    it "raises on codepoint bigger than 0x10ffff" do
      expect_raises InvalidByteSequenceError do
        (0x10ffff + 1).unsafe_chr.bytesize
      end
    end
  end

  describe "in_set?" do
    it { assert 'a'.in_set?("a") == true }
    it { assert 'a'.in_set?("b") == false }
    it { assert 'a'.in_set?("a-c") == true }
    it { assert 'b'.in_set?("a-c") == true }
    it { assert 'c'.in_set?("a-c") == true }
    it { assert 'c'.in_set?("a-bc") == true }
    it { assert 'b'.in_set?("a-bc") == true }
    it { assert 'd'.in_set?("a-c") == false }
    it { assert 'b'.in_set?("^a-c") == false }
    it { assert 'd'.in_set?("^a-c") == true }
    it { assert 'a'.in_set?("ab-c") == true }
    it { assert 'a'.in_set?("\\^ab-c") == true }
    it { assert '^'.in_set?("\\^ab-c") == true }
    it { assert '^'.in_set?("a^b-c") == true }
    it { assert '^'.in_set?("ab-c^") == true }
    it { assert '^'.in_set?("a0-^") == true }
    it { assert '^'.in_set?("^-c") == true }
    it { assert '^'.in_set?("a^-c") == true }
    it { assert '\\'.in_set?("ab-c\\") == true }
    it { assert '\\'.in_set?("a\\b-c") == false }
    it { assert '\\'.in_set?("a0-\\c") == true }
    it { assert '\\'.in_set?("a\\-c") == false }
    it { assert '-'.in_set?("a-c") == false }
    it { assert '-'.in_set?("a-c") == false }
    it { assert '-'.in_set?("a\\-c") == true }
    it { assert '-'.in_set?("-c") == true }
    it { assert '-'.in_set?("a-") == true }
    it { assert '-'.in_set?("^-c") == false }
    it { assert '-'.in_set?("^\\-c") == false }
    it { assert 'b'.in_set?("^\\-c") == true }
    it { assert '-'.in_set?("a^-c") == false }
    it { assert 'a'.in_set?("a", "ab") == true }
    it { assert 'a'.in_set?("a", "^b") == true }
    it { assert 'a'.in_set?("a", "b") == false }
    it { assert 'a'.in_set?("ab", "ac", "ad") == true }

    it "rejects invalid ranges" do
      expect_raises do
        'a'.in_set?("c-a")
      end
    end
  end

  it "raises on codepoint bigger than 0x10ffff when doing each_byte" do
    expect_raises InvalidByteSequenceError do
      (0x10ffff + 1).unsafe_chr.each_byte { |b| }
    end
  end

  it "does bytes" do
    assert '\u{FF}'.bytes == [195, 191]
  end

  it "#===(:Int)" do
    assert ('c'.ord) == 99
    assert ('c' === 99_u8) == true
    assert ('c' === 99) == true
    assert ('z' === 99) == false

    assert ('酒'.ord) == 37202
    assert ('酒' === 37202) == true
  end

  it "does digit?" do
    256.times do |i|
      chr = i.chr
      assert ("01".chars.includes?(chr) == chr.digit?(2)) == true
      assert ("01234567".chars.includes?(chr) == chr.digit?(8)) == true
      assert ("0123456789".chars.includes?(chr) == chr.digit?) == true
      assert ("0123456789".chars.includes?(chr) == chr.digit?(10)) == true
      assert ("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes?(chr) == chr.digit?(36)) == true
      unless 2 <= i <= 36
        expect_raises ArgumentError do
          '0'.digit?(i)
        end
      end
    end
  end

  it "does control?" do
    assert 'ù'.control? == false
    assert 'a'.control? == false
    assert '\u0019'.control? == true
  end

  it "does ascii?" do
    assert 'a'.ascii? == true
    assert 127.chr.ascii? == true
    assert 128.chr.ascii? == false
    assert '酒'.ascii? == false
  end

  describe "clone" do
    it { assert 'a'.clone == 'a' }
  end
end
