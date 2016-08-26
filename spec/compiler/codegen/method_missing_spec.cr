require "../../spec_helper"

describe "Code gen: method_missing" do
  it "does method_missing macro without args" do
    assert run("
      class Foo
        def foo_something
          1
        end

        macro method_missing(call)
          {{call.name.id}}_something
        end
      end

      Foo.new.foo
      ").to_i == 1
  end

  it "does method_missing macro with args" do
    assert run(%(
      class Foo
        macro method_missing(call)
          {{call.args.join(" + ").id}}
        end
      end

      Foo.new.foo(1, 2, 3)
      )).to_i == 6
  end

  it "does method_missing macro with block" do
    assert run(%(
      class Foo
        def foo_something
          yield 1
          yield 2
          yield 3
        end

        macro method_missing(call)
          {{call.name.id}}_something {{call.block}}
        end
      end

      a = 0
      Foo.new.foo do |x|
        a += x
      end
      a
      )).to_i == 6
  end

  it "does method_missing macro with block but not using it" do
    assert run(%(
      class Foo
        def foo_something
          1 + 2
        end

        macro method_missing(call)
          {{call.name.id}}_something {{call.block}}
        end
      end

      Foo.new.foo
      )).to_i == 3
  end

  it "does method_missing macro with virtual type (1)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          "{{@type.name.id}}{{call.name.id}}"
        end
      end

      class Bar < Foo
      end

      foo = Foo.new || Bar.new
      foo.coco
      )).to_string == "Foococo"
  end

  it "does method_missing macro with virtual type (2)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          "{{@type.name.id}}{{call.name.id}}"
        end
      end

      class Bar < Foo
      end

      foo = Bar.new || Foo.new
      foo.coco
      )).to_string == "Barcoco"
  end

  it "does method_missing macro with virtual type (3)" do
    assert run(%(
      class Foo
        def lala
          1
        end

        macro method_missing(call)
          2
        end
      end

      class Bar < Foo
      end

      foo = Bar.new || Foo.new
      foo.lala
      )).to_i == 1
  end

  it "does method_missing macro with virtual type (4)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          1
        end
      end

      class Bar < Foo
        macro method_missing(call)
          2
        end
      end

      foo = Bar.new || Foo.new
      foo.lala
      )).to_i == 2
  end

  it "does method_missing macro with virtual type (5)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          1
        end
      end

      class Bar < Foo
        macro method_missing(call)
          2
        end
      end

      class Baz < Bar
        macro method_missing(call)
          3
        end
      end

      foo = Baz.new || Bar.new || Foo.new
      foo.lala
      )).to_i == 3
  end

  it "does method_missing macro with virtual type (6)" do
    assert run(%(
      abstract class Foo
      end

      class Bar < Foo
        macro method_missing(call)
          2
        end
      end

      class Baz < Bar
        def lala
          3
        end
      end

      foo = Bar.new || Baz.new
      foo.lala
      )).to_i == 2
  end

  it "does method_missing macro with virtual type (7)" do
    assert run(%(
      abstract class Foo
      end

      class Bar < Foo
        macro method_missing(call)
          2
        end
      end

      class Baz < Bar
        def lala
          3
        end
      end

      foo = Baz.new || Bar.new
      foo.lala
      )).to_i == 3
  end

  it "does method_missing macro with virtual type (8)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          {{@type.name.stringify}}
        end
      end

      class Bar < Foo
      end

      foo = Foo.new
      foo.coco

      bar = Bar.new
      bar.coco
      )).to_string == "Bar"
  end

  it "does method_missing macro with module involved" do
    assert run("
      module Moo
        def lala
          1
        end
      end

      class Foo
        include Moo

        macro method_missing(call)
          2
        end
      end

      Foo.new.lala
      ").to_i == 1
  end

  it "does method_missing macro with top level method involved" do
    assert run("
      def lala
        1
      end

      class Foo
        macro method_missing(call)
          2
        end

        def bar
          lala
        end
      end

      foo = Foo.new
      foo.bar
      ").to_i == 1
  end

  it "does method_missing macro with included module" do
    assert run("
      module Moo
        macro method_missing(call)
          {{@type.name.stringify}}
        end
      end

      class Foo
        include Moo
      end

      Foo.new.coco
      ").to_string == "Foo"
  end

  it "does method_missing with assignment (bug)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          x = {{call.args[0]}}
          x
        end
      end

      foo = Foo.new
      foo.bar(1)
      )).to_i == 1
  end

  it "does method_missing with assignment (2) (bug)" do
    assert run(%(
      struct Nil
        def to_i
          0
        end
      end

      class Foo
        @x : Int32?

        macro method_missing(call)
          @x = {{call.args[0]}}
          @x
        end
      end

      foo = Foo.new
      foo.bar(1).to_i
      )).to_i == 1
  end

  it "does method_missing macro without args (with call)" do
    assert run("
      class Foo
        def foo_something
          1
        end

        macro method_missing(call)
          {{call.name.id}}_something
        end
      end

      Foo.new.foo
      ").to_i == 1
  end

  it "does method_missing macro with args (with call)" do
    assert run(%(
      class Foo
        macro method_missing(call)
          {{call.args.join(" + ").id}}
        end
      end

      Foo.new.foo(1, 2, 3)
      )).to_i == 6
  end

  it "forwards" do
    assert run(%(
      class Wrapped
        def foo(x, y, z)
          x + y + z
        end
      end

      class Foo
        def initialize(@wrapped : Wrapped)
        end

        macro method_missing(call)
          @wrapped.{{call}}
        end
      end

      Foo.new(Wrapped.new).foo(1, 2, 3)
      )).to_i == 6
  end
end
