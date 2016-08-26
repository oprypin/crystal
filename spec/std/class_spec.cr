require "spec"

describe Class do
  it "does ===" do
    assert (Int32 === 1) == true
    assert (Int32 === 1.5) == false
    assert (Array === [1]) == true
    assert (Array(Int32) === [1]) == true
    assert (Array(Int32) === ['a']) == false
  end

  it "casts, allowing the class to be passed in at runtime" do
    ar = [99, "something"]
    cl = {Int32, String}
    casted = {cl[0].cast(ar[0]), cl[1].cast(ar[1])}
    assert casted == {99, "something"}
    assert typeof(casted[0]) == Int32
    assert typeof(casted[1]) == String
  end

  it "does |" do
    assert (Int32 | Char) == typeof(1, 'a')
    assert (Int32 | Char | Float64) == typeof(1, 'a', 1.0)
  end

  it "dups" do
    assert Int32.dup == Int32
  end

  it "clones" do
    assert Int32.clone == Int32
  end

  it "#nilable" do
    assert Int32.nilable? == false
    assert Nil.nilable? == true
    assert (Int32 | String).nilable? == false
    assert Int32?.nilable? == true
  end
end
