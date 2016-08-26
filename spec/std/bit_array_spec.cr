require "spec"
require "bit_array"

describe "BitArray" do
  it "has size" do
    ary = BitArray.new(100)
    assert ary.size == 100
  end

  it "is initially empty" do
    ary = BitArray.new(100)
    100.times do |i|
      assert ary[i] == false
    end
  end

  it "sets first bit to true" do
    ary = BitArray.new(100)
    ary[0] = true
    assert ary[0] == true
  end

  it "sets second bit to true" do
    ary = BitArray.new(100)
    ary[1] = true
    assert ary[1] == true
  end

  it "sets first bit to false" do
    ary = BitArray.new(100)
    ary[0] = true
    ary[0] = false
    assert ary[0] == false
  end

  it "sets second bit to false" do
    ary = BitArray.new(100)
    ary[1] = true
    ary[1] = false
    assert ary[1] == false
  end

  it "sets last bit to true with negative index" do
    ary = BitArray.new(100)
    ary[-1] = true
    assert ary[-1] == true
    assert ary[99] == true
  end

  it "toggles a bit" do
    ary = BitArray.new(32)
    assert ary[3] == false

    ary.toggle(3)
    assert ary[3] == true

    ary.toggle(3)
    assert ary[3] == false
  end

  it "inverts all bits" do
    ary = BitArray.new(100)
    assert ary.none? == true

    ary.invert
    assert ary.all? == true

    ary[50] = false
    ary[33] = false
    assert ary.count { |b| b } == 98

    ary.invert
    assert ary.count { |b| b } == 2
  end

  it "raises when out of bounds" do
    ary = BitArray.new(10)
    expect_raises IndexError do
      ary[10] = true
    end
  end

  it "does to_s and inspect" do
    ary = BitArray.new(8)
    ary[0] = true
    ary[2] = true
    ary[4] = true
    assert ary.to_s == "BitArray[10101000]"
    assert ary.inspect == "BitArray[10101000]"
  end

  it "initializes with true by default" do
    ary = BitArray.new(64, true)
    ary.size.times { |i| assert ary[i] == true }
  end

  it "reads bits from slice" do
    ary = BitArray.new(43) # 5 bytes 3 bits
    # 11010000_00000000_00001011_00000000_00000000_101xxxxx
    ary[0] = true
    ary[1] = true
    ary[3] = true
    ary[20] = true
    ary[22] = true
    ary[23] = true
    ary[40] = true
    ary[42] = true
    slice = ary.to_slice

    assert slice.size == 6
    assert slice[0] == 0b00001011_u8
    assert slice[1] == 0b00000000_u8
    assert slice[2] == 0b11010000_u8
    assert slice[3] == 0b00000000_u8
    assert slice[4] == 0b00000000_u8
    assert slice[5] == 0b00000101_u8
  end

  it "read bits written from slice" do
    ary = BitArray.new(43) # 5 bytes 3 bits
    slice = ary.to_slice
    slice[0] = 0b10101010_u8
    slice[1] = 0b01010101_u8
    slice[5] = 0b11111101_u8
    ary.each_with_index do |e, i|
      assert e == {1, 3, 5, 7, 8, 10, 12, 14, 40, 42}.includes?(i)
    end
  end

  it "provides an iterator" do
    ary = BitArray.new(2)
    ary[0] = true
    ary[1] = false

    iter = ary.each
    assert iter.next == true
    assert iter.next == false
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == true

    iter.rewind
    assert iter.cycle.first(3).to_a == [true, false, true]
  end

  it "provides an index iterator" do
    ary = BitArray.new(2)

    iter = ary.each_index
    assert iter.next == 0
    assert iter.next == 1
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 0
  end

  it "provides a reverse iterator" do
    ary = BitArray.new(2)
    ary[0] = true
    ary[1] = false

    iter = ary.reverse_each
    assert iter.next == false
    assert iter.next == true
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == false
  end
end
