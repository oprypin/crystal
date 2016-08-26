require "spec"

describe "UInt" do
  it "compares with <=>" do
    assert (1_u32 <=> 0_u32) == 1
    assert (0_u32 <=> 0_u32) == 0
    assert (0_u32 <=> 1_u32) == -1
  end
end
