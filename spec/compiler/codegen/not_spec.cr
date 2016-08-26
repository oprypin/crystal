require "../../spec_helper"

describe "Code gen: not" do
  it "codegens not number" do
    assert run("!1").to_b == false
  end

  it "codegens not true" do
    assert run("!true").to_b == false
  end

  it "codegens not false" do
    assert run("!false").to_b == true
  end

  it "codegens not nil" do
    assert run("!nil").to_b == true
  end

  it "codegens not nilable type (true)" do
    assert run(%(
      class Foo
      end

      a = 1 == 2 ? Foo.new : nil
      !a
      )).to_b == true
  end

  it "codegens not nilable type (false)" do
    assert run(%(
      class Foo
      end

      a = 1 == 1 ? Foo.new : nil
      !a
      )).to_b == false
  end

  it "codegens not pointer (true)" do
    assert run(%(
      !Pointer(Int32).new(0_u64)
      )).to_b == true
  end

  it "codegens not pointer (false)" do
    assert run(%(
      !Pointer(Int32).new(1_u64)
      )).to_b == false
  end

  it "doesn't crash" do
    assert run(%(
      a = 1
      !a.is_a?(String) && !a
      )).to_b == false
  end
end
