require "spec"
require "secure_random"

describe SecureRandom do
  describe "base64" do
    it "gets base64 with default number of digits" do
      base64 = SecureRandom.base64
      assert base64.size == 24
      assert base64 !~ /\n/
    end

    it "gets base64 with requested number of digits" do
      base64 = SecureRandom.base64(50)
      assert base64.size == 68
      assert base64 !~ /\n/
    end
  end

  describe "urlsafe_base64" do
    it "gets urlsafe base64 with default number of digits" do
      base64 = SecureRandom.urlsafe_base64
      assert (base64.size <= 24) == true
      assert base64 !~ /[\n+\/=]/
    end

    it "gets urlsafe base64 with requested number of digits" do
      base64 = SecureRandom.urlsafe_base64(50)
      assert (base64.size >= 24 && base64.size <= 68) == true
      assert base64 !~ /[\n+\/=]/
    end

    it "keeps padding" do
      base64 = SecureRandom.urlsafe_base64(padding: true)
      assert base64[-2..-1] == "=="
    end
  end

  describe "hex" do
    it "gets hex with default number of digits" do
      hex = SecureRandom.hex
      assert hex.size == 32
      hex.each_char do |char|
        assert ('0' <= char <= '9' || 'a' <= char <= 'f') == true
      end
    end

    it "gets hex with requested number of digits" do
      hex = SecureRandom.hex(50)
      assert hex.size == 100
      hex.each_char do |char|
        assert ('0' <= char <= '9' || 'a' <= char <= 'f') == true
      end
    end
  end

  describe "random_bytes" do
    it "gets random bytes with default number of digits" do
      bytes = SecureRandom.random_bytes
      assert bytes.size == 16
    end

    it "gets random bytes with requested number of digits" do
      bytes = SecureRandom.random_bytes(50)
      assert bytes.size == 50
    end
  end

  describe "uuid" do
    it "gets uuid" do
      uuid = SecureRandom.uuid
      assert uuid =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{4}[0-9a-f]{8}\Z/
    end
  end
end
