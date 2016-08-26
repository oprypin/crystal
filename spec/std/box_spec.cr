require "spec"

describe "Box" do
  it "boxes and unboxes" do
    a = 1
    box = Box.box(a)
    assert Box(Int32).unbox(box) == 1
  end
end
