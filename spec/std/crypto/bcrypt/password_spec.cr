require "spec"
require "crypto/bcrypt/password"

describe "Crypto::Bcrypt::Password" do
  describe "new" do
    password = Crypto::Bcrypt::Password.new("$2a$08$K8y0i4Wyqyei3SiGHLEd.OweXJt7sno2HdPVrMvVf06kGgAZvPkga")

    it "parses version" do
      assert password.version == "2a"
    end

    it "parses cost" do
      assert password.cost == 8
    end

    it "parses salt" do
      assert password.salt == "K8y0i4Wyqyei3SiGHLEd.O"
    end

    it "parses digest" do
      assert password.digest == "weXJt7sno2HdPVrMvVf06kGgAZvPkga"
    end
  end

  describe "create" do
    password = Crypto::Bcrypt::Password.create("super secret", 5)

    it "uses cost" do
      assert password.cost == 5
    end

    it "generates salt" do
      assert password.salt
    end

    it "generates digest" do
      assert password.digest
    end
  end

  describe "==" do
    password = Crypto::Bcrypt::Password.create("secret", 4)

    it "verifies password is incorrect" do
      assert (password == "wrong") == false
    end

    it "verifies password is correct" do
      assert (password == "secret") == true
    end
  end
end
