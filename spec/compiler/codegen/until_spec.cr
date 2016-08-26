require "../../spec_helper"

describe "Codegen: until" do
  it "codegens until" do
    assert run(%(
      a = 1
      until a == 10
        a = a + 1
      end
      a
    )).to_i == 10
  end
end
