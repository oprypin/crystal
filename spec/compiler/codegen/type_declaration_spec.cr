require "../../spec_helper"

describe "Code gen: type declaration" do
  it "codegens initialize instance var" do
    assert run("
      class Foo
        @x = 1

        def x
          @x
        end
      end

      Foo.new.x
      ").to_i == 1
  end

  it "codegens initialize instance var of superclass" do
    assert run("
      class Foo
        @x = 1

        def x
          @x
        end
      end

      class Bar < Foo
      end

      Bar.new.x
      ").to_i == 1
  end

  it "codegens initialize instance var with var declaration" do
    assert run("
      class Foo
        @x : Int32 = begin
          a = 1
          a
        end

        def x
          @x
        end
      end

      Foo.new.x
      ").to_i == 1
  end

  it "declares and initializes" do
    assert run(%(
      class Foo
        @x : Int32 = 42

        def x
          @x
        end
      end

      Foo.new.x
      )).to_i == 42
  end
end
