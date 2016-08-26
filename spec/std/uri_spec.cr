require "spec"
require "uri"

private def assert_uri(string, scheme = nil, host = nil, port = nil, path = "", query = nil, user = nil, password = nil, fragment = nil, opaque = nil)
  it "parse #{string}" do
    uri = URI.parse(string)
    assert uri.scheme == scheme
    assert uri.host == host
    assert uri.port == port
    assert uri.path == path
    assert uri.query == query
    assert uri.user == user
    assert uri.password == password
    assert uri.fragment == fragment
    assert uri.opaque == opaque
  end
end

describe "URI" do
  assert_uri("http://www.example.com", scheme: "http", host: "www.example.com")
  assert_uri("http://www.example.com:81", scheme: "http", host: "www.example.com", port: 81)
  assert_uri("http://www.example.com/foo", scheme: "http", host: "www.example.com", path: "/foo")
  assert_uri("http://www.example.com/foo?q=1", scheme: "http", host: "www.example.com", path: "/foo", query: "q=1")
  assert_uri("http://www.example.com?q=1", scheme: "http", host: "www.example.com", query: "q=1")
  assert_uri("https://www.example.com", scheme: "https", host: "www.example.com")
  assert_uri("https://alice:pa55w0rd@www.example.com", scheme: "https", host: "www.example.com", user: "alice", password: "pa55w0rd")
  assert_uri("https://alice@www.example.com", scheme: "https", host: "www.example.com", user: "alice", password: nil)
  assert_uri("https://%3AD:%40_%40@www.example.com", scheme: "https", host: "www.example.com", user: ":D", password: "@_@")
  assert_uri("https://www.example.com/#top", scheme: "https", host: "www.example.com", path: "/", fragment: "top")
  assert_uri("http://www.foo-bar.example.com", scheme: "http", host: "www.foo-bar.example.com")
  assert_uri("/foo", path: "/foo")
  assert_uri("/foo?q=1", path: "/foo", query: "q=1")
  assert_uri("mailto:foo@example.org", scheme: "mailto", path: nil, opaque: "foo@example.org")

  it { assert URI.parse("http://www.example.com/foo").full_path == "/foo" }
  it { assert URI.parse("http://www.example.com").full_path == "/" }
  it { assert URI.parse("http://www.example.com/foo?q=1").full_path == "/foo?q=1" }
  it { assert URI.parse("http://www.example.com/?q=1").full_path == "/?q=1" }
  it { assert URI.parse("http://www.example.com?q=1").full_path == "/?q=1" }
  it { assert URI.parse("http://test.dev/a%3Ab").full_path == "/a%3Ab" }

  it "implements ==" do
    assert URI.parse("http://example.com") == URI.parse("http://example.com")
  end

  it "implements hash" do
    assert URI.parse("http://example.com").hash == URI.parse("http://example.com").hash
  end

  describe "userinfo" do
    it { assert URI.parse("http://www.example.com").userinfo.nil? }
    it { assert URI.parse("http://foo@www.example.com").userinfo == "foo" }
    it { assert URI.parse("http://foo:bar@www.example.com").userinfo == "foo:bar" }
  end

  describe "to_s" do
    it { assert URI.new("http", "www.example.com").to_s == "http://www.example.com" }
    it { assert URI.new("http", "www.example.com", 80).to_s == "http://www.example.com" }
    it do
      u = URI.new("http", "www.example.com")
      u.user = "alice"
      assert u.to_s == "http://alice@www.example.com"
      u.password = "s3cr3t"
      assert u.to_s == "http://alice:s3cr3t@www.example.com"
    end
    it do
      u = URI.new("http", "www.example.com")
      u.user = ":D"
      assert u.to_s == "http://%3AD@www.example.com"
      u.password = "@_@"
      assert u.to_s == "http://%3AD:%40_%40@www.example.com"
    end
    it { assert URI.new("http", "www.example.com", user: "@al:ce", password: "s/cr3t").to_s == "http://%40al%3Ace:s%2Fcr3t@www.example.com" }
    it { assert URI.new("http", "www.example.com", fragment: "top").to_s == "http://www.example.com#top" }
    it { assert URI.new("http", "www.example.com", 1234).to_s == "http://www.example.com:1234" }
    it { assert URI.new("http", "www.example.com", 80, "/hello").to_s == "http://www.example.com/hello" }
    it { assert URI.new("http", "www.example.com", 80, "/hello", "a=1").to_s == "http://www.example.com/hello?a=1" }
    it { assert URI.new("mailto", opaque: "foo@example.com").to_s == "mailto:foo@example.com" }
  end

  describe ".unescape" do
    {
      {"hello", "hello"},
      {"hello%20world", "hello world"},
      {"hello+world", "hello+world"},
      {"hello%", "hello%"},
      {"hello%2", "hello%2"},
      {"hello%2B", "hello+"},
      {"hello%2Bworld", "hello+world"},
      {"hello%2%2Bworld", "hello%2+world"},
      {"%E3%81%AA%E3%81%AA", "なな"},
      {"%e3%81%aa%e3%81%aa", "なな"},
      {"%27Stop%21%27+said+Fred", "'Stop!'+said+Fred"},
    }.each do |(from, to)|
      it "unescapes #{from}" do
        assert URI.unescape(from) == to
      end

      it "unescapes #{from} to IO" do
        assert String.build do |str|
          URI.unescape(from, str)
        end == to
      end
    end

    it "unescapes plus to space" do
      assert URI.unescape("hello+world", plus_to_space: true) == "hello world"
      assert String.build do |str|
        URI.unescape("hello+world", str, plus_to_space: true)
      end == "hello world"
    end

    it "does not unescape string when block returns true" do
      assert URI.unescape("hello%26world") { |byte| URI.reserved? byte } == "hello%26world"
    end
  end

  describe ".escape" do
    [
      {"hello", "hello"},
      {"hello%20world", "hello world"},
      {"hello%25", "hello%"},
      {"hello%252", "hello%2"},
      {"hello%2B", "hello+"},
      {"hello%2Bworld", "hello+world"},
      {"hello%252%2Bworld", "hello%2+world"},
      {"%E3%81%AA%E3%81%AA", "なな"},
      {"%27Stop%21%27%20said%20Fred", "'Stop!' said Fred"},
      {"%0A", "\n"},
    ].each do |(from, to)|
      it "escapes #{to}" do
        assert URI.escape(to) == from
      end

      it "escapes #{to} to IO" do
        assert String.build do |str|
          URI.escape(to, str)
        end == from
      end
    end

    describe "invalid utf8 strings" do
      input = String.new(1) { |buf| buf.value = 255_u8; {1, 0} }

      it "escapes without failing" do
        assert URI.escape(input) == "%FF"
      end

      it "escapes to IO without failing" do
        assert String.build do |str|
          URI.escape(input, str)
        end == "%FF"
      end
    end

    it "escape space to plus when space_to_plus flag is true" do
      assert URI.escape("hello world", space_to_plus: true) == "hello+world"
      assert URI.escape("'Stop!' said Fred", space_to_plus: true) == "%27Stop%21%27+said+Fred"
    end

    it "does not escape character when block returns true" do
      assert URI.unescape("hello&world") { |byte| URI.reserved? byte } == "hello&world"
    end
  end

  describe "reserved?" do
    reserved_chars = Set.new([':', '/', '?', '#', '[', ']', '@', '!', '$', '&', '\'', '(', ')', '*', '+', ',', ';', '='])

    ('\u{00}'..'\u{7F}').each do |char|
      ok = reserved_chars.includes? char
      it "should return #{ok} on given #{char}" do
        assert URI.reserved?(char.ord.to_u8) == ok
      end
    end
  end

  describe "unreserved?" do
    unreserved_chars = Set.new(('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '.', '-', '~'])

    ('\u{00}'..'\u{7F}').each do |char|
      ok = unreserved_chars.includes? char
      it "should return #{ok} on given #{char}" do
        assert URI.unreserved?(char.ord.to_u8) == ok
      end
    end
  end
end
