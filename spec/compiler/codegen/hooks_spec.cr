require "../../spec_helper"

describe "Code gen: hooks" do
  it "does inherited macro" do
    assert run("
      class Foo
        macro inherited
          @@x = 1

          def self.x
            @@x
          end
        end
      end

      class Bar < Foo
      end

      Bar.x
      ").to_i == 1
  end

  it "does included macro" do
    assert run("
      module Foo
        macro included
          @@x = 1

          def self.x
            @@x
          end
        end
      end

      class Bar
        include Foo
      end

      Bar.x
      ").to_i == 1
  end

  it "does extended macro" do
    assert run("
      module Foo
        macro extended
          @@x = 1

          def self.x
            @@x
          end
        end
      end

      class Bar
        extend Foo
      end

      Bar.x
      ").to_i == 1
  end

  it "does added method macro" do
    assert run("
      class Global
        @@x = 0

        def self.x=(@@x)
        end

        def self.x
          @@x
        end
      end

      class Foo
        macro method_added(d)
          Global.x = 1
        end

        def foo; end
      end

      Global.x
      ").to_i == 1
  end

  it "does inherited macro recursively" do
    assert run("
      class Global
        @@x = 0

        def self.x=(@@x)
        end

        def self.x
          @@x
        end
      end

      class Foo
        macro inherited
          Global.x += 1
        end
      end

      class Bar < Foo
      end

      class Baz < Bar
      end

      Global.x
      ").to_i == 2
  end

  it "does inherited macro before class body" do
    assert run("
      class Global
        @@x = 123

        def self.x=(@@x)
        end

        def self.x
          @@x
        end
      end

      class Foo
        macro inherited
          @@y : Int32 = Global.x

          def self.y
            @@y
          end
        end
      end

      class Bar < Foo
        Global.x += 1
      end

      Bar.y
      ").to_i == 123
  end
end
