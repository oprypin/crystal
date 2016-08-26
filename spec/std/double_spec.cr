require "spec"

describe "Double" do
  describe "**" do
    it { assert (2.5 ** 2).close?(6.25, 0.0001) }
    it { assert (2.5 ** 2.5_f32).close?(9.882117688026186, 0.0001) }
    it { assert (2.5 ** 2.5).close?(9.882117688026186, 0.0001) }
  end
end
