require "spec"
require "http/request"

module HTTP
  describe Request do
    it "serialize GET" do
      headers = HTTP::Headers.new
      headers["Host"] = "host.example.org"
      orignal_headers = headers.dup
      request = Request.new "GET", "/", headers

      io = MemoryIO.new
      request.to_io(io)
      assert io.to_s == "GET / HTTP/1.1\r\nHost: host.example.org\r\n\r\n"
      assert headers == orignal_headers
    end

    it "serialize GET (with query params)" do
      headers = HTTP::Headers.new
      headers["Host"] = "host.example.org"
      orignal_headers = headers.dup
      request = Request.new "GET", "/greet?q=hello&name=world", headers

      io = MemoryIO.new
      request.to_io(io)
      assert io.to_s == "GET /greet?q=hello&name=world HTTP/1.1\r\nHost: host.example.org\r\n\r\n"
      assert headers == orignal_headers
    end

    it "serialize GET (with cookie)" do
      headers = HTTP::Headers.new
      headers["Host"] = "host.example.org"
      orignal_headers = headers.dup
      request = Request.new "GET", "/", headers
      request.cookies << Cookie.new("foo", "bar")

      io = MemoryIO.new
      request.to_io(io)
      assert io.to_s == "GET / HTTP/1.1\r\nHost: host.example.org\r\nCookie: foo=bar\r\n\r\n"
      assert headers == orignal_headers
    end

    it "serialize GET (with cookies, from headers)" do
      headers = HTTP::Headers.new
      headers["Host"] = "host.example.org"
      headers["Cookie"] = "foo=bar"
      orignal_headers = headers.dup

      request = Request.new "GET", "/", headers

      io = MemoryIO.new
      request.to_io(io)
      assert io.to_s == "GET / HTTP/1.1\r\nHost: host.example.org\r\nCookie: foo=bar\r\n\r\n"

      assert request.cookies["foo"].value == "bar" # Force lazy initialization

      io.clear
      request.to_io(io)
      assert io.to_s == "GET / HTTP/1.1\r\nHost: host.example.org\r\nCookie: foo=bar\r\n\r\n"

      request.cookies["foo"] = "baz"
      request.cookies["quux"] = "baz"

      io.clear
      request.to_io(io)
      assert io.to_s == "GET / HTTP/1.1\r\nHost: host.example.org\r\nCookie: foo=baz; quux=baz\r\n\r\n"
      assert headers == orignal_headers
    end

    it "serialize POST (with body)" do
      request = Request.new "POST", "/", body: "thisisthebody"
      io = MemoryIO.new
      request.to_io(io)
      assert io.to_s == "POST / HTTP/1.1\r\nContent-Length: 13\r\n\r\nthisisthebody"
    end

    it "parses GET" do
      request = Request.from_io(MemoryIO.new("GET / HTTP/1.1\r\nHost: host.example.org\r\n\r\n")).as(Request)
      assert request.method == "GET"
      assert request.path == "/"
      assert request.headers == {"Host" => "host.example.org"}
    end

    it "parses GET with query params" do
      request = Request.from_io(MemoryIO.new("GET /greet?q=hello&name=world HTTP/1.1\r\nHost: host.example.org\r\n\r\n")).as(Request)
      assert request.method == "GET"
      assert request.path == "/greet"
      assert request.headers == {"Host" => "host.example.org"}
    end

    it "parses GET without \\r" do
      request = Request.from_io(MemoryIO.new("GET / HTTP/1.1\nHost: host.example.org\n\n")).as(Request)
      assert request.method == "GET"
      assert request.path == "/"
      assert request.headers == {"Host" => "host.example.org"}
    end

    it "parses empty header" do
      request = Request.from_io(MemoryIO.new("GET / HTTP/1.1\r\nHost: host.example.org\r\nReferer:\r\n\r\n")).as(Request)
      assert request.method == "GET"
      assert request.path == "/"
      assert request.headers == {"Host" => "host.example.org", "Referer" => ""}
    end

    it "parses GET with cookie" do
      request = Request.from_io(MemoryIO.new("GET / HTTP/1.1\r\nHost: host.example.org\r\nCookie: a=b\r\n\r\n")).as(Request)
      assert request.method == "GET"
      assert request.path == "/"
      assert request.cookies["a"].value == "b"

      # Headers should not be modified (#2920)
      assert request.headers == {"Host" => "host.example.org", "Cookie" => "a=b"}
    end

    it "headers are case insensitive" do
      request = Request.from_io(MemoryIO.new("GET / HTTP/1.1\r\nHost: host.example.org\r\n\r\n")).as(Request)
      headers = request.headers.not_nil!
      assert headers["HOST"] == "host.example.org"
      assert headers["host"] == "host.example.org"
      assert headers["Host"] == "host.example.org"
    end

    it "parses POST (with body)" do
      request = Request.from_io(MemoryIO.new("POST /foo HTTP/1.1\r\nContent-Length: 13\r\n\r\nthisisthebody")).as(Request)
      assert request.method == "POST"
      assert request.path == "/foo"
      assert request.headers == {"Content-Length" => "13"}
      assert request.body == "thisisthebody"
    end

    it "handles malformed request" do
      request = Request.from_io(MemoryIO.new("nonsense"))
      assert request.is_a?(Request::BadRequest)
    end

    describe "keep-alive" do
      it "is false by default in HTTP/1.0" do
        request = Request.new "GET", "/", version: "HTTP/1.0"
        assert request.keep_alive? == false
      end

      it "is true in HTTP/1.0 if `Connection: keep-alive` header is present" do
        headers = HTTP::Headers.new
        headers["Connection"] = "keep-alive"
        orignal_headers = headers.dup
        request = Request.new "GET", "/", headers: headers, version: "HTTP/1.0"
        assert request.keep_alive? == true
        assert headers == orignal_headers
      end

      it "is true by default in HTTP/1.1" do
        request = Request.new "GET", "/", version: "HTTP/1.1"
        assert request.keep_alive? == true
      end

      it "is false in HTTP/1.1 if `Connection: close` header is present" do
        headers = HTTP::Headers.new
        headers["Connection"] = "close"
        orignal_headers = headers.dup
        request = Request.new "GET", "/", headers: headers, version: "HTTP/1.1"
        assert request.keep_alive? == false
        assert headers == orignal_headers
      end
    end

    describe "#path" do
      it "returns parsed path" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        assert request.path == "/api/v3/some/resource"
      end

      it "falls back to /" do
        request = Request.new("GET", "/foo")
        request.path = nil
        assert request.path == "/"
      end
    end

    describe "#path=" do
      it "sets path" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.path = "/api/v2/greet"
        assert request.path == "/api/v2/greet"
      end

      it "updates @resource" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.path = "/api/v2/greet"
        assert request.resource == "/api/v2/greet?filter=hello&world=test"
      end

      it "updates serialized form" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.path = "/api/v2/greet"

        io = MemoryIO.new
        request.to_io(io)
        assert io.to_s == "GET /api/v2/greet?filter=hello&world=test HTTP/1.1\r\n\r\n"
      end
    end

    describe "#query" do
      it "returns request's query" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        assert request.query == "filter=hello&world=test"
      end
    end

    describe "#query=" do
      it "sets query" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.query = "q=isearchforsomething&locale=de"
        assert request.query == "q=isearchforsomething&locale=de"
      end

      it "updates @resource" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.query = "q=isearchforsomething&locale=de"
        assert request.resource == "/api/v3/some/resource?q=isearchforsomething&locale=de"
      end

      it "updates serialized form" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?filter=hello&world=test HTTP/1.1\r\n\r\n")).as(Request)
        request.query = "q=isearchforsomething&locale=de"

        io = MemoryIO.new
        request.to_io(io)
        assert io.to_s == "GET /api/v3/some/resource?q=isearchforsomething&locale=de HTTP/1.1\r\n\r\n"
      end
    end

    describe "#query_params" do
      it "returns parsed HTTP::Params" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?foo=bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params

        assert params["foo"] == "bar"
        assert params.fetch_all("foo") == ["bar", "baz"]
        assert params["baz"] == "qux"
      end

      it "happily parses when query is not a canonical url-encoded string" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?{\"hello\":\"world\"} HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params
        assert params["{\"hello\":\"world\"}"] == ""
        assert params.to_s == "%7B%22hello%22%3A%22world%22%7D="
      end

      it "affects #query when modified" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?foo=bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params

        params["foo"] = "not-bar"
        assert request.query == "foo=not-bar&foo=baz&baz=qux"
      end

      it "updates @resource when modified" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?foo=bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params

        params["foo"] = "not-bar"
        assert request.resource == "/api/v3/some/resource?foo=not-bar&foo=baz&baz=qux"
      end

      it "updates serialized form when modified" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?foo=bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params

        params["foo"] = "not-bar"

        io = MemoryIO.new
        request.to_io(io)
        assert io.to_s == "GET /api/v3/some/resource?foo=not-bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n"
      end

      it "is affected when #query is modified" do
        request = Request.from_io(MemoryIO.new("GET /api/v3/some/resource?foo=bar&foo=baz&baz=qux HTTP/1.1\r\n\r\n")).as(Request)
        params = request.query_params

        new_query = "foo=not-bar&foo=not-baz&not-baz=hello&name=world"
        request.query = new_query
        assert request.query_params.to_s == new_query
      end
    end
  end
end
