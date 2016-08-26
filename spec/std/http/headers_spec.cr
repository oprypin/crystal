require "spec"
require "http/headers"

describe HTTP::Headers do
  it "is empty" do
    headers = HTTP::Headers.new
    assert headers.empty? == true
  end

  it "is case insensitive" do
    headers = HTTP::Headers{"Foo" => "bar"}
    assert headers["foo"] == "bar"
  end

  it "it allows indifferent access for underscore and dash separated keys" do
    headers = HTTP::Headers{"foo_Bar" => "bar", "Foobar-foo" => "baz"}
    assert headers["foo-bar"] == "bar"
    assert headers["foobar_foo"] == "baz"
  end

  it "raises an error if header value contains invalid character" do
    expect_raises ArgumentError do
      headers = HTTP::Headers{"invalid-header" => "\r\nLocation: http://example.com"}
    end
  end

  it "should retain the input casing" do
    headers = HTTP::Headers{"FOO_BAR" => "bar", "Foobar-foo" => "baz"}
    serialized = String.build do |io|
      headers.each do |name, values|
        io << name << ": " << values.first << ";"
      end
    end

    assert serialized == "FOO_BAR: bar;Foobar-foo: baz;"
  end

  it "is gets with []?" do
    headers = HTTP::Headers.new
    assert headers["foo"]?.nil?

    headers["Foo"] = "bar"
    assert headers["foo"]? == "bar"
  end

  it "fetches" do
    headers = HTTP::Headers{"Foo" => "bar"}
    assert headers.fetch("foo") == "bar"
  end

  it "fetches with default value" do
    headers = HTTP::Headers.new
    assert headers.fetch("foo", "baz") == "baz"

    headers["Foo"] = "bar"
    assert headers.fetch("foo", "baz") == "bar"
  end

  it "fetches with block" do
    headers = HTTP::Headers.new
    assert headers.fetch("foo") { |k| "#{k}baz" } == "foobaz"

    headers["Foo"] = "bar"
    assert headers.fetch("foo") { "baz" } == "bar"
  end

  it "has key" do
    headers = HTTP::Headers{"Foo" => "bar"}
    assert headers.has_key?("foo") == true
    assert headers.has_key?("bar") == false
  end

  it "deletes" do
    headers = HTTP::Headers{"Foo" => "bar"}
    assert headers.delete("foo") == "bar"
    assert headers.empty? == true
  end

  it "equals another hash" do
    headers = HTTP::Headers{"Foo" => "bar"}
    assert headers == {"foo" => "bar"}
  end

  it "dups" do
    headers = HTTP::Headers{"Foo" => "bar"}
    other = headers.dup
    assert other.is_a?(HTTP::Headers)
    assert other["foo"] == "bar"

    other["Baz"] = "Qux"
    assert headers["baz"]?.nil?
  end

  it "clones" do
    headers = HTTP::Headers{"Foo" => "bar"}
    other = headers.clone
    assert other.is_a?(HTTP::Headers)
    assert other["foo"] == "bar"

    other["Baz"] = "Qux"
    assert headers["baz"]?.nil?
  end

  it "adds string" do
    headers = HTTP::Headers.new
    headers.add("foo", "bar")
    headers.add("foo", "baz")
    assert headers["foo"] == "bar,baz"
  end

  it "adds array of string" do
    headers = HTTP::Headers.new
    headers.add("foo", "bar")
    headers.add("foo", ["baz", "qux"])
    assert headers["foo"] == "bar,baz,qux"
  end

  it "gets all values" do
    headers = HTTP::Headers{"foo" => "bar"}
    assert headers.get("foo") == ["bar"]

    assert headers.get?("foo") == ["bar"]
    assert headers.get?("qux").nil?
  end

  it "does to_s" do
    headers = HTTP::Headers{"Foo_quux" => "bar", "Baz-Quux" => ["a", "b"]}
    assert headers.to_s == %(HTTP::Headers{"Foo_quux" => "bar", "Baz-Quux" => ["a", "b"]})
  end

  it "merges and return self" do
    headers = HTTP::Headers.new
    assert headers.same? headers.merge!({"foo" => "bar"})
  end

  it "matches word" do
    headers = HTTP::Headers{"foo" => "bar"}
    assert headers.includes_word?("foo", "bar") == true
    assert headers.includes_word?("foo", "ba") == false
    assert headers.includes_word?("foo", "ar") == false
  end

  it "matches word with comma separated value" do
    headers = HTTP::Headers{"foo" => "bar, baz"}
    assert headers.includes_word?("foo", "bar") == true
    assert headers.includes_word?("foo", "baz") == true
    assert headers.includes_word?("foo", "ba") == false
  end

  it "matches word among headers" do
    headers = HTTP::Headers.new
    headers.add("foo", "bar")
    headers.add("foo", "baz")
    assert headers.includes_word?("foo", "bar") == true
    assert headers.includes_word?("foo", "baz") == true
  end

  it "does not matches word if missing header" do
    headers = HTTP::Headers.new
    assert headers.includes_word?("foo", "bar") == false
    assert headers.includes_word?("foo", "") == false
  end

  it "can create header value with all US-ASCII visible chars (#2999)" do
    headers = HTTP::Headers.new
    value = (32..126).map(&.chr).join
    headers.add("foo", value)
  end
end
