require "../../spec_helper"

describe "Code gen: magic constants" do
  it "does __LINE__" do
    assert run(%(
      def foo(x = __LINE__)
        x
      end

      foo
      ), inject_primitives: false).to_i == 6
  end

  it "does __FILE__" do
    assert run(%(
      def foo(x = __FILE__)
        x
      end

      foo
      ), filename: "/foo/bar/baz.cr").to_string == "/foo/bar/baz.cr"
  end

  it "does __DIR__" do
    assert run(%(
      def foo(x = __DIR__)
        x
      end

      foo
      ), filename: "/foo/bar/baz.cr").to_string == "/foo/bar"
  end

  it "does __LINE__ with dispatch" do
    assert run(%(
      def foo(z : Int32, x = __LINE__)
        x
      end

      def foo(z : String)
        1
      end

      a = 1 || "hello"
      foo(a)
      ), inject_primitives: false).to_i == 11
  end

  it "does __LINE__ when specifying one default arg with __FILE__" do
    assert run(%(
      def foo(x, file = __FILE__, line = __LINE__)
        line
      end

      foo 1, "hello"
      ), inject_primitives: false).to_i == 6
  end

  it "does __LINE__ when specifying one normal default arg" do
    assert run(%(
      require "primitives"

      def foo(x, z = 10, line = __LINE__)
        z + line
      end

      foo 1, 20
      ), inject_primitives: false).to_i == 28
  end

  it "does __LINE__ when specifying one middle argument" do
    assert run(%(
      require "primitives"

      def foo(x, line = __LINE__, z = 1)
        z + line
      end

      foo 1, z: 20
      ), inject_primitives: false).to_i == 28
  end

  it "does __LINE__ in macro" do
    assert run(%(
      macro foo(line = __LINE__)
        {{line}}
      end

      foo
      ), inject_primitives: false).to_i == 6
  end

  it "does __FILE__ in macro" do
    assert run(%(
      macro foo(file = __FILE__)
        {{file}}
      end

      foo
      ), filename: "/foo/bar/baz.cr").to_string == "/foo/bar/baz.cr"
  end

  it "does __DIR__ in macro" do
    assert run(%(
      macro foo(dir = __DIR__)
        {{dir}}
      end

      foo
      ), filename: "/foo/bar/baz.cr").to_string == "/foo/bar"
  end
end
