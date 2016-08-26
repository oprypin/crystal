require "spec"

describe "ENV" do
  it "gets non existent key raises" do
    expect_raises KeyError, "Missing ENV key: \"NON-EXISTENT\"" do
      ENV["NON-EXISTENT"]
    end
  end

  it "gets non existent key as nilable" do
    assert ENV["NON-EXISTENT"]?.nil?
  end

  it "set and gets" do
    assert (ENV["FOO"] = "1") == "1"
    assert ENV["FOO"] == "1"
    assert ENV["FOO"]? == "1"
  end

  it "sets to nil (same as delete)" do
    ENV["FOO"] = "1"
    assert ENV["FOO"]?
    ENV["FOO"] = nil
    assert ENV["FOO"]?.nil?
  end

  it "does has_key?" do
    ENV["FOO"] = "1"
    assert ENV.has_key?("BAR") == false
    assert ENV.has_key?("FOO") == true
  end

  it "deletes a key" do
    ENV["FOO"] = "1"
    assert ENV.delete("FOO") == "1"
    assert ENV.delete("FOO").nil?
    assert ENV.has_key?("FOO") == false
  end

  it "does .keys" do
    %w(FOO BAR).each { |k| assert !ENV.keys.includes?(k) }
    ENV["FOO"] = ENV["BAR"] = "1"
    %w(FOO BAR).each { |k| assert ENV.keys.includes?(k) }
  end

  it "does .values" do
    [1, 2].each { |i| assert !ENV.values.includes?("SOMEVALUE_#{i}") }
    ENV["FOO"] = "SOMEVALUE_1"
    ENV["BAR"] = "SOMEVALUE_2"
    [1, 2].each { |i| assert ENV.values.includes?("SOMEVALUE_#{i}") }
  end

  describe "fetch" do
    it "fetches with one argument" do
      ENV["1"] = "2"
      assert ENV.fetch("1") == "2"
    end

    it "fetches with default value" do
      ENV["1"] = "2"
      assert ENV.fetch("1", "3") == "2"
      assert ENV.fetch("2", "3") == "3"
    end

    it "fetches with block" do
      ENV["1"] = "2"
      assert ENV.fetch("1") { |k| k + "block" } == "2"
      assert ENV.fetch("2") { |k| k + "block" } == "2block"
    end

    it "fetches and raises" do
      ENV["1"] = "2"
      expect_raises KeyError, "Missing ENV key: \"2\"" do
        ENV.fetch("2")
      end
    end
  end
end
