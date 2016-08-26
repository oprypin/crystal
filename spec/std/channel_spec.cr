require "spec"

describe Channel do
  it "creates unbuffered with no arguments" do
    assert Channel(Int32).new.is_a?(Channel::Unbuffered(Int32))
  end

  it "creates buffered with capacity argument" do
    assert Channel(Int32).new(32).is_a?(Channel::Buffered(Int32))
  end

  it "send returns channel" do
    channel = Channel(Int32).new(1)
    assert channel.send(1).same?(channel)
  end

  it "does receive_first" do
    channel = Channel(Int32).new(1)
    channel.send(1)
    assert Channel.receive_first(Channel(Int32).new, channel) == 1
  end

  it "does send_first" do
    ch1 = Channel(Int32).new(1)
    ch2 = Channel(Int32).new(1)
    ch1.send(1)
    Channel.send_first(2, ch1, ch2)
    assert ch2.receive == 2
  end
end

describe Channel::Unbuffered do
  it "pings" do
    ch = Channel::Unbuffered(Int32).new
    spawn { ch.send(ch.receive) }
    ch.send 123
    assert ch.receive == 123
  end

  it "blocks if there is no receiver" do
    ch = Channel::Unbuffered(Int32).new
    state = 0
    spawn do
      state = 1
      ch.send 123
      state = 2
    end

    Fiber.yield
    assert state == 1
    assert ch.receive == 123
    assert state == 1
    Fiber.yield
    assert state == 2
  end

  it "deliver many senders" do
    ch = Channel::Unbuffered(Int32).new
    spawn { ch.send 1; ch.send 4 }
    spawn { ch.send 2; ch.send 5 }
    spawn { ch.send 3; ch.send 6 }

    assert (1..6).map { ch.receive }.sort == [1, 2, 3, 4, 5, 6]
  end

  it "gets not full when there is a sender" do
    ch = Channel::Unbuffered(Int32).new
    assert ch.full? == true
    assert ch.empty? == true
    spawn { ch.send 123 }
    Fiber.yield
    assert ch.empty? == false
    assert ch.full? == true
    assert ch.receive == 123
  end

  it "works with select" do
    ch1 = Channel::Unbuffered(Int32).new
    ch2 = Channel::Unbuffered(Int32).new
    spawn { ch1.send 123 }
    assert Channel.select(ch1.receive_select_action, ch2.receive_select_action) == {0, 123}
  end

  it "works with select else" do
    ch1 = Channel::Unbuffered(Int32).new
    assert Channel.select({ch1.receive_select_action}, true) == {1, nil}
  end

  it "can send and receive nil" do
    ch = Channel::Unbuffered(Nil).new
    spawn { ch.send nil }
    Fiber.yield
    assert ch.empty? == false
    assert ch.receive.nil?
    assert ch.empty? == true
  end

  it "can be closed" do
    ch = Channel::Unbuffered(Int32).new
    assert ch.closed? == false
    assert ch.close.nil?
    assert ch.closed? == true
    expect_raises(Channel::ClosedError) { ch.receive }
  end

  it "can be closed after sending" do
    ch = Channel::Unbuffered(Int32).new
    spawn { ch.send 123; ch.close }
    assert ch.receive == 123
    expect_raises(Channel::ClosedError) { ch.receive }
  end

  it "can be closed from different fiber" do
    ch = Channel::Unbuffered(Int32).new
    received = false
    spawn { expect_raises(Channel::ClosedError) { ch.receive }; received = true }
    Fiber.yield
    ch.close
    Fiber.yield
    assert received == true
  end

  it "cannot send if closed" do
    ch = Channel::Unbuffered(Int32).new
    ch.close
    expect_raises(Channel::ClosedError) { ch.send 123 }
  end

  it "can receive? when closed" do
    ch = Channel::Unbuffered(Int32).new
    ch.close
    assert ch.receive?.nil?
  end

  it "can receive? when not empty" do
    ch = Channel::Unbuffered(Int32).new
    spawn { ch.send 123 }
    assert ch.receive? == 123
  end
end

describe Channel::Buffered do
  it "pings" do
    ch = Channel::Buffered(Int32).new
    spawn { ch.send(ch.receive) }
    ch.send 123
    assert ch.receive == 123
  end

  it "blocks when full" do
    ch = Channel::Buffered(Int32).new(2)
    freed = false
    spawn { 2.times { ch.receive }; freed = true }

    ch.send 1
    assert ch.full? == false
    assert freed == false

    ch.send 2
    assert ch.full? == true
    assert freed == false

    ch.send 3
    assert ch.full? == false
    assert freed == true
  end

  it "doesn't block when not full" do
    ch = Channel::Buffered(Int32).new
    done = false
    spawn { ch.send 123; done = true }
    assert done == false
    Fiber.yield
    assert done == true
  end

  it "gets ready with data" do
    ch = Channel::Buffered(Int32).new
    assert ch.empty? == true
    ch.send 123
    assert ch.empty? == false
  end

  it "works with select" do
    ch1 = Channel::Buffered(Int32).new
    ch2 = Channel::Buffered(Int32).new
    spawn { ch1.send 123 }
    assert Channel.select(ch1.receive_select_action, ch2.receive_select_action) == {0, 123}
  end

  it "can send and receive nil" do
    ch = Channel::Buffered(Nil).new
    spawn { ch.send nil }
    Fiber.yield
    assert ch.empty? == false
    assert ch.receive.nil?
    assert ch.empty? == true
  end

  it "can be closed" do
    ch = Channel::Buffered(Int32).new
    assert ch.closed? == false
    ch.close
    assert ch.closed? == true
    expect_raises(Channel::ClosedError) { ch.receive }
  end

  it "can be closed after sending" do
    ch = Channel::Buffered(Int32).new
    spawn { ch.send 123; ch.close }
    assert ch.receive == 123
    expect_raises(Channel::ClosedError) { ch.receive }
  end

  it "can be closed from different fiber" do
    ch = Channel::Buffered(Int32).new
    received = false
    spawn { expect_raises(Channel::ClosedError) { ch.receive }; received = true }
    Fiber.yield
    ch.close
    Fiber.yield
    assert received == true
  end

  it "cannot send if closed" do
    ch = Channel::Buffered(Int32).new
    ch.close
    expect_raises(Channel::ClosedError) { ch.send 123 }
  end

  it "can receive? when closed" do
    ch = Channel::Buffered(Int32).new
    ch.close
    assert ch.receive?.nil?
  end

  it "can receive? when not empty" do
    ch = Channel::Buffered(Int32).new
    spawn { ch.send 123 }
    assert ch.receive? == 123
  end

  it "does inspect on unbuffered channel" do
    ch = Channel::Unbuffered(Int32).new
    assert ch.inspect == "#<Channel::Unbuffered(Int32):0x#{ch.object_id.to_s(16)}>"
  end

  it "does inspect on buffered channel" do
    ch = Channel::Buffered(Int32).new(10)
    assert ch.inspect == "#<Channel::Buffered(Int32):0x#{ch.object_id.to_s(16)}>"
  end
end
