require "spec"
require "big_int"

private def to_s_with_io(num)
  String.build { |str| num.to_s(str) }
end

private def to_s_with_io(num, base, upcase = false)
  String.build { |str| num.to_s(base, str, upcase) }
end

describe "Int" do
  describe "**" do
    it "with positive Int32" do
      x = 2 ** 2
      assert x == 4
      assert x.is_a?(Int32)

      x = 2 ** 0
      assert x == 1
      assert x.is_a?(Int32)
    end

    it "with positive UInt8" do
      x = 2_u8 ** 2
      assert x == 4
      assert x.is_a?(UInt8)
    end

    it "raises with negative exponent" do
      expect_raises(ArgumentError, "cannot raise an integer to a negative integer power, use floats for that") do
        2 ** -1
      end
    end

    it "should work with large integers" do
      x = 51_i64 ** 11
      assert x == 6071163615208263051_i64
      assert x.is_a?(Int64)
    end

    describe "with float" do
      it { assert (2 ** 2.0).close?(4, 0.0001) }
      it { assert (2 ** 2.5_f32).close?(5.656854249492381, 0.0001) }
      it { assert (2 ** 2.5).close?(5.656854249492381, 0.0001) }
    end
  end

  describe "#===(:Char)" do
    it { assert (99 === 'c') == true }
    it { assert (99_u8 === 'c') == true }
    it { assert (99 === 'z') == false }
    it { assert (37202 === '酒') == true }
  end

  describe "divisible_by?" do
    it { assert 10.divisible_by?(5) == true }
    it { assert 10.divisible_by?(3) == false }
  end

  describe "even?" do
    it { assert 2.even? == true }
    it { assert 3.even? == false }
  end

  describe "odd?" do
    it { assert 2.odd? == false }
    it { assert 3.odd? == true }
  end

  describe "succ" do
    it { assert 8.succ == 9 }
    it { assert -2147483648.succ == -2147483647 }
    it { assert 2147483646.succ == 2147483647 }
  end

  describe "pred" do
    it { assert 9.pred == 8 }
    it { assert -2147483647.pred == -2147483648 }
    it { assert 2147483647.pred == 2147483646 }
  end

  describe "abs" do
    it "does for signed" do
      assert 1_i8.abs == 1_i8
      assert -1_i8.abs == 1_i8
      assert 1_i16.abs == 1_i16
      assert -1_i16.abs == 1_i16
      assert 1_i32.abs == 1_i32
      assert -1_i32.abs == 1_i32
      assert 1_i64.abs == 1_i64
      assert -1_i64.abs == 1_i64
    end

    it "does for unsigned" do
      assert 1_u8.abs == 1_u8
      assert 1_u16.abs == 1_u16
      assert 1_u32.abs == 1_u32
      assert 1_u64.abs == 1_u64
    end
  end

  describe "lcm" do
    it { assert 2.lcm(2) == 2 }
    it { assert 3.lcm(-7) == 21 }
    it { assert 4.lcm(6) == 12 }
    it { assert 0.lcm(2) == 0 }
    it { assert 2.lcm(0) == 0 }
  end

  describe "to_s in base" do
    it { assert 12.to_s(2) == "1100" }
    it { assert -12.to_s(2) == "-1100" }
    it { assert -123456.to_s(2) == "-11110001001000000" }
    it { assert 1234.to_s(16) == "4d2" }
    it { assert -1234.to_s(16) == "-4d2" }
    it { assert 1234.to_s(36) == "ya" }
    it { assert -1234.to_s(36) == "-ya" }
    it { assert 1234.to_s(16, upcase: true) == "4D2" }
    it { assert -1234.to_s(16, upcase: true) == "-4D2" }
    it { assert 1234.to_s(36, upcase: true) == "YA" }
    it { assert -1234.to_s(36, upcase: true) == "-YA" }
    it { assert 0.to_s(2) == "0" }
    it { assert 0.to_s(16) == "0" }
    it { assert 1.to_s(2) == "1" }
    it { assert 1.to_s(16) == "1" }
    it { assert 0.to_s(62) == "0" }
    it { assert 1.to_s(62) == "1" }
    it { assert 10.to_s(62) == "a" }
    it { assert 35.to_s(62) == "z" }
    it { assert 36.to_s(62) == "A" }
    it { assert 61.to_s(62) == "Z" }
    it { assert 62.to_s(62) == "10" }
    it { assert 97.to_s(62) == "1z" }
    it { assert 3843.to_s(62) == "ZZ" }

    it "raises on base 1" do
      expect_raises { 123.to_s(1) }
    end

    it "raises on base 37" do
      expect_raises { 123.to_s(37) }
    end

    it "raises on base 62 with upcase" do
      expect_raises { 123.to_s(62, upcase: true) }
    end

    it { assert to_s_with_io(12, 2) == "1100" }
    it { assert to_s_with_io(-12, 2) == "-1100" }
    it { assert to_s_with_io(-123456, 2) == "-11110001001000000" }
    it { assert to_s_with_io(1234, 16) == "4d2" }
    it { assert to_s_with_io(-1234, 16) == "-4d2" }
    it { assert to_s_with_io(1234, 36) == "ya" }
    it { assert to_s_with_io(-1234, 36) == "-ya" }
    it { assert to_s_with_io(1234, 16, upcase: true) == "4D2" }
    it { assert to_s_with_io(-1234, 16, upcase: true) == "-4D2" }
    it { assert to_s_with_io(1234, 36, upcase: true) == "YA" }
    it { assert to_s_with_io(-1234, 36, upcase: true) == "-YA" }
    it { assert to_s_with_io(0, 2) == "0" }
    it { assert to_s_with_io(0, 16) == "0" }
    it { assert to_s_with_io(1, 2) == "1" }
    it { assert to_s_with_io(1, 16) == "1" }
    it { assert to_s_with_io(0, 62) == "0" }
    it { assert to_s_with_io(1, 62) == "1" }
    it { assert to_s_with_io(10, 62) == "a" }
    it { assert to_s_with_io(35, 62) == "z" }
    it { assert to_s_with_io(36, 62) == "A" }
    it { assert to_s_with_io(61, 62) == "Z" }
    it { assert to_s_with_io(62, 62) == "10" }
    it { assert to_s_with_io(97, 62) == "1z" }
    it { assert to_s_with_io(3843, 62) == "ZZ" }

    it "raises on base 1 with io" do
      expect_raises { to_s_with_io(123, 1) }
    end

    it "raises on base 37 with io" do
      expect_raises { to_s_with_io(123, 37) }
    end

    it "raises on base 62 with upcase with io" do
      expect_raises { to_s_with_io(12, 62, upcase: true) }
    end
  end

  describe "bit" do
    it { assert 5.bit(0) == 1 }
    it { assert 5.bit(1) == 0 }
    it { assert 5.bit(2) == 1 }
    it { assert 5.bit(3) == 0 }
    it { assert 0.bit(63) == 0 }
    it { assert Int64::MAX.bit(63) == 0 }
    it { assert UInt64::MAX.bit(63) == 1 }
    it { assert UInt64::MAX.bit(64) == 0 }
  end

  describe "divmod" do
    it { assert 5.divmod(3) == {1, 2} }
  end

  describe "fdiv" do
    it { assert 1.fdiv(1) == 1.0 }
    it { assert 1.fdiv(2) == 0.5 }
    it { assert 1.fdiv(0.5) == 2.0 }
    it { assert 0.fdiv(1) == 0.0 }
    it { assert 1.fdiv(0) == 1.0/0.0 }
  end

  describe "~" do
    it { assert (~1) == -2 }
    it { assert (~1_u32) == 4294967294 }
  end

  describe ">>" do
    it { assert (8000 >> 1) == 4000 }
    it { assert (8000 >> 2) == 2000 }
    it { assert (8000 >> 32) == 0 }
    it { assert (8000 >> -1) == 16000 }
  end

  describe "<<" do
    it { assert (8000 << 1) == 16000 }
    it { assert (8000 << 2) == 32000 }
    it { assert (8000 << 32) == 0 }
    it { assert (8000 << -1) == 4000 }
  end

  describe "to" do
    it "does upwards" do
      a = 0
      1.to(3) { |i| a += i }
      assert a == 6
    end

    it "does downards" do
      a = 0
      4.to(2) { |i| a += i }
      assert a == 9
    end

    it "does when same" do
      a = 0
      2.to(2) { |i| a += i }
      assert a == 2
    end
  end

  describe "to_s" do
    it "does to_s for various int sizes" do
      assert 0.to_s == "0"
      assert 1.to_s == "1"

      assert 127_i8.to_s == "127"
      assert -128_i8.to_s == "-128"

      assert 32767_i16.to_s == "32767"
      assert -32768_i16.to_s == "-32768"

      assert 2147483647.to_s == "2147483647"
      assert -2147483648.to_s == "-2147483648"

      assert 9223372036854775807_i64.to_s == "9223372036854775807"
      assert -9223372036854775808_i64.to_s == "-9223372036854775808"

      assert 255_u8.to_s == "255"
      assert 65535_u16.to_s == "65535"
      assert 4294967295_u32.to_s == "4294967295"

      assert 18446744073709551615_u64.to_s == "18446744073709551615"
    end

    it "does to_s for various int sizes with IO" do
      assert to_s_with_io(0) == "0"
      assert to_s_with_io(1) == "1"

      assert to_s_with_io(127_i8) == "127"
      assert to_s_with_io(-128_i8) == "-128"

      assert to_s_with_io(32767_i16) == "32767"
      assert to_s_with_io(-32768_i16) == "-32768"

      assert to_s_with_io(2147483647) == "2147483647"
      assert to_s_with_io(-2147483648) == "-2147483648"

      assert to_s_with_io(9223372036854775807_i64) == "9223372036854775807"
      assert to_s_with_io(-9223372036854775808_i64) == "-9223372036854775808"

      assert to_s_with_io(255_u8) == "255"
      assert to_s_with_io(65535_u16) == "65535"
      assert to_s_with_io(4294967295_u32) == "4294967295"

      assert to_s_with_io(18446744073709551615_u64) == "18446744073709551615"
    end
  end

  describe "step" do
    it "steps through limit" do
      passed = false
      1.step(1) { |x| passed = true }
      fail "expected step to pass through 1" unless passed
    end
  end

  it "casts" do
    assert Int8.new(1).is_a?(Int8)
    assert Int8.new(1) == 1

    assert Int16.new(1).is_a?(Int16)
    assert Int16.new(1) == 1

    assert Int32.new(1).is_a?(Int32)
    assert Int32.new(1) == 1

    assert Int64.new(1).is_a?(Int64)
    assert Int64.new(1) == 1

    assert UInt8.new(1).is_a?(UInt8)
    assert UInt8.new(1) == 1

    assert UInt16.new(1).is_a?(UInt16)
    assert UInt16.new(1) == 1

    assert UInt32.new(1).is_a?(UInt32)
    assert UInt32.new(1) == 1

    assert UInt64.new(1).is_a?(UInt64)
    assert UInt64.new(1) == 1
  end

  it "raises when divides by zero" do
    expect_raises(DivisionByZero) { 1 / 0 }
    assert (4 / 2) == 2
  end

  it "raises when mods by zero" do
    expect_raises(DivisionByZero) { 1 % 0 }
    assert (4 % 2) == 0
  end

  it "gets times iterator" do
    iter = 3.times
    assert iter.next == 0
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 0
  end

  it "does %" do
    assert (7 % 5) == 2
    assert (-7 % 5) == 3

    assert (13 % -4) == -3
    assert (-13 % -4) == -1
  end

  it "does remainder" do
    assert 7.remainder(5) == 2
    assert -7.remainder(5) == -2

    assert 13.remainder(-4) == 1
    assert -13.remainder(-4) == -1
  end

  it "gets upto iterator" do
    iter = 1.upto(3)
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next == 3
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1
  end

  it "gets downto iterator" do
    iter = 3.downto(1)
    assert iter.next == 3
    assert iter.next == 2
    assert iter.next == 1
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 3
  end

  it "gets to iterator" do
    iter = 1.to(3)
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next == 3
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1
  end

  describe "#popcount" do
    it { assert 5_i8.popcount == 2 }
    it { assert 127_i8.popcount == 7 }
    it { assert -1_i8.popcount == 8 }
    it { assert -128_i8.popcount == 1 }

    it { assert 0_u8.popcount == 0 }
    it { assert 255_u8.popcount == 8 }

    it { assert 5_i16.popcount == 2 }
    it { assert -6_i16.popcount == 14 }
    it { assert 65535_u16.popcount == 16 }

    it { assert 0_i32.popcount == 0 }
    it { assert 2147483647_i32.popcount == 31 }
    it { assert 4294967295_u32.popcount == 32 }

    it { assert 5_i64.popcount == 2 }
    it { assert 9223372036854775807_i64.popcount == 63 }
    it { assert 18446744073709551615_u64.popcount == 64 }
  end

  it "compares signed vs. unsigned integers" do
    signed_ints = [Int8::MAX, Int16::MAX, Int32::MAX, Int64::MAX, Int8::MIN, Int16::MIN, Int32::MIN, Int64::MIN, 0_i8, 0_i16, 0_i32, 0_i64]
    unsigned_ints = [UInt8::MAX, UInt16::MAX, UInt32::MAX, UInt64::MAX, 0_u8, 0_u16, 0_u32, 0_u64]

    big_signed_ints = signed_ints.map &.to_big_i
    big_unsigned_ints = unsigned_ints.map &.to_big_i

    signed_ints.zip(big_signed_ints) do |si, bsi|
      unsigned_ints.zip(big_unsigned_ints) do |ui, bui|
        {% for op in %w(< <= > >=).map(&.id) %}
          if (si {{op}} ui) != (bsi {{op}} bui)
            fail "comparison of #{si} {{op}} #{ui} (#{si.class} {{op}} #{ui.class}) gave incorrect result"
          end
        {% end %}
      end
    end
  end

  it "clones" do
    [1_u8, 2_u16, 3_u32, 4_u64, 5_i8, 6_i16, 7_i32, 8_i64].each do |value|
      assert value.clone == value
    end
  end

  it "#chr" do
    assert 65.chr == 'A'

    expect_raises(ArgumentError, "#{0x10ffff + 1} out of char range") do
      (0x10ffff + 1).chr
    end
  end

  it "#unsafe_chr" do
    assert 65.unsafe_chr == 'A'
    assert (0x10ffff + 1).unsafe_chr.ord == 0x10ffff + 1
  end
end
