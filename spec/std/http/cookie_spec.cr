require "spec"
require "http/cookie"

def parse_first_cookie(header)
  cookies = HTTP::Cookie::Parser.parse_cookies(header)
  assert cookies.size == 1
  cookies.first
end

def parse_set_cookie(header)
  cookie = HTTP::Cookie::Parser.parse_set_cookie(header)
  assert cookie
  cookie.not_nil!
end

module HTTP
  describe Cookie::Parser do
    describe "parse_cookies" do
      it "parses key=value" do
        cookie = parse_first_cookie("key=value")
        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.to_set_cookie_header == "key=value; path=/"
      end

      it "parses key=" do
        cookie = parse_first_cookie("key=")
        assert cookie.name == "key"
        assert cookie.value == ""
        assert cookie.to_set_cookie_header == "key=; path=/"
      end

      it "parses key=key=value" do
        cookie = parse_first_cookie("key=key=value")
        assert cookie.name == "key"
        assert cookie.value == "key=value"
        assert cookie.to_set_cookie_header == "key=key%3Dvalue; path=/"
      end

      it "parses key=key%3Dvalue" do
        cookie = parse_first_cookie("key=key%3Dvalue")
        assert cookie.name == "key"
        assert cookie.value == "key=value"
        assert cookie.to_set_cookie_header == "key=key%3Dvalue; path=/"
      end

      it "parses key%3Dvalue=value" do
        cookie = parse_first_cookie("key%3Dvalue=value")
        assert cookie.name == "key=value"
        assert cookie.value == "value"
        assert cookie.to_set_cookie_header == "key%3Dvalue=value; path=/"
      end

      it "parses multiple cookies" do
        cookies = Cookie::Parser.parse_cookies("foo=bar; foobar=baz")
        assert cookies.size == 2
        first, second = cookies
        assert first.name == "foo"
        assert second.name == "foobar"
        assert first.value == "bar"
        assert second.value == "baz"
      end
    end

    describe "parse_set_cookie" do
      it "parses path" do
        cookie = parse_set_cookie("key=value; path=/test")
        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.path == "/test"
        assert cookie.to_set_cookie_header == "key=value; path=/test"
      end

      it "parses Secure" do
        cookie = parse_set_cookie("key=value; Secure")
        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.secure == true
        assert cookie.to_set_cookie_header == "key=value; path=/; Secure"
      end

      it "parses HttpOnly" do
        cookie = parse_set_cookie("key=value; HttpOnly")
        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.http_only == true
        assert cookie.to_set_cookie_header == "key=value; path=/; HttpOnly"
      end

      it "parses domain" do
        cookie = parse_set_cookie("key=value; domain=www.example.com")
        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.domain == "www.example.com"
        assert cookie.to_set_cookie_header == "key=value; domain=www.example.com; path=/"
      end

      it "parses expires rfc1123" do
        cookie = parse_set_cookie("key=value; expires=Sun, 06 Nov 1994 08:49:37 GMT")
        time = Time.new(1994, 11, 6, 8, 49, 37)

        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.expires == time
      end

      it "parses expires rfc1036" do
        cookie = parse_set_cookie("key=value; expires=Sunday, 06-Nov-94 08:49:37 GMT")
        time = Time.new(1994, 11, 6, 8, 49, 37)

        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.expires == time
      end

      it "parses expires ansi c" do
        cookie = parse_set_cookie("key=value; expires=Sun Nov  6 08:49:37 1994")
        time = Time.new(1994, 11, 6, 8, 49, 37)

        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.expires == time
      end

      it "parses expires ansi c, variant with zone" do
        cookie = parse_set_cookie("bla=; expires=Thu, 01 Jan 1970 00:00:00 -0000")
        assert cookie.expires == Time.new(1970, 1, 1, 0, 0, 0)
      end

      it "parses full" do
        cookie = parse_set_cookie("key=value; path=/test; domain=www.example.com; HttpOnly; Secure; expires=Sun, 06 Nov 1994 08:49:37 GMT")
        time = Time.new(1994, 11, 6, 8, 49, 37)

        assert cookie.name == "key"
        assert cookie.value == "value"
        assert cookie.path == "/test"
        assert cookie.domain == "www.example.com"
        assert cookie.http_only == true
        assert cookie.secure == true
        assert cookie.expires == time
      end

      it "parse domain as IP" do
        assert parse_set_cookie("a=1; domain=127.0.0.1; path=/; HttpOnly").domain == "127.0.0.1"
      end

      it "parse max-age as seconds from Time.now" do
        cookie = parse_set_cookie("a=1; max-age=10")
        delta = cookie.expires.not_nil! - Time.now
        assert delta > 9.seconds
        assert delta < 11.seconds

        cookie = parse_set_cookie("a=1; max-age=0")
        delta = Time.now - cookie.expires.not_nil!
        assert delta > 0.seconds
        assert delta < 1.seconds
      end
    end

    describe "expired?" do
      it "by max-age=0" do
        assert parse_set_cookie("bla=1; max-age=0").expired? == true
      end

      it "by old date" do
        assert parse_set_cookie("bla=1; expires=Thu, 01 Jan 1970 00:00:00 -0000").expired? == true
      end

      it "not expired" do
        assert parse_set_cookie("bla=1; max-age=1").expired? == false
      end

      it "not expired" do
        assert parse_set_cookie("bla=1; expires=Thu, 01 Jan 2020 00:00:00 -0000").expired? == false
      end

      it "not expired" do
        assert parse_set_cookie("bla=1").expired? == false
      end
    end
  end

  describe Cookies do
    it "allows adding cookies and retrieving" do
      cookies = Cookies.new
      cookies << Cookie.new("a", "b")
      cookies["c"] = Cookie.new("c", "d")
      cookies["d"] = "e"

      assert cookies["a"].value == "b"
      assert cookies["c"].value == "d"
      assert cookies["d"].value == "e"
      assert cookies["a"]?
      assert cookies["e"]?.nil?
      assert cookies.has_key?("a") == true
    end

    describe "adding request headers" do
      it "overwrites a pre-existing Cookie header" do
        headers = Headers.new
        headers["Cookie"] = "some_key=some_value"

        cookies = Cookies.new
        cookies << Cookie.new("a", "b")

        assert headers["Cookie"] == "some_key=some_value"

        cookies.add_request_headers(headers)

        assert headers["Cookie"] == "a=b"
      end

      it "merges multiple cookies into one Cookie header" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b")
        cookies << Cookie.new("c", "d")

        cookies.add_request_headers(headers)

        assert headers["Cookie"] == "a=b; c=d"
      end

      describe "when no cookies are set" do
        it "does not set a Cookie header" do
          headers = Headers.new
          headers["Cookie"] = "a=b"
          cookies = Cookies.new

          assert headers["Cookie"]?
          cookies.add_request_headers(headers)
          assert headers["Cookie"]?.nil?
        end
      end
    end

    describe "adding response headers" do
      it "overwrites all pre-existing Set-Cookie headers" do
        headers = Headers.new
        headers.add("Set-Cookie", "a=b; path=/")
        headers.add("Set-Cookie", "c=d; path=/")

        cookies = Cookies.new
        cookies << Cookie.new("x", "y")

        assert headers.get("Set-Cookie").size == 2
        assert headers.get("Set-Cookie").includes?("a=b; path=/") == true
        assert headers.get("Set-Cookie").includes?("c=d; path=/") == true

        cookies.add_response_headers(headers)

        assert headers.get("Set-Cookie").size == 1
        assert headers.get("Set-Cookie")[0] == "x=y; path=/"
      end

      it "sets one Set-Cookie header per cookie" do
        headers = Headers.new
        cookies = Cookies.new
        cookies << Cookie.new("a", "b")
        cookies << Cookie.new("c", "d")

        assert headers.get?("Set-Cookie").nil?
        cookies.add_response_headers(headers)
        assert headers.get?("Set-Cookie")

        assert headers.get("Set-Cookie").includes?("a=b; path=/") == true
        assert headers.get("Set-Cookie").includes?("c=d; path=/") == true
      end

      describe "when no cookies are set" do
        it "does not set a Set-Cookie header" do
          headers = Headers.new
          headers.add("Set-Cookie", "a=b; path=/")
          cookies = Cookies.new

          assert headers.get?("Set-Cookie")
          cookies.add_response_headers(headers)
          assert headers.get?("Set-Cookie").nil?
        end
      end
    end

    it "disallows adding inconsistent state" do
      cookies = Cookies.new

      expect_raises ArgumentError do
        cookies["a"] = Cookie.new("b", "c")
      end
    end

    it "allows to iterate over the cookies" do
      cookies = Cookies.new
      cookies["a"] = "b"
      cookies.each do |cookie|
        assert cookie.name == "a"
        assert cookie.value == "b"
      end

      cookie = cookies.each.next
      assert cookie == Cookie.new("a", "b")
    end

    it "allows transform to hash" do
      cookies = Cookies.new
      cookies << Cookie.new("a", "b")
      cookies["c"] = Cookie.new("c", "d")
      cookies["d"] = "e"
      cookies_hash = cookies.to_h
      compare_hash = {"a" => Cookie.new("a", "b"), "c" => Cookie.new("c", "d"), "d" => Cookie.new("d", "e")}
      assert cookies_hash == compare_hash
      cookies["x"] = "y"
      assert cookies.to_h != cookies_hash
    end
  end
end
