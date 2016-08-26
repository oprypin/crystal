require "spec"

describe "Bool" do
  describe "!" do
    it { assert (!true) == false }
    it { assert (!false) == true }
  end

  describe "|" do
    it { assert (false | false) == false }
    it { assert (false | true) == true }
    it { assert (true | false) == true }
    it { assert (true | true) == true }
  end

  describe "&" do
    it { assert (false & false) == false }
    it { assert (false & true) == false }
    it { assert (true & false) == false }
    it { assert (true & true) == true }
  end

  describe "^" do
    it { assert (false ^ false) == false }
    it { assert (false ^ true) == true }
    it { assert (true ^ false) == true }
    it { assert (true ^ true) == false }
  end

  describe "hash" do
    it { assert true.hash == 1 }
    it { assert false.hash == 0 }
  end

  describe "to_s" do
    it { assert true.to_s == "true" }
    it { assert false.to_s == "false" }
  end

  describe "clone" do
    it { assert true.clone == true }
    it { assert false.clone == false }
  end
end
