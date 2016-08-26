require "spec"
require "system"

describe System do
  describe "hostname" do
    it "returns current hostname" do
      shell_hostname = `hostname`.strip
      assert $?.success? == true # The hostname command has to be available
      hostname = System.hostname
      assert hostname == shell_hostname
    end
  end
end
