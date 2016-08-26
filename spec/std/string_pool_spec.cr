require "spec"
require "string_pool"

describe StringPool do
  it "is empty" do
    pool = StringPool.new
    assert pool.empty? == true
    assert pool.size == 0
  end

  it "gets string" do
    pool = StringPool.new
    s1 = pool.get "foo"
    s2 = pool.get "foo"

    assert s1 == "foo"
    assert s2 == "foo"
    assert s1.same?(s2)
    assert pool.size == 1
  end

  it "gets string IO" do
    pool = StringPool.new
    io = MemoryIO.new "foo"

    s1 = pool.get io
    s2 = pool.get "foo"

    assert s1 == "foo"
    assert s2 == "foo"
    assert s1.same?(s2)
    assert pool.size == 1
  end

  it "gets slice" do
    pool = StringPool.new
    slice = Slice(UInt8).new(3, 'a'.ord.to_u8)

    s1 = pool.get(slice)
    s2 = pool.get(slice)

    assert s1 == "aaa"
    assert s2 == "aaa"
    assert s1.same?(s2)
    assert pool.size == 1
  end

  it "gets pointer with size" do
    pool = StringPool.new
    slice = Slice(UInt8).new(3, 'a'.ord.to_u8)

    s1 = pool.get(slice.pointer(slice.size), slice.size)
    s2 = pool.get(slice.pointer(slice.size), slice.size)

    assert s1 == "aaa"
    assert s2 == "aaa"
    assert s1.same?(s2)
    assert pool.size == 1
  end

  it "puts many" do
    pool = StringPool.new
    10_000.times do |i|
      pool.get(i.to_s)
    end
    assert pool.size == 10_000
  end
end
