require "spec"

describe Concurrent::Future do
  describe "delay" do
    it "computes a value" do
      chan = Channel(Int32).new(1)

      d = delay(0.05) { chan.receive }
      assert d.delayed? == true

      chan.send 3

      assert d.get == 3
      assert d.completed? == true
    end

    it "cancels" do
      d = delay(1) { 42 }
      assert d.delayed? == true

      d.cancel
      assert d.canceled? == true

      expect_raises(Concurrent::CanceledError) { d.get }
    end

    it "raises" do
      d = delay(0.001) { raise IndexError.new("test error") }

      expect_raises(IndexError) { d.get }
      assert d.completed? == true
    end
  end

  describe "future" do
    it "computes a value" do
      chan = Channel(Int32).new(1)

      f = future { chan.receive }
      assert f.running? == true

      chan.send 42
      Fiber.yield
      assert f.completed? == true

      assert f.get == 42
      assert f.completed? == true
    end

    it "can't cancel a completed computation" do
      f = future { 42 }
      assert f.running? == true

      assert f.get == 42
      assert f.completed? == true

      f.cancel
      assert f.canceled? == false
    end

    it "raises" do
      f = future { raise IndexError.new("test error") }
      assert f.running? == true

      Fiber.yield
      assert f.completed? == true

      expect_raises(IndexError) { f.get }
      assert f.completed? == true
    end
  end

  describe "lazy" do
    it "computes a value" do
      chan = Channel(Int32).new(1)

      f = lazy { chan.receive }
      assert f.idle? == true

      chan.send 42
      Fiber.yield
      assert f.idle? == true

      assert f.get == 42
      assert f.completed? == true
    end

    it "cancels" do
      l = lazy { 42 }
      assert l.idle? == true

      l.cancel
      assert l.canceled? == true

      expect_raises(Concurrent::CanceledError) { l.get }
    end

    it "raises" do
      f = lazy { raise IndexError.new("test error") }
      assert f.idle? == true

      Fiber.yield
      assert f.idle? == true

      expect_raises(IndexError) { f.get }
      assert f.completed? == true
    end
  end
end
