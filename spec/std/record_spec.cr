require "spec"

module RecordSpec
  record Record1,
    x : Int32,
    y : Array(Int32)

  record Record2,
    x : Int32 = 0,
    y : Array(Int32) = [2, 3]

  record Record3,
    x = 0,
    y = [2, 3]
end

describe "record" do
  it "defines record with type declarations" do
    ary = [2, 3]
    rec = RecordSpec::Record1.new(1, ary)
    assert rec.x == 1
    assert rec.y.same?(ary)

    cloned = rec.clone
    assert cloned.x == 1
    assert cloned.y == ary
    assert !cloned.y.same?(ary)
  end

  it "defines record with type declaration and initialization" do
    rec = RecordSpec::Record2.new
    assert rec.x == 0
    assert rec.y == [2, 3]

    cloned = rec.clone
    assert cloned.x == 0
    assert cloned.y == rec.y
    assert !cloned.y.same?(rec.y)
  end

  it "defines record with assignments" do
    rec = RecordSpec::Record3.new
    assert rec.x == 0
    assert rec.y == [2, 3]

    cloned = rec.clone
    assert cloned.x == 0
    assert cloned.y == rec.y
    assert !cloned.y.same?(rec.y)
  end
end
