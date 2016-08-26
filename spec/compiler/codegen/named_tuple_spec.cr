require "../../spec_helper"

describe "Code gen: named tuple" do
  it "codegens tuple index" do
    assert run(%(
      t = {x: 42, y: 'a'}
      t[:x]
      )).to_i == 42
  end

  it "codegens tuple index another order" do
    assert run(%(
      t = {y: 'a', x: 42}
      t[:x]
      )).to_i == 42
  end

  it "codegens tuple nilable index (1)" do
    assert run(%(
      t = {x: 42, y: 'a'}
      t[:x]? || 84
      )).to_i == 42
  end

  it "codegens tuple nilable index (2)" do
    assert run(%(
      t = {x: 'a', y: 42}
      t[:y]? || 84
      )).to_i == 42
  end

  it "codegens tuple nilable index (3)" do
    assert run(%(
      t = {x: 'a', y: 42}
      t[:z]? || 84
      )).to_i == 84
  end

  it "passes named tuple to def" do
    assert run("
      def foo(t)
        t[:x]
      end

      foo({y: 'a', x: 42})
      ").to_i == 42
  end

  it "gets size at compile time" do
    assert run(%(
      struct NamedTuple
        def my_size
          {{ T.size }}
        end
      end

      {x: 10, y: 20}.my_size
      )).to_i == 2
  end

  it "gets keys at compile time (1)" do
    assert run(%(
      struct NamedTuple
        def keys
          {{ T.keys.map(&.stringify)[0] }}
        end
      end

      {x: 10, y: 2}.keys
      )).to_string == "x"
  end

  it "gets keys at compile time (2)" do
    assert run(%(
      struct NamedTuple
        def keys
          {{ T.keys.map(&.stringify)[1] }}
        end
      end

      {x: 10, y: 2}.keys
      )).to_string == "y"
  end

  it "doesn't crash when overload doesn't match" do
    codegen(%(
      struct NamedTuple
        def foo(other : self)
        end

        def foo(other)
        end
      end

      tup1 = {a: 1}
      tup2 = {b: 1}
      tup1.foo(tup2)
      ))
  end

  it "assigns named tuple to compatible named tuple" do
    assert run(%(
      ptr = Pointer({x: Int32, y: String}).malloc(1_u64)

      # Here the compiler should reoder the values to match
      # the type inside the pointer
      ptr.value = {y: "hello", x: 42}

      ptr.value[:x]
      )).to_i == 42
  end

  it "upcasts named tuple inside compatible named tuple" do
    assert run(%(
      def foo
        if 1 == 2
          {name: "Foo", age: 20}
        else
          # Here the compiler should reorder the values to match
          # those of the tuple above
          {age: 40, name: "Bar"}
        end
      end

      foo[:name]
      )).to_string == "Bar"
  end

  it "assigns named tuple union to compatible named tuple" do
    assert run(%(
      tup1 = {x: 1, y: "foo"}
      tup2 = {x: 3}
      tup3 = {y: "bar", x: 42}

      ptr = Pointer(typeof(tup1, tup2, tup3)).malloc(1_u64)

      # Here the compiler should reorder the values
      # inside tup3 to match the order of tup1
      ptr.value = tup3

      ptr.value[:x]
      )).to_i == 42
  end

  it "upcasts named tuple union to compatible named tuple" do
    assert run(%(
      def foo
        if 1 == 2
          {x: 1, y: "foo"} || {x: 3}
        else
          {y: "bar", x: 42}
        end
      end

      foo[:x]
      )).to_i == 42
  end

  it "assigns named tuple inside union to union with compatible named tuple" do
    assert run(%(
      tup1 = {x: 21, y: "foo"}
      tup2 = {x: 3}

      union1 = tup1 || tup2

      tup3 = {y: "bar", x: 42}
      tup4 = {x: 4}

      union2 = tup3 || tup4

      ptr = Pointer(typeof(union1, union2)).malloc(1_u64)

      # Here the compiler should reorder the values inside
      # tup3 inside union2 to match the order of tup1
      ptr.value = union2

      ptr.value[:x]
      )).to_i == 42
  end

  it "upcasts named tuple inside union to union with compatible named tuple" do
    assert run(%(
      def foo
        if 1 == 2
          tup1 = {x: 21, y: "foo"}
          tup2 = {x: 3}
          union1 = tup1 || tup2
          union1
        else
          tup3 = {y: "bar", x: 42}
          tup4 = {x: 4}
          union2 = tup3 || tup4

          # Here the compiler should reorder the values inside
          # tup3 inside union2 to match the order of tup1
          union2
        end
      end

      foo[:x]
      )).to_i == 42
  end

  it "allows named tuple covariance" do
    assert run(%(
       class Obj
         def initialize
           @tuple = {foo: Foo.new}
         end

         def tuple=(@tuple)
         end

         def tuple
           @tuple
         end
       end

       class Foo
         def bar
           21
         end
       end

       class Bar < Foo
         def bar
           42
         end
       end

       obj = Obj.new
       obj.tuple = {foo: Bar.new}
       obj.tuple[:foo].bar
       )).to_i == 42
  end

  it "merges two named tuple types with same keys but different types (1)" do
    assert run(%(
       def foo
         if 1 == 2
           {x: "foo", y: 10}
         else
           {y: nil, x: "foo"}
         end
       end

       val = foo[:y]
       val || 20
       )).to_i == 20
  end

  it "merges two named tuple types with same keys but different types (2)" do
    assert run(%(
       def foo
         if 1 == 1
           {x: "foo", y: 10}
         else
           {y: nil, x: "foo"}
         end
       end

       val = foo[:y]
       val || 20
       )).to_i == 10
  end

  it "codegens union of tuple of float with tuple of tuple of float" do
    assert run(%(
      a = {x: 1.5}
      b = {x: {22.0, 20.0} }
      c = b || a
      v = c[:x]
      if v.is_a?(Float64)
        10
      else
        v[0].to_i + v[1].to_i
      end
      )).to_i == 42
  end

  it "provides T as a named tuple literal" do
    assert run(%(
      struct NamedTuple
        def self.foo
          {{ T.class_name }}
        end
      end
      NamedTuple(x: Nil, y: Int32).foo
      )).to_string == "NamedTupleLiteral"
  end
end
