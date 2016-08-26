require "../../spec_helper"

describe "Code gen: return" do
  it "codegens return" do
    assert run("def foo; return 1; end; foo").to_i == 1
  end

  it "codegens return followed by another expression" do
    assert run("def foo; return 1; 2; end; foo").to_i == 1
  end

  it "codegens return inside if" do
    assert run("def foo; if 1 == 1; return 1; end; 2; end; foo").to_i == 1
  end

  it "return from function with union type" do
    assert run("struct Char; def to_i; 2; end; end; def foo; return 1 if 1 == 1; 'a'; end; foo.to_i").to_i == 1
  end

  it "return union" do
    assert run("struct Char; def to_i; 2; end; end; def foo; 1 == 2 ? return 1 : return 'a'; end; foo.to_i").to_i == 2
  end

  it "return from function with nilable type" do
    assert run(%(require "prelude"; def foo; return Reference.new if 1 == 1; end; foo.nil?)).to_b == false
  end

  it "return from function with nilable type 2" do
    assert run(%(require "prelude"; def foo; return Reference.new if 1 == 1; end; foo.nil?)).to_b == false
  end

  it "returns empty from function" do
    assert run("
      struct Nil; def to_i; 0; end; end
      def foo(x)
        return if x == 1
        1
      end

      foo(2).to_i
    ").to_i == 1
  end

  it "codegens bug with return if true" do
    assert run(%(
      def bar
        return if true
        1
      end

      bar.is_a?(Nil)
      )).to_b == true
  end

  it "codegens assign with if with two returns" do
    assert run(%(
      def test
        a = 1 ? return 2 : return 3
      end

      test
      )).to_i == 2
  end
end
