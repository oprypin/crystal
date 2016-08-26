require "spec"

describe "Proc" do
  it "does to_s(io)" do
    str = MemoryIO.new
    f = ->(x : Int32) { x.to_f }
    f.to_s(str)
    assert str.to_s == "#<Proc(Int32, Float64):0x#{f.pointer.address.to_s(16)}>"
  end

  it "does to_s(io) when closured" do
    str = MemoryIO.new
    a = 1.5
    f = ->(x : Int32) { x + a }
    f.to_s(str)
    assert str.to_s == "#<Proc(Int32, Float64):0x#{f.pointer.address.to_s(16)}:closure>"
  end

  it "does to_s" do
    str = MemoryIO.new
    f = ->(x : Int32) { x.to_f }
    assert f.to_s == "#<Proc(Int32, Float64):0x#{f.pointer.address.to_s(16)}>"
  end

  it "does to_s when closured" do
    str = MemoryIO.new
    a = 1.5
    f = ->(x : Int32) { x + a }
    assert f.to_s == "#<Proc(Int32, Float64):0x#{f.pointer.address.to_s(16)}:closure>"
  end

  it "gets pointer" do
    f = ->{ 1 }
    assert f.pointer.address > 0
  end

  it "gets closure data for non-closure" do
    f = ->{ 1 }
    assert f.closure_data.address == 0
    assert f.closure? == false
  end

  it "gets closure data for closure" do
    a = 1
    f = ->{ a }
    assert f.closure_data.address > 0
    assert f.closure? == true
  end

  it "does new" do
    a = 1
    f = ->(x : Int32) { x + a }
    f2 = Proc(Int32, Int32).new(f.pointer, f.closure_data)
    assert f2.call(3) == 4
  end

  it "does ==" do
    func = ->{ 1 }
    assert func == func
    func2 = ->{ 1 }
    assert func2 != func
  end

  it "clones" do
    func = ->{ 1 }
    assert func.clone == func
  end

  it "#arity" do
    f = ->(x : Int32, y : Int32) {}
    assert f.arity == 2
  end

  it "#partial" do
    f = ->(x : Int32, y : Int32, z : Int32) { x + y + z }
    assert f.call(1, 2, 3) == 6

    f2 = f.partial(10)
    assert f2.call(2, 3) == 15
    assert f2.call(2, 10) == 22

    f3 = f2.partial(20)
    assert f3.call(3) == 33
    assert f3.call(10) == 40

    f = ->(x : String, y : Char) { x.index(y) }
    assert f.call("foo", 'o') == 1

    f2 = f.partial("bar")
    assert f2.call('a') == 1
    assert f2.call('r') == 2
  end
end
