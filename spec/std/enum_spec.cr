require "spec"

enum SpecEnum : Int8
  One
  Two
  Three
end

enum SpecEnum2
  FourtyTwo
  FOURTY_FOUR
end

@[Flags]
enum SpecEnumFlags
  One
  Two
  Three
end

describe Enum do
  describe "to_s" do
    it "for simple enum" do
      assert SpecEnum::One.to_s == "One"
      assert SpecEnum::Two.to_s == "Two"
      assert SpecEnum::Three.to_s == "Three"
    end

    it "for flags enum" do
      assert SpecEnumFlags::None.to_s == "None"
      assert SpecEnumFlags::All.to_s == "One, Two, Three"
      assert (SpecEnumFlags::One | SpecEnumFlags::Two).to_s == "One, Two"
    end
  end

  it "gets value" do
    assert SpecEnum::Two.value == 1
    assert SpecEnum::Two.value.is_a?(Int8)
  end

  it "gets value with to_i" do
    assert SpecEnum::Two.to_i == 1
    assert SpecEnum::Two.to_i.is_a?(Int32)

    assert SpecEnum::Two.to_i64 == 1
    assert SpecEnum::Two.to_i64.is_a?(Int64)
  end

  it "does +" do
    assert (SpecEnum::One + 1) == SpecEnum::Two
  end

  it "does -" do
    assert (SpecEnum::Two - 1) == SpecEnum::One
  end

  it "sorts" do
    assert [SpecEnum::Three, SpecEnum::One, SpecEnum::Two].sort == [SpecEnum::One, SpecEnum::Two, SpecEnum::Three]
  end

  it "does includes?" do
    assert (SpecEnumFlags::One | SpecEnumFlags::Two).includes?(SpecEnumFlags::One) == true
    assert (SpecEnumFlags::One | SpecEnumFlags::Two).includes?(SpecEnumFlags::Three) == false
  end

  describe "names" do
    it "for simple enum" do
      assert SpecEnum.names == %w(One Two Three)
    end

    it "for flags enum" do
      assert SpecEnumFlags.names == %w(One Two Three)
    end
  end

  describe "values" do
    it "for simple enum" do
      assert SpecEnum.values == [SpecEnum::One, SpecEnum::Two, SpecEnum::Three]
    end

    it "for flags enum" do
      assert SpecEnumFlags.values == [SpecEnumFlags::One, SpecEnumFlags::Two, SpecEnumFlags::Three]
    end
  end

  it "does from_value?" do
    assert SpecEnum.from_value?(0) == SpecEnum::One
    assert SpecEnum.from_value?(1) == SpecEnum::Two
    assert SpecEnum.from_value?(2) == SpecEnum::Three
    assert SpecEnum.from_value?(3).nil?
  end

  it "does from_value" do
    assert SpecEnum.from_value(0) == SpecEnum::One
    assert SpecEnum.from_value(1) == SpecEnum::Two
    assert SpecEnum.from_value(2) == SpecEnum::Three
    expect_raises { SpecEnum.from_value(3) }
  end

  it "has hash" do
    assert SpecEnum::Two.hash == 1.hash
  end

  it "parses" do
    assert SpecEnum.parse("Two") == SpecEnum::Two
    assert SpecEnum2.parse("FourtyTwo") == SpecEnum2::FourtyTwo
    assert SpecEnum2.parse("fourty_two") == SpecEnum2::FourtyTwo
    expect_raises(ArgumentError, "Unknown enum SpecEnum value: Four") { SpecEnum.parse("Four") }

    assert SpecEnum.parse("TWO") == SpecEnum::Two
    assert SpecEnum.parse("TwO") == SpecEnum::Two
    assert SpecEnum2.parse("FOURTY_TWO") == SpecEnum2::FourtyTwo

    assert SpecEnum2.parse("FOURTY_FOUR") == SpecEnum2::FOURTY_FOUR
    assert SpecEnum2.parse("fourty_four") == SpecEnum2::FOURTY_FOUR
    assert SpecEnum2.parse("FourtyFour") == SpecEnum2::FOURTY_FOUR
    assert SpecEnum2.parse("FOURTYFOUR") == SpecEnum2::FOURTY_FOUR
    assert SpecEnum2.parse("fourtyfour") == SpecEnum2::FOURTY_FOUR
  end

  it "parses?" do
    assert SpecEnum.parse?("Two") == SpecEnum::Two
    assert SpecEnum.parse?("Four").nil?
  end

  it "clones" do
    assert SpecEnum::One.clone == SpecEnum::One
  end
end
