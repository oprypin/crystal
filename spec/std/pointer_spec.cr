require "spec"

private def reset(p1, p2)
  p1.value = 10
  p2.value = 20
end

describe "Pointer" do
  it "does malloc with value" do
    p1 = Pointer.malloc(4, 1)
    4.times do |i|
      assert p1[i] == 1
    end
  end

  it "does malloc with value from block" do
    p1 = Pointer.malloc(4) { |i| i }
    4.times do |i|
      assert p1[i] == i
    end
  end

  it "does index with count" do
    p1 = Pointer.malloc(4) { |i| i ** 2 }
    assert p1.to_slice(4).index(4) == 2
    assert p1.to_slice(4).index(5).nil?
  end

  describe "copy_from" do
    it "performs" do
      p1 = Pointer.malloc(4) { |i| i }
      p2 = Pointer.malloc(4) { 0 }
      p2.copy_from(p1, 4)
      4.times do |i|
        assert p2[0] == p1[0]
      end
    end

    it "raises on negative count" do
      p1 = Pointer.malloc(4, 0)
      expect_raises(ArgumentError, "negative count") do
        p1.copy_from(p1, -1)
      end
    end
  end

  describe "copy_to" do
    it "performs" do
      p1 = Pointer.malloc(4) { |i| i }
      p2 = Pointer.malloc(4) { 0 }
      p1.copy_to(p2, 4)
      4.times do |i|
        assert p2[0] == p1[0]
      end
    end

    it "raises on negative count" do
      p1 = Pointer.malloc(4, 0)
      expect_raises(ArgumentError, "negative count") do
        p1.copy_to(p1, -1)
      end
    end
  end

  describe "move_from" do
    it "performs with overlap right to left" do
      p1 = Pointer.malloc(4) { |i| i }
      (p1 + 1).move_from(p1 + 2, 2)
      assert p1[0] == 0
      assert p1[1] == 2
      assert p1[2] == 3
      assert p1[3] == 3
    end

    it "performs with overlap left to right" do
      p1 = Pointer.malloc(4) { |i| i }
      (p1 + 2).move_from(p1 + 1, 2)
      assert p1[0] == 0
      assert p1[1] == 1
      assert p1[2] == 1
      assert p1[3] == 2
    end

    it "raises on negative count" do
      p1 = Pointer.malloc(4, 0)
      expect_raises(ArgumentError, "negative count") do
        p1.move_from(p1, -1)
      end
    end
  end

  describe "move_to" do
    it "performs with overlap right to left" do
      p1 = Pointer.malloc(4) { |i| i }
      (p1 + 2).move_to(p1 + 1, 2)
      assert p1[0] == 0
      assert p1[1] == 2
      assert p1[2] == 3
      assert p1[3] == 3
    end

    it "performs with overlap left to right" do
      p1 = Pointer.malloc(4) { |i| i }
      (p1 + 1).move_to(p1 + 2, 2)
      assert p1[0] == 0
      assert p1[1] == 1
      assert p1[2] == 1
      assert p1[3] == 2
    end

    it "raises on negative count" do
      p1 = Pointer.malloc(4, 0)
      expect_raises(ArgumentError, "negative count") do
        p1.move_to(p1, -1)
      end
    end
  end

  describe "memcmp" do
    it do
      p1 = Pointer.malloc(4) { |i| i }
      p2 = Pointer.malloc(4) { |i| i }
      p3 = Pointer.malloc(4) { |i| i + 1 }

      assert p1.memcmp(p2, 4) == 0
      assert p1.memcmp(p3, 4) < 0
      assert p3.memcmp(p1, 4) > 0
    end
  end

  it "compares two pointers by address" do
    p1 = Pointer(Int32).malloc(1)
    p2 = Pointer(Int32).malloc(1)
    assert p1 == p1
    assert p1 != p2
    assert p1 != 1
  end

  it "does to_s" do
    assert Pointer(Int32).null.to_s == "Pointer(Int32).null"
    assert Pointer(Int32).new(1234_u64).to_s == "Pointer(Int32)@0x4d2"
  end

  it "creates from int" do
    assert Pointer(Int32).new(1234).address == 1234
  end

  it "shuffles!" do
    a = Pointer(Int32).malloc(3) { |i| i + 1 }
    a.shuffle!(3)

    assert (a[0] + a[1] + a[2]) == 6

    3.times do |i|
      assert a.to_slice(3).includes?(i + 1) == true
    end
  end

  it "maps!" do
    a = Pointer(Int32).malloc(3) { |i| i + 1 }
    a.map!(3) { |i| i + 1 }
    assert a[0] == 2
    assert a[1] == 3
    assert a[2] == 4
  end

  it "raises if mallocs negative size" do
    expect_raises(ArgumentError) { Pointer.malloc(-1, 0) }
  end

  it "copies/move with different types" do
    p1 = Pointer(Int32).malloc(1)
    p2 = Pointer(Int32 | String).malloc(1)

    reset p1, p2
    p1.copy_from(p1, 1)
    assert p1.value == 10

    # p1.copy_from(p2, 10) # invalid

    reset p1, p2
    p2.copy_from(p1, 1)
    assert p2.value == 10

    reset p1, p2
    p2.copy_from(p2, 1)
    assert p2.value == 20

    reset p1, p2
    p1.move_from(p1, 1)
    assert p1.value == 10

    # p1.move_from(p2, 10) # invalid

    reset p1, p2
    p2.move_from(p1, 1)
    assert p2.value == 10

    reset p1, p2
    p2.move_from(p2, 1)
    assert p2.value == 20

    # ---

    reset p1, p2
    p1.copy_to(p1, 1)
    assert p1.value == 10

    reset p1, p2
    p1.copy_to(p2, 1)
    assert p2.value == 10

    # p2.copy_to(p1, 10) # invalid

    reset p1, p2
    p2.copy_to(p2, 1)
    assert p2.value == 20

    reset p1, p2
    p1.move_to(p1, 1)
    assert p1.value == 10

    reset p1, p2
    p1.move_to(p2, 1)
    assert p2.value == 10

    # p2.move_to(p1, 10) # invalid

    reset p1, p2
    p2.move_to(p2, 1)
    assert p2.value == 20
  end

  describe "clear" do
    it "clears one" do
      ptr = Pointer(Int32).malloc(2)
      ptr[0] = 10
      ptr[1] = 20
      ptr.clear
      assert ptr[0] == 0
      assert ptr[1] == 20
    end

    it "clears many" do
      ptr = Pointer(Int32).malloc(4)
      ptr[0] = 10
      ptr[1] = 20
      ptr[2] = 30
      ptr[3] = 40
      ptr.clear(2)
      assert ptr[0] == 0
      assert ptr[1] == 0
      assert ptr[2] == 30
      assert ptr[3] == 40
    end

    it "clears with union" do
      ptr = Pointer(Int32 | Nil).malloc(4)
      ptr[0] = 10
      ptr[1] = 20
      ptr[2] = 30
      ptr[3] = 0
      ptr.clear(2)
      assert ptr[0].nil?
      assert ptr[1].nil?
      assert ptr[2] == 30
      assert ptr[3] == 0
      assert ptr[3]
    end
  end

  it "does !" do
    assert (!Pointer(Int32).null) == true
    assert (!Pointer(Int32).new(123)) == false
  end

  it "clones" do
    ptr = Pointer(Int32).new(123)
    assert ptr.clone == ptr
  end
end
