require "spec"

class DequeTester
  # Execute the same actions on an Array and a Deque and compare them at each step.

  @deque : Deque(Int32)
  @array : Array(Int32)
  @i : Int32
  @c : Array(Int32) | Deque(Int32) | Nil

  def step
    @c = @deque
    yield
    @c = @array
    yield
    assert @deque.to_a == @array
    @i += 1
  end

  def initialize
    @deque = Deque(Int32).new
    @array = Array(Int32).new
    @i = 1
  end

  getter i

  def c
    @c.not_nil!
  end

  def test
    with self yield
  end
end

alias RecursiveDeque = Deque(RecursiveDeque)

describe "Deque" do
  describe "implementation" do
    it "works the same as array" do
      DequeTester.new.test do
        step { c.unshift i }
        step { c.pop }
        step { c.push i }
        step { c.shift }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.pop }
        step { c.shift }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.push i }
        step { c.unshift i }
        step { c.unshift i }
        step { c.unshift i }
        step { c.unshift i }
        step { c.unshift i }
        step { c.unshift i }
        step { c.insert(1, i) }
        step { c.insert(0, i) }
        step { c.insert(17, i) }
        step { c.insert(14, i) }
        step { c.insert(10, i) }
        step { c.insert(10, i) }
      end
    end

    it "works the same as array when inserting at 1/8 size and deleting at 3/4 size" do
      DequeTester.new.test do
        1000.times do
          step { c.insert(c.size / 8, i) }
        end
        1000.times do
          step { c.delete_at(c.size * 3 / 4) }
        end
      end
    end

    it "works the same as array when inserting at 3/4 size and deleting at 1/8 size" do
      DequeTester.new.test do
        1000.times do
          step { c.insert(c.size * 3 / 4, i) }
        end
        1000.times do
          step { c.delete_at(c.size / 8) }
        end
      end
    end
  end

  describe "new" do
    it "creates with default value" do
      deq = Deque.new(5, 3)
      assert deq == Deque{3, 3, 3, 3, 3}
    end

    it "creates with default value in block" do
      deq = Deque(Int32).new(5) { |i| i * 2 }
      assert deq == Deque{0, 2, 4, 6, 8}
    end

    it "creates from an array" do
      deq = Deque(Int32).new([1, 2, 3, 4, 5])
      assert deq == Deque{1, 2, 3, 4, 5}
    end

    it "raises on negative count" do
      expect_raises(ArgumentError, "negative deque size") do
        Deque.new(-1, 3)
      end
    end

    it "raises on negative capacity" do
      expect_raises(ArgumentError, "negative deque capacity") do
        Deque(Int32).new(-1)
      end
    end
  end

  describe "==" do
    it "compares empty" do
      assert Deque(Int32).new == Deque(Int32).new
      assert Deque{1} != Deque(Int32).new
      assert Deque(Int32).new != Deque{1}
    end

    it "compares elements" do
      assert Deque{1, 2, 3} == Deque{1, 2, 3}
      assert Deque{1, 2, 3} != Deque{3, 2, 1}
    end

    it "compares other" do
      a = Deque{1, 2, 3}
      b = Deque{1, 2, 3}
      c = Deque{1, 2, 3, 4}
      d = Deque{1, 2, 4}
      assert (a == b) == true
      assert (b == c) == false
      assert (a == d) == false
    end
  end

  describe "+" do
    it "does +" do
      a = Deque{1, 2, 3}
      b = Deque{4, 5}
      c = a + b
      assert c.size == 5
      0.upto(4) { |i| assert c[i] == i + 1 }
    end

    it "does + with different types" do
      a = Deque{1, 2, 3}
      a += Deque{"hello"}
      assert a == Deque{1, 2, 3, "hello"}
    end
  end

  describe "[]" do
    it "gets on positive index" do
      assert Deque{1, 2, 3}[1] == 2
    end

    it "gets on negative index" do
      assert Deque{1, 2, 3}[-1] == 3
    end

    it "gets nilable" do
      assert Deque{1, 2, 3}[2]? == 3
      assert Deque{1, 2, 3}[3]?.nil?
    end

    it "same access by at" do
      assert Deque{1, 2, 3}[1] == Deque{1, 2, 3}.at(1)
    end
  end

  describe "[]=" do
    it "sets on positive index" do
      a = Deque{1, 2, 3}
      a[1] = 4
      assert a[1] == 4
    end

    it "sets on negative index" do
      a = Deque{1, 2, 3}
      a[-1] = 4
      assert a[2] == 4
    end
  end

  it "does clear" do
    a = Deque{1, 2, 3}
    a.clear
    assert a == Deque(Int32).new
  end

  it "does clone" do
    x = {1 => 2}
    a = Deque{x}
    b = a.clone
    assert b == a
    assert !a.same?(b)
    assert !a[0].same?(b[0])
  end

  describe "concat" do
    it "concats deque" do
      a = Deque{1, 2, 3}
      a.concat(Deque{4, 5, 6})
      assert a == Deque{1, 2, 3, 4, 5, 6}
    end

    it "concats large deques" do
      a = Deque{1, 2, 3}
      a.concat((4..1000).to_a)
      assert a == Deque.new((1..1000).to_a)
    end

    it "concats enumerable" do
      a = Deque{1, 2, 3}
      a.concat((4..1000))
      assert a == Deque.new((1..1000).to_a)
    end
  end

  describe "delete" do
    it "deletes many" do
      a = Deque{1, 2, 3, 1, 2, 3}
      assert a.delete(2) == true
      assert a == Deque{1, 3, 1, 3}
    end

    it "delete not found" do
      a = Deque{1, 2}
      assert a.delete(4) == false
      assert a == Deque{1, 2}
    end
  end

  describe "delete_at" do
    it "deletes positive index" do
      a = Deque{1, 2, 3, 4, 5}
      assert a.delete_at(3) == 4
      assert a == Deque{1, 2, 3, 5}
    end

    it "deletes negative index" do
      a = Deque{1, 2, 3, 4, 5}
      assert a.delete_at(-4) == 2
      assert a == Deque{1, 3, 4, 5}
    end

    it "deletes out of bounds" do
      a = Deque{1, 2, 3, 4}
      expect_raises IndexError do
        a.delete_at(4)
      end
    end
  end

  it "does dup" do
    x = {1 => 2}
    a = Deque{x}
    b = a.dup
    assert b == Deque{x}
    assert !a.same?(b)
    assert a[0].same?(b[0])
    b << {3 => 4}
    assert a == Deque{x}
  end

  it "does each_index" do
    a = Deque{1, 1, 1}
    b = 0
    a.each_index { |i| b += i }
    assert b == 3
  end

  describe "empty" do
    it "is empty" do
      assert (Deque(Int32).new.empty?) == true
    end

    it "is not empty" do
      assert Deque{1}.empty? == false
    end
  end

  it "does equals? with custom block" do
    a = Deque{1, 3, 2}
    b = Deque{3, 9, 4}
    c = Deque{5, 7, 3}
    d = Deque{1, 3, 2, 4}
    f = ->(x : Int32, y : Int32) { (x % 2) == (y % 2) }
    assert a.equals?(b, &f) == true
    assert a.equals?(c, &f) == false
    assert a.equals?(d, &f) == false
  end

  describe "first" do
    it "gets first when non empty" do
      a = Deque{1, 2, 3}
      assert a.first == 1
    end

    it "raises when empty" do
      expect_raises IndexError do
        Deque(Int32).new.first
      end
    end
  end

  describe "first?" do
    it "gets first? when non empty" do
      a = Deque{1, 2, 3}
      assert a.first? == 1
    end

    it "gives nil when empty" do
      assert Deque(Int32).new.first?.nil?
    end
  end

  it "does hash" do
    a = Deque{1, 2, Deque{3}}
    b = Deque{1, 2, Deque{3}}
    assert a.hash == b.hash
  end

  describe "insert" do
    it "inserts with positive index" do
      a = Deque{1, 3, 4}
      expected = Deque{1, 2, 3, 4}
      assert a.insert(1, 2) == expected
      assert a == expected
    end

    it "inserts with negative index" do
      a = Deque{1, 2, 3}
      expected = Deque{1, 2, 3, 4}
      assert a.insert(-1, 4) == expected
      assert a == expected
    end

    it "inserts with negative index (2)" do
      a = Deque{1, 2, 3}
      expected = Deque{4, 1, 2, 3}
      assert a.insert(-4, 4) == expected
      assert a == expected
    end

    it "inserts out of range" do
      a = Deque{1, 3, 4}

      expect_raises IndexError do
        a.insert(4, 1)
      end
    end
  end

  describe "inspect" do
    it { assert Deque{1, 2, 3}.inspect == "Deque{1, 2, 3}" }
  end

  describe "last" do
    it "gets last when non empty" do
      a = Deque{1, 2, 3}
      assert a.last == 3
    end

    it "raises when empty" do
      expect_raises IndexError do
        Deque(Int32).new.last
      end
    end
  end

  describe "size" do
    it "has size 0" do
      assert Deque(Int32).new.size == 0
    end

    it "has size 2" do
      assert Deque{1, 2}.size == 2
    end
  end

  describe "pop" do
    it "pops when non empty" do
      a = Deque{1, 2, 3}
      assert a.pop == 3
      assert a == Deque{1, 2}
    end

    it "raises when empty" do
      expect_raises IndexError do
        Deque(Int32).new.pop
      end
    end

    it "pops many elements" do
      a = Deque{1, 2, 3, 4, 5}
      a.pop(3)
      assert a == Deque{1, 2}
    end

    it "pops more elements than what is available" do
      a = Deque{1, 2, 3, 4, 5}
      a.pop(10)
      assert a == Deque(Int32).new
    end

    it "pops negative count raises" do
      a = Deque{1, 2}
      expect_raises ArgumentError do
        a.pop(-1)
      end
    end
  end

  describe "push" do
    it "adds one element to the deque" do
      a = Deque{"a", "b"}
      a.push("c")
      assert a == Deque{"a", "b", "c"}
    end

    it "returns the deque" do
      a = Deque{"a", "b"}
      assert a.push("c") == Deque{"a", "b", "c"}
    end

    it "has the << alias" do
      a = Deque{"a", "b"}
      a << "c"
      assert a == Deque{"a", "b", "c"}
    end
  end

  describe "rotate!" do
    it "rotates" do
      a = Deque{1, 2, 3, 4, 5}
      a.rotate!
      assert a == Deque{2, 3, 4, 5, 1}
      a.rotate!(-2)
      assert a == Deque{5, 1, 2, 3, 4}
      a.rotate!(10)
      assert a == Deque{5, 1, 2, 3, 4}
    end

    it "rotates with size=capacity" do
      a = Deque{1, 2, 3, 4}
      a.rotate!
      assert a == Deque{2, 3, 4, 1}
      a.rotate!(-2)
      assert a == Deque{4, 1, 2, 3}
      a.rotate!(8)
      assert a == Deque{4, 1, 2, 3}
    end
  end

  describe "shift" do
    it "shifts when non empty" do
      a = Deque{1, 2, 3}
      assert a.shift == 1
      assert a == Deque{2, 3}
    end

    it "raises when empty" do
      expect_raises IndexError do
        Deque(Int32).new.shift
      end
    end

    it "shifts many elements" do
      a = Deque{1, 2, 3, 4, 5}
      a.shift(3)
      assert a == Deque{4, 5}
    end

    it "shifts more than what is available" do
      a = Deque{1, 2, 3, 4, 5}
      a.shift(10)
      assert a == Deque(Int32).new
    end

    it "shifts negative count raises" do
      a = Deque{1, 2}
      expect_raises ArgumentError do
        a.shift(-1)
      end
    end
  end

  describe "swap" do
    it "swaps" do
      a = Deque{1, 2, 3}
      a.swap(0, 2)
      assert a == Deque{3, 2, 1}
    end

    it "swaps with negative indices" do
      a = Deque{1, 2, 3}
      a.swap(-3, -1)
      assert a == Deque{3, 2, 1}
    end

    it "swaps but raises out of bounds on left" do
      a = Deque{1, 2, 3}
      expect_raises IndexError do
        a.swap(3, 0)
      end
    end

    it "swaps but raises out of bounds on right" do
      a = Deque{1, 2, 3}
      expect_raises IndexError do
        a.swap(0, 3)
      end
    end
  end

  describe "to_s" do
    it "does to_s" do
      it { assert Deque{1, 2, 3}.to_s == "Deque{1, 2, 3}" }
    end

    it "does with recursive" do
      deq = Deque(RecursiveDeque).new
      deq << deq
      assert deq.to_s == "Deque{Deque{...}}"
    end
  end

  it "does unshift" do
    a = Deque{2, 3}
    expected = Deque{1, 2, 3}
    assert a.unshift(1) == expected
    assert a == expected
  end

  describe "each iterator" do
    it "does next" do
      a = Deque{1, 2, 3}
      iter = a.each
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next == 3
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 1
    end

    it "cycles" do
      assert Deque{1, 2, 3}.cycle.first(8).join == "12312312"
    end

    it "works while modifying deque" do
      a = Deque{1, 2, 3}
      count = 0
      it = a.each
      it.each do
        count += 1
        a.clear
      end
      assert count == 1
    end
  end

  describe "each_index iterator" do
    it "does next" do
      a = Deque{1, 2, 3}
      iter = a.each_index
      assert iter.next == 0
      assert iter.next == 1
      assert iter.next == 2
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 0
    end

    it "works while modifying deque" do
      a = Deque{1, 2, 3}
      count = 0
      it = a.each_index
      a.each_index.each do
        count += 1
        a.clear
      end
      assert count == 1
    end
  end

  describe "reverse each iterator" do
    it "does next" do
      a = Deque{1, 2, 3}
      iter = a.reverse_each
      assert iter.next == 3
      assert iter.next == 2
      assert iter.next == 1
      assert iter.next.is_a?(Iterator::Stop)

      iter.rewind
      assert iter.next == 3
    end
  end

  describe "cycle" do
    it "cycles" do
      a = [] of Int32
      Deque{1, 2, 3}.cycle do |x|
        a << x
        break if a.size == 9
      end
      assert a == [1, 2, 3, 1, 2, 3, 1, 2, 3]
    end

    it "cycles N times" do
      a = [] of Int32
      Deque{1, 2, 3}.cycle(2) do |x|
        a << x
      end
      assert a == [1, 2, 3, 1, 2, 3]
    end

    it "cycles with iterator" do
      assert Deque{1, 2, 3}.cycle.first(5).to_a == [1, 2, 3, 1, 2]
    end

    it "cycles with N and iterator" do
      assert Deque{1, 2, 3}.cycle(2).to_a == [1, 2, 3, 1, 2, 3]
    end
  end
end
