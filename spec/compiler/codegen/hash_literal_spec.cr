require "../../spec_helper"

describe "Code gen: hash literal spec" do
  it "creates custom non-generic hash" do
    assert run(%(
      class Custom
        def initialize
          @keys = 0
          @values = 0
        end

        def []=(key, value)
          @keys += key
          @values += value
        end

        def keys
          @keys
        end

        def values
          @values
        end
      end

      custom = Custom {1 => 10, 2 => 20}
      custom.keys * custom.values
      )).to_i == 90
  end

  it "creates custom generic hash" do
    assert run(%(
      class Custom(K, V)
        def initialize
          @keys = 0
          @values = 0
        end

        def []=(key, value)
          @keys += key
          @values += value
        end

        def keys
          @keys
        end

        def values
          @values
        end
      end

      custom = Custom {1 => 10, 2 => 20}
      custom.keys * custom.values
      )).to_i == 90
  end

  it "creates custom generic hash with type vars" do
    assert run(%(
      class Custom(K, V)
        def initialize
          @keys = 0
          @values = 0
        end

        def []=(key, value)
          @keys += key
          @values += value
        end

        def keys
          @keys
        end

        def values
          @values
        end
      end

      custom = Custom(Int32, Int32) {1 => 10, 2 => 20}
      custom.keys * custom.values
      )).to_i == 90
  end

  it "creates custom generic hash via alias (1)" do
    assert run(%(
      class Custom(K, V)
        def initialize
          @keys = 0
          @values = 0
        end

        def []=(key, value)
          @keys += key
          @values += value
        end

        def keys
          @keys
        end

        def values
          @values
        end
      end

      alias MyCustom = Custom

      custom = MyCustom {1 => 10, 2 => 20}
      custom.keys * custom.values
      )).to_i == 90
  end

  it "creates custom generic hash via alias (2)" do
    assert run(%(
      class Custom(K, V)
        def initialize
          @keys = 0
          @values = 0
        end

        def []=(key, value)
          @keys += key
          @values += value
        end

        def keys
          @keys
        end

        def values
          @values
        end
      end

      alias MyCustom = Custom(Int32, Int32)

      custom = MyCustom {1 => 10, 2 => 20}
      custom.keys * custom.values
      )).to_i == 90
  end

  it "doesn't crash on hash literal with proc pointer (#646)" do
    assert run(%(
      require "prelude"

      def blah
        1
      end

      b = {"a" => ->blah}
      b["a"].call
      )).to_i == 1
  end
end
