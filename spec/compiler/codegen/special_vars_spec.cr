require "../../spec_helper"

describe "Codegen: special vars" do
  ["$~", "$?"].each do |name|
    it "codegens #{name}" do
      assert run(%(
        class Object; def not_nil!; self; end; end

        def foo(z)
          #{name} = "hey"
        end

        foo(2)
        #{name}
        )).to_string == "hey"
    end

    it "codegens #{name} with nilable (1)" do
      assert run(%(
        require "prelude"

        def foo
          if 1 == 2
            #{name} = "foo"
          end
        end

        foo

        begin
          #{name}
        rescue ex
          "ouch"
        end
        )).to_string == "ouch"
    end

    it "codegens #{name} with nilable (2)" do
      assert run(%(
        require "prelude"

        def foo
          if 1 == 1
            #{name} = "foo"
          end
        end

        foo

        begin
          #{name}
        rescue ex
          "ouch"
        end
        )).to_string == "foo"
    end
  end

  it "codegens $~ two levels" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def foo
        $? = "hey"
      end

      def bar
        $? = foo
        $?
      end

      bar
      $?
      )).to_string == "hey"
  end

  it "works lazily" do
    assert run(%(
      require "prelude"

      class Foo
        getter string

        def initialize(@string : String)
        end
      end

      def bar(&block : Foo -> _)
        block
      end

      block = bar do |foo|
        case foo.string
        when /foo-(.+)/
          $1
        else
          "baz"
        end
      end
      block.call(Foo.new("foo-bar"))
      )).to_string == "bar"
  end

  it "codegens in block" do
    assert run(%(
      require "prelude"

      class Object; def not_nil!; self; end; end

      def foo
        $~ = "hey"
        yield
      end

      a = nil
      foo do
        a = $~
      end
      a.not_nil!
      )).to_string == "hey"
  end

  it "codegens in block with nested block" do
    assert run(%(
      require "prelude"

      class Object; def not_nil!; self; end; end

      def bar
        yield
      end

      def foo
        bar do
          $~ = "hey"
          yield
        end
      end

      a = nil
      foo do
        a = $~
      end
      a.not_nil!
      )).to_string == "hey"
  end

  it "codegens after block" do
    assert run(%(
      require "prelude"

      class Object; def not_nil!; self; end; end

      def foo
        $~ = "hey"
        yield
      end

      a = nil
      foo {}
      $~
      )).to_string == "hey"
  end

  it "codegens after block 2" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def baz
        $~ = "bye"
      end

      def foo
        baz
        yield
        $~
      end

      foo do
      end
      )).to_string == "bye"
  end

  it "codegens with default argument" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def baz(x = 1)
        $~ = "bye"
      end

      baz
      $~
      )).to_string == "bye"
  end

  it "preserves special vars in macro expansion with call with default arguments (#824)" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def bar(x = 0)
        $~ = "yes"
      end

      macro foo
        bar
        $~
      end

      foo
      )).to_string == "yes"
  end

  it "allows with primitive" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def foo
        $~ = 123
      end

      foo

      v = $~
      v || 456
    )).to_i == 123
  end

  it "allows with struct" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      struct Foo
        def initialize(@x : Int32)
        end

        def x
          @x
        end
      end

      def foo
        $~ = Foo.new(123)
      end

      foo

      v = $~
      if v
        v.x
      else
        456
      end
    )).to_i == 123
  end

  it "preserves special vars if initialized inside block (#2194)" do
    assert run(%(
      class Object; def not_nil!; self; end; end

      def foo
        $~ = "foo"
      end

      def bar
        yield
      end

      bar do
        foo
      end

      v = $~
      if v
        v
      else
        "bar"
      end
      )).to_string == "foo"
  end
end
