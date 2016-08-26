require "spec"

describe "StaticArray" do
  it "creates with new" do
    a = StaticArray(Int32, 3).new 0
    assert a.size == 3
  end

  it "creates with new and value" do
    a = StaticArray(Int32, 3).new 1
    assert a.size == 3
    assert a[0] == 1
    assert a[1] == 1
    assert a[2] == 1
  end

  it "creates with new and block" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    assert a.size == 3
    assert a[0] == 1
    assert a[1] == 2
    assert a[2] == 3
  end

  it "raises index out of bounds on read" do
    a = StaticArray(Int32, 3).new 0
    expect_raises IndexError do
      a[4]
    end
  end

  it "raises index out of bounds on write" do
    a = StaticArray(Int32, 3).new 0
    expect_raises IndexError do
      a[4] = 1
    end
  end

  it "allows using negative indices" do
    a = StaticArray(Int32, 3).new 0
    a[-1] = 2
    assert a[-1] == 2
    assert a[2] == 2
  end

  describe "==" do
    it "compares empty" do
      assert (StaticArray(Int32, 0).new(0)) == StaticArray(Int32, 0).new(0)
      assert (StaticArray(Int32, 1).new(0)) != StaticArray(Int32, 0).new(0)
      assert (StaticArray(Int32, 0).new(0)) != StaticArray(Int32, 1).new(0)
    end

    it "compares elements" do
      a = StaticArray(Int32, 3).new { |i| i * 2 }
      assert a == StaticArray(Int32, 3).new { |i| i * 2 }
      assert a != StaticArray(Int32, 3).new { |i| i * 3 }
    end

    it "compares other" do
      assert (StaticArray(Int32, 0).new(0)) != nil
      assert (StaticArray(Int32, 3).new(0)) == StaticArray(Int8, 3).new(0_i8)
    end
  end

  describe "values_at" do
    it "returns the given indexes" do
      assert StaticArray(Int32, 4).new { |i| i + 1 }.values_at(1, 0, 2) == {2, 1, 3}
    end

    it "raises when passed an invalid index" do
      expect_raises IndexError do
        StaticArray(Int32, 1).new { |i| i + 1 }.values_at(10)
      end
    end
  end

  it "does to_s" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    assert a.to_s == "StaticArray[1, 2, 3]"
  end

  it "shuffles" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    a.shuffle!

    assert (a[0] + a[1] + a[2]) == 6

    3.times do |i|
      assert a.includes?(i + 1) == true
    end
  end

  it "shuffles with a seed" do
    a = StaticArray(Int32, 10).new { |i| i + 1 }
    b = StaticArray(Int32, 10).new { |i| i + 1 }
    a.shuffle!(Random.new(42))
    b.shuffle!(Random.new(42))

    10.times do |i|
      assert a[i] == b[i]
    end
  end

  it "reverse" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    a.reverse!
    assert a[0] == 3
    assert a[1] == 2
    assert a[2] == 1
  end

  it "maps!" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    a.map! { |i| i + 1 }
    assert a[0] == 2
    assert a[1] == 3
    assert a[2] == 4
  end

  it "updates value" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    a.update(1) { |x| x * 2 }
    assert a[0] == 1
    assert a[1] == 4
    assert a[2] == 3
  end

  it "clones" do
    a = StaticArray(Array(Int32), 1).new { |i| [1] }
    b = a.clone
    assert b[0] == a[0]
    assert !b[0].same?(a[0])
  end

  it "iterates with each" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    iter = a.each
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next == 3
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1

    iter.rewind
    assert iter.cycle.first(5).to_a == [1, 2, 3, 1, 2]
  end

  it "iterates with reverse each" do
    a = StaticArray(Int32, 3).new { |i| i + 1 }
    iter = a.reverse_each
    assert iter.next == 3
    assert iter.next == 2
    assert iter.next == 1
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 3

    iter.rewind
    assert iter.cycle.first(5).to_a == [3, 2, 1, 3, 2]
  end
end
