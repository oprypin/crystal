require "spec"

private def method_with_named_args(chan, x = 1, y = 2)
  chan.send(x + y)
end

private def method_named(expected_named)
  assert Fiber.current.name == expected_named
end

describe "concurrent" do
  it "does four things concurrently" do
    a, b, c, d = parallel(1 + 2, "hello".size, [1, 2, 3, 4].size, nil)
    assert a == 3
    assert b == 5
    assert c == 4
    assert d.nil?
  end

  it "uses spawn macro" do
    chan = Channel(Int32).new

    spawn method_with_named_args(chan)
    assert chan.receive == 3

    spawn method_with_named_args(chan, y: 20)
    assert chan.receive == 21

    spawn method_with_named_args(chan, x: 10, y: 20)
    assert chan.receive == 30
  end

  it "spawns named" do
    spawn(name: "sub") do
      assert Fiber.current.name == "sub"
    end
    Fiber.yield
  end

  it "spawns named with macro" do
    spawn method_named("foo"), name: "foo"
    Fiber.yield
  end
end
