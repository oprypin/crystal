require "spec"

describe "Number" do
  describe "significant" do
    it "10 base " do
      assert 1234.567.significant(1) == 1000
      assert 1234.567.significant(2) == 1200
      assert 1234.567.significant(3) == 1230
      assert 1234.567.significant(4) == 1235
      assert 1234.567.significant(5).close?(1234.6, 1e-7)
      assert 1234.567.significant(6) == 1234.57
      assert 1234.567.significant(7) == 1234.567
    end

    it "2 base " do
      assert -1763.116.significant(2, base = 2) == -1536.0
      assert 753.155.significant(3, base = 2) == 768.0
      assert 15.159.significant(1, base = 2) == 16.0
    end

    it "8 base " do
      assert -1763.116.significant(2, base = 8) == -1792.0
      assert 753.155.significant(3, base = 8) == 752.0
      assert 15.159.significant(1, base = 8) == 16.0
    end

    it "preserves type" do
      assert 123.significant(2) == 120
      assert 123.significant(2).is_a?(Int32)
    end
  end

  describe "round" do
    it "10 base " do
      assert -1763.116.round(2) == -1763.12
      assert 753.155.round(2) == 753.16
      assert 15.151.round(2) == 15.15
    end

    it "2 base " do
      assert -1763.116.round(2, base = 2) == -1763.0
      assert 753.155.round(2, base = 2) == 753.25
      assert 15.159.round(2, base = 2) == 15.25
    end

    it "8 base " do
      assert -1763.116.round(2, base = 8) == -1763.109375
      assert 753.155.round(1, base = 8) == 753.125
      assert 15.159.round(0, base = 8) == 15.0
    end

    it "preserves type" do
      assert 123.round(2) == 123
      assert 123.round(2).is_a?(Int32)
    end
  end

  describe "clamp" do
    it "clamps integers" do
      assert -5.clamp(-10, 100) == -5
      assert -5.clamp(10, 100) == 10
      assert 5.clamp(10, 100) == 10
      assert 50.clamp(10, 100) == 50
      assert 500.clamp(10, 100) == 100

      assert 50.clamp(10..100) == 50
    end

    it "clamps floats" do
      assert -5.5.clamp(-10.1, 100.1) == -5.5
      assert -5.5.clamp(10.1, 100.1) == 10.1
      assert 5.5.clamp(10.1, 100.1) == 10.1
      assert 50.5.clamp(10.1, 100.1) == 50.5
      assert 500.5.clamp(10.1, 100.1) == 100.1

      assert 50.5.clamp(10.1..100.1) == 50.5
    end

    it "fails with an exclusive range" do
      expect_raises(ArgumentError) do
        range = Range.new(1, 2, exclusive: true)
        5.clamp(range)
      end
    end
  end

  it "gives the absolute value" do
    assert 123.abs == 123
    assert -123.abs == 123
  end

  it "gives the square of a value" do
    assert 2.abs2 == 4
    assert -2.abs2 == 4
    assert 2.5.abs2 == 6.25
    assert -2.5.abs2 == 6.25
  end

  it "gives the sign" do
    assert 123.sign == 1
    assert -123.sign == -1
    assert 0.sign == 0
  end

  it "divides and calculs the modulo" do
    assert 10.divmod(2) == {5, 0}
    assert 10.divmod(-2) == {-5, 0}
    assert 11.divmod(-2) == {-5, -1}
  end

  it "compare the numbers" do
    assert 10.<=>(10) == 0
    assert 10.<=>(11) == -1
    assert 11.<=>(10) == 1
  end

  it "creates an array with [] and some elements" do
    ary = Int64[1, 2, 3]
    assert ary == [1, 2, 3]
    assert ary[0].is_a?(Int64)
  end

  it "creates an array with [] and no elements" do
    ary = Int64[]
    assert ary == [] of Int64
    ary << 1_i64
    assert ary == [1]
  end

  it "creates a slice" do
    slice = Int8.slice(1, 2, 300)
    assert slice.is_a?(Slice(Int8))
    assert slice.size == 3
    assert slice[0] == 1
    assert slice[1] == 2
    assert slice[2] == 300.to_u8
  end

  it "creates a static array" do
    ary = Int8.static_array(1, 2, 300)
    assert ary.is_a?(StaticArray(Int8, 3))
    assert ary.size == 3
    assert ary[0] == 1
    assert ary[1] == 2
    assert ary[2] == 300.to_u8
  end

  it "steps from int to float" do
    count = 0
    0.step(by: 0.1, limit: 0.3) do |x|
      assert typeof(x) == typeof(0.1)
      case count
      when 0 then assert x == 0.0
      when 1 then assert x == 0.1
      when 2 then assert x == 0.2
      end
      count += 1
    end
  end

  it "does step iterator" do
    iter = 0.step(by: 0.1, limit: 0.3)
    assert iter.next == 0.0
    assert iter.next == 0.1
    assert iter.next == 0.2
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 0.0
  end
end
