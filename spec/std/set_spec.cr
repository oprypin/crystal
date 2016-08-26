require "spec"
require "set"

describe "Set" do
  describe "an empty set" do
    it "is empty" do
      assert Set(Nil).new.empty? == true
    end

    it "has size 0" do
      assert Set(Nil).new.size == 0
    end
  end

  describe "new" do
    it "creates new set with enumerable without block" do
      set_from_array = Set.new([2, 4, 6, 4])
      assert set_from_array.size == 3
      assert set_from_array.to_a.sort == [2, 4, 6]

      set_from_tulpe = Set.new({1, "hello", 'x'})
      assert set_from_tulpe.size == 3
      assert set_from_tulpe.to_a.includes?(1) == true
      assert set_from_tulpe.to_a.includes?("hello") == true
      assert set_from_tulpe.to_a.includes?('x') == true
    end
  end

  describe "add" do
    it "adds and includes" do
      set = Set(Int32).new
      set.add 1
      assert set.includes?(1) == true
      assert set.size == 1
    end

    it "returns self" do
      set = Set(Int32).new
      assert set.add(1) == set
    end
  end

  describe "delete" do
    it "deletes an object" do
      set = Set{1, 2, 3}
      set.delete 2
      assert set.size == 2
      assert set.includes?(1) == true
      assert set.includes?(3) == true
    end

    it "returns self" do
      set = Set{1, 2, 3}
      assert set.delete(2) == set
    end
  end

  describe "dup" do
    it "creates a dup" do
      set1 = Set{[1, 2]}
      set2 = set1.dup

      assert set1 == set2
      assert !set1.same?(set2)

      assert set1.to_a.first.same?(set2.to_a.first)

      set1 << [3]
      set2 << [4]

      assert set2 == Set{[1, 2], [4]}
    end
  end

  describe "clone" do
    it "creates a clone" do
      set1 = Set{[1, 2]}
      set2 = set1.clone

      assert set1 == set2
      assert !set1.same?(set2)

      assert !set1.to_a.first.same?(set2.to_a.first)

      set1 << [3]
      set2 << [4]

      assert set2 == Set{[1, 2], [4]}
    end
  end

  describe "==" do
    it "compares two sets" do
      set1 = Set{1, 2, 3}
      set2 = Set{1, 2, 3}
      set3 = Set{1, 2, 3, 4}

      assert set1 == set1
      assert set1 == set2
      assert set1 != set3
    end
  end

  describe "merge" do
    it "adds all the other elements" do
      set = Set{1, 4, 8}
      set.merge [1, 9, 10]
      assert set == Set{1, 4, 8, 9, 10}
    end

    it "returns self" do
      set = Set{1, 4, 8}
      assert set.merge([1, 9, 10]) == Set{1, 4, 8, 9, 10}
    end
  end

  it "does &" do
    set1 = Set{1, 2, 3}
    set2 = Set{4, 2, 5, 3}
    set3 = set1 & set2
    assert set3 == Set{2, 3}
  end

  it "does |" do
    set1 = Set{1, 2, 3}
    set2 = Set{4, 2, 5, "3"}
    set3 = set1 | set2
    assert set3 == Set{1, 2, 3, 4, 5, "3"}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 6}
    set3 = set1 - set2
    assert set3 == Set{1, 3, 5}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 'a'}
    set3 = set1 - set2
    assert set3 == Set{1, 3, 5}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = Set{2, 4, 5}
    set3 = set1 - set2
    assert set3 == Set{1, 3, 'b'}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 6]
    set3 = set1 - set2
    assert set3 == Set{1, 3, 5}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 'a']
    set3 = set1 - set2
    assert set3 == Set{1, 3, 5}
  end

  it "does -" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = [2, 4, 5]
    set3 = set1 - set2
    assert set3 == Set{1, 3, 'b'}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 6}
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 6}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 'a'}
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 'a'}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = Set{2, 4, 5}
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 'b'}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 6]
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 6}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 'a']
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 'a'}
  end

  it "does ^" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = [2, 4, 5]
    set3 = set1 ^ set2
    assert set3 == Set{1, 3, 5, 'b'}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 6}
    set1.subtract set2
    assert set1 == Set{1, 3, 5}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = Set{2, 4, 'a'}
    set1.subtract set2
    assert set1 == Set{1, 3, 5}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = Set{2, 4, 5}
    set1.subtract set2
    assert set1 == Set{1, 3, 'b'}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 6]
    set1.subtract set2
    assert set1 == Set{1, 3, 5}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 5}
    set2 = [2, 4, 'a']
    set1.subtract set2
    assert set1 == Set{1, 3, 5}
  end

  it "does subtract" do
    set1 = Set{1, 2, 3, 4, 'b'}
    set2 = [2, 4, 5]
    set1.subtract set2
    assert set1 == Set{1, 3, 'b'}
  end

  it "does to_a" do
    assert Set{1, 2, 3}.to_a == [1, 2, 3]
  end

  it "does to_s" do
    assert Set{1, 2, 3}.to_s == "Set{1, 2, 3}"
    assert Set{"foo"}.to_s == %(Set{"foo"})
  end

  it "does clear" do
    x = Set{1, 2, 3}
    assert x.to_a == [1, 2, 3]
    assert x.clear.same?(x)
    x << 1
    assert x.to_a == [1]
  end

  it "checks intersects" do
    set = Set{3, 4, 5}
    empty_set = Set(Int32).new

    assert set.intersects?(set) == true
    assert set.intersects?(Set{2, 4}) == true
    assert set.intersects?(Set{5, 6, 7}) == true
    assert set.intersects?(Set{1, 2, 6, 8, 4}) == true

    assert set.intersects?(empty_set) == false
    assert set.intersects?(Set{0, 2}) == false
    assert set.intersects?(Set{0, 2, 6}) == false
    assert set.intersects?(Set{0, 2, 6, 8, 10}) == false

    # Make sure set hasn't changed
    assert set == Set{3, 4, 5}
  end

  it "compares hashes of sets" do
    h1 = {Set{1, 2, 3} => 1}
    h2 = {Set{1, 2, 3} => 1}
    assert h1 == h2
  end

  it "gets each iterator" do
    iter = Set{1, 2, 3}.each
    assert iter.next == 1
    assert iter.next == 2
    assert iter.next == 3
    assert iter.next.is_a?(Iterator::Stop)

    iter.rewind
    assert iter.next == 1
  end

  it "check subset" do
    set = Set{1, 2, 3}
    empty_set = Set(Int32).new

    assert set.subset?(Set{1, 2, 3, 4}) == true
    assert set.subset?(Set{1, 2, 3, "4"}) == true
    assert set.subset?(Set{1, 2, 3}) == true
    assert set.subset?(Set{1, 2}) == false
    assert set.subset?(empty_set) == false

    assert empty_set.subset?(Set{1}) == true
    assert empty_set.subset?(empty_set) == true
  end

  it "check proper_subset" do
    set = Set{1, 2, 3}
    empty_set = Set(Int32).new

    assert set.proper_subset?(Set{1, 2, 3, 4}) == true
    assert set.proper_subset?(Set{1, 2, 3, "4"}) == true
    assert set.proper_subset?(Set{1, 2, 3}) == false
    assert set.proper_subset?(Set{1, 2}) == false
    assert set.proper_subset?(empty_set) == false

    assert empty_set.proper_subset?(Set{1}) == true
    assert empty_set.proper_subset?(empty_set) == false
  end

  it "check superset" do
    set = Set{1, 2, "3"}
    empty_set = Set(Int32).new

    assert set.superset?(empty_set) == true
    assert set.superset?(Set{1, 2}) == true
    assert set.superset?(Set{1, 2, "3"}) == true
    assert set.superset?(Set{1, 2, 3}) == false
    assert set.superset?(Set{1, 2, 3, 4}) == false
    assert set.superset?(Set{1, 4}) == false

    assert empty_set.superset?(empty_set) == true
  end

  it "check proper_superset" do
    set = Set{1, 2, "3"}
    empty_set = Set(Int32).new

    assert set.proper_superset?(empty_set) == true
    assert set.proper_superset?(Set{1, 2}) == true
    assert set.proper_superset?(Set{1, 2, "3"}) == false
    assert set.proper_superset?(Set{1, 2, 3}) == false
    assert set.proper_superset?(Set{1, 2, 3, 4}) == false
    assert set.proper_superset?(Set{1, 4}) == false

    assert empty_set.proper_superset?(empty_set) == false
  end

  it "has object_id" do
    assert Set(Int32).new.object_id > 0
  end

  typeof(Set(Int32).new(initial_capacity: 1234))
end
