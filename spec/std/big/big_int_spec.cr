require "spec"
require "big_int"

describe "BigInt" do
  it "creates with a value of zero" do
    assert BigInt.new.to_s == "0"
  end

  it "creates from signed ints" do
    assert BigInt.new(-1_i8).to_s == "-1"
    assert BigInt.new(-1_i16).to_s == "-1"
    assert BigInt.new(-1_i32).to_s == "-1"
    assert BigInt.new(-1_i64).to_s == "-1"
  end

  it "creates from unsigned ints" do
    assert BigInt.new(1_u8).to_s == "1"
    assert BigInt.new(1_u16).to_s == "1"
    assert BigInt.new(1_u32).to_s == "1"
    assert BigInt.new(1_u64).to_s == "1"
  end

  it "creates from string" do
    assert BigInt.new("12345678").to_s == "12345678"
  end

  it "raises if creates from string but invalid" do
    expect_raises ArgumentError, "invalid BigInt: 123 hello 456" do
      BigInt.new("123 hello 456")
    end
  end

  it "creates from float" do
    assert BigInt.new(12.3).to_s == "12"
  end

  it "compares" do
    assert 1.to_big_i == 1.to_big_i
    assert 1.to_big_i == 1
    assert 1.to_big_i == 1_u8

    assert [3.to_big_i, 2.to_big_i, 10.to_big_i, 4, 8_u8].sort == [2, 3, 4, 8, 10]
  end

  it "compares against float" do
    assert 1.to_big_i == 1.0
    assert 1.to_big_i == 1.0_f32
    assert 1.to_big_i != 1.1
    assert 1.0 == 1.to_big_i
    assert 1.0_f32 == 1.to_big_i
    assert 1.1 != 1.to_big_i

    assert [1.1, 1.to_big_i, 3.to_big_i, 2.2].sort == [1, 1.1, 2.2, 3]
  end

  it "adds" do
    assert (1.to_big_i + 2.to_big_i) == 3.to_big_i
    assert (1.to_big_i + 2) == 3.to_big_i
    assert (1.to_big_i + 2_u8) == 3.to_big_i
    assert (5.to_big_i + (-2_i64)) == 3.to_big_i

    assert (2 + 1.to_big_i) == 3.to_big_i
  end

  it "subs" do
    assert (5.to_big_i - 2.to_big_i) == 3.to_big_i
    assert (5.to_big_i - 2) == 3.to_big_i
    assert (5.to_big_i - 2_u8) == 3.to_big_i
    assert (5.to_big_i - (-2_i64)) == 7.to_big_i

    assert (5 - 1.to_big_i) == 4.to_big_i
    assert (-5 - 1.to_big_i) == -6.to_big_i
  end

  it "negates" do
    assert (-(-123.to_big_i)) == 123.to_big_i
  end

  it "multiplies" do
    assert (2.to_big_i * 3.to_big_i) == 6.to_big_i
    assert (2.to_big_i * 3) == 6.to_big_i
    assert (2.to_big_i * 3_u8) == 6.to_big_i
    assert (3 * 2.to_big_i) == 6.to_big_i
    assert (3_u8 * 2.to_big_i) == 6.to_big_i
  end

  it "gets absolute value" do
    assert (-10.to_big_i.abs) == 10.to_big_i
  end

  it "divides" do
    assert (10.to_big_i / 3.to_big_i) == 3.to_big_i
    assert (10.to_big_i / 3) == 3.to_big_i
    assert (10.to_big_i / -3) == -3.to_big_i
    assert (10 / 3.to_big_i) == 3.to_big_i
  end

  it "does modulo" do
    assert (10.to_big_i % 3.to_big_i) == 1.to_big_i
    assert (10.to_big_i % 3) == 1.to_big_i
    assert (10.to_big_i % -3) == 1.to_big_i
    assert (10 % 3.to_big_i) == 1.to_big_i
  end

  it "does bitwise and" do
    assert (123.to_big_i & 321) == 65
    assert (BigInt.new("96238761238973286532") & 86325735648) == 69124358272
  end

  it "does bitwise or" do
    assert (123.to_big_i | 4) == 127
    assert (BigInt.new("96238761238986532") | 8632573) == 96238761247506429
  end

  it "does bitwise xor" do
    assert (123.to_big_i ^ 50) == 73
    assert (BigInt.new("96238761238986532") ^ 8632573) == 96238761247393753
  end

  it "does bitwise not" do
    assert (~123) == -124

    a = BigInt.new("192623876123689865327")
    b = BigInt.new("-192623876123689865328")
    assert (~a) == b
  end

  it "does bitwise right shift" do
    assert (123.to_big_i >> 4) == 7
    assert (123456.to_big_i >> 8) == 482
  end

  it "does bitwise left shift" do
    assert (123.to_big_i << 4) == 1968
    assert (123456.to_big_i << 8) == 31604736
  end

  it "raises if divides by zero" do
    expect_raises DivisionByZero do
      10.to_big_i / 0.to_big_i
    end

    expect_raises DivisionByZero do
      10.to_big_i / 0
    end

    expect_raises DivisionByZero do
      10 / 0.to_big_i
    end
  end

  it "raises if mods by zero" do
    expect_raises DivisionByZero do
      10.to_big_i % 0.to_big_i
    end

    expect_raises DivisionByZero do
      10.to_big_i % 0
    end

    expect_raises DivisionByZero do
      10 % 0.to_big_i
    end
  end

  it "exponentiates" do
    result = (2.to_big_i ** 1000)
    assert result.is_a?(BigInt)
    assert result.to_s == "10715086071862673209484250490600018105614048117055336074437503883703510511249361224931983788156958581275946729175531468251871452856923140435984577574698574803934567774824230985421074605062371141877954182153046474983581941267398767559165543946077062914571196477686542167660429831652624386837205668069376"
  end

  it "does to_s in the given base" do
    a = BigInt.new("1234567890123456789")
    b = "1000100100010000100001111010001111101111010011000000100010101"
    c = "112210f47de98115"
    d = "128gguhuuj08l"
    assert a.to_s(2) == b
    assert a.to_s(16) == c
    assert a.to_s(32) == d
  end

  it "does gcd and lcm" do
    # 3 primes
    a = BigInt.new("48112959837082048697")
    b = BigInt.new("12764787846358441471")
    c = BigInt.new("36413321723440003717")
    abc = a * b * c
    a_17 = a * 17

    assert (abc * b).gcd(abc * c) == abc
    assert (abc * b).lcm(abc * c) == abc * b * c
    assert (abc * b).gcd(abc * c).is_a?(BigInt)

    assert (a_17).gcd(17) == 17
    assert (17).gcd(a_17) == 17
    assert (-a_17).gcd(17) == 17
    assert (-17).gcd(a_17) == 17

    assert (a_17).gcd(17).is_a?(Int::Unsigned)
    assert (17).gcd(a_17).is_a?(Int::Unsigned)

    assert (a_17).lcm(17) == a_17
    assert (17).lcm(a_17) == a_17
  end

  it "can use Number::[]" do
    a = BigInt[146, "3464", 97, "545"]
    b = [BigInt.new(146), BigInt.new(3464), BigInt.new(97), BigInt.new(545)]
    assert a == b
  end

  it "can be casted into other Number types" do
    big = BigInt.new(1234567890)
    assert big.to_i == 1234567890
    assert big.to_i8 == -46
    assert big.to_i16 == 722
    assert big.to_i32 == 1234567890
    assert big.to_i64 == 1234567890
    assert big.to_u == 1234567890
    assert big.to_u8 == 210
    assert big.to_u16 == 722
    assert big.to_u32 == 1234567890

    u64 = big.to_u64
    assert u64 == 1234567890
    assert u64.is_a?(UInt64)
  end

  {% if flag?(:x86_64) %}
    # For 32 bits libgmp can't seem to be able to do it
    it "can cast UInt64::MAX to UInt64 (#2264)" do
      assert BigInt.new(UInt64::MAX).to_u64 == UInt64::MAX
    end
  {% end %}

  it "does String#to_big_i" do
    assert "123456789123456789".to_big_i == BigInt.new("123456789123456789")
    assert "abcabcabcabcabcabc".to_big_i(base: 16) == BigInt.new("3169001976782853491388")
  end

  it "does popcount" do
    assert 5.to_big_i.popcount == 2
  end

  it "#hash" do
    hash = 5.to_big_i.hash
    assert hash == 5
    assert typeof(hash) == UInt64
  end

  it "clones" do
    x = 1.to_big_i
    assert x.clone == x
  end
end
