require "spec"
require "http/client/response"

class HTTP::Client
  describe Response do
    it "parses response with body" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nhelloworld"))
      assert response.version == "HTTP/1.1"
      assert response.status_code == 200
      assert response.status_message == "OK"
      assert response.headers["content-type"] == "text/plain"
      assert response.headers["content-length"] == "5"
      assert response.body == "hello"
    end

    it "parses response with streamed body" do
      Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nhelloworld")) do |response|
        assert response.version == "HTTP/1.1"
        assert response.status_code == 200
        assert response.status_message == "OK"
        assert response.headers["content-type"] == "text/plain"
        assert response.headers["content-length"] == "5"
        assert response.body?.nil?
        assert response.body_io.gets_to_end == "hello"
      end
    end

    it "parses response with streamed body, huge content-length" do
      Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{UInt64::MAX}\r\n\r\nhelloworld")) do |response|
        assert response.headers["content-length"] == "#{UInt64::MAX}"
      end
    end

    it "parses response with body without \\r" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 5\n\nhelloworld"))
      assert response.version == "HTTP/1.1"
      assert response.status_code == 200
      assert response.status_message == "OK"
      assert response.headers["content-type"] == "text/plain"
      assert response.headers["content-length"] == "5"
      assert response.body == "hello"
    end

    it "parses response with body but without content-length" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\n\r\nhelloworld"))
      assert response.status_code == 200
      assert response.status_message == "OK"
      assert response.headers.size == 0
      assert response.body == "helloworld"
    end

    it "parses response with empty body but without content-length" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 404 Not Found\r\n\r\n"))
      assert response.status_code == 404
      assert response.status_message == "Not Found"
      assert response.headers.size == 0
      assert response.body == ""
    end

    it "parses response without body" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 100 Continue\r\n\r\n"))
      assert response.status_code == 100
      assert response.status_message == "Continue"
      assert response.headers.size == 0
      assert response.body?.nil?
    end

    it "parses response without status message" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200\r\n\r\n"))
      assert response.status_code == 200
      assert response.status_message == ""
      assert response.headers.size == 0
      assert response.body == ""
    end

    it "parses response with duplicated headers" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nWarning: 111 Revalidation failed\r\nWarning: 110 Response is stale\r\n\r\nhelloworld"))
      assert response.headers.get("Warning") == ["111 Revalidation failed", "110 Response is stale"]
    end

    it "parses response with cookies" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nSet-Cookie: a=b\r\nSet-Cookie: c=d\r\n\r\nhelloworld"))
      assert response.cookies["a"].value == "b"
      assert response.cookies["c"].value == "d"
    end

    it "parses response with chunked body" do
      response = Response.from_io(io = MemoryIO.new("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nabcde\r\na\r\n0123456789\r\n0\r\n\r\n"))
      assert response.body == "abcde0123456789"
      assert io.gets.nil?
    end

    it "parses response with streamed chunked body" do
      Response.from_io(io = MemoryIO.new("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nabcde\r\na\r\n0123456789\r\n0\r\n\r\n")) do |response|
        assert response.body_io.gets_to_end == "abcde0123456789"
        assert io.gets.nil?
      end
    end

    it "parses response with chunked body of size 0" do
      response = Response.from_io(io = MemoryIO.new("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n"))
      assert response.body == ""
      assert io.gets.nil?
    end

    it "parses response ignoring body" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nhelloworld"), true)
      assert response.version == "HTTP/1.1"
      assert response.status_code == 200
      assert response.status_message == "OK"
      assert response.headers["content-type"] == "text/plain"
      assert response.headers["content-length"] == "5"
      assert response.body == ""
    end

    it "parses 204 response without body but Content-Length == 0 (#2512)" do
      response = Response.from_io(MemoryIO.new("HTTP/1.1 204 OK\r\nContent-Type: text/plain\r\nContent-Length: 0\r\n\r\n"))
      assert response.version == "HTTP/1.1"
      assert response.status_code == 204
      assert response.status_message == "OK"
      assert response.headers["content-type"] == "text/plain"
      assert response.headers["content-length"] == "0"
      assert response.body == ""
    end

    it "doesn't sets content length for 1xx, 204 or 304" do
      [100, 101, 204, 304].each do |status|
        response = Response.new(status)
        assert response.headers.size == 0
      end
    end

    it "raises when creating 1xx, 204 or 304 with body" do
      [100, 101, 204, 304].each do |status|
        expect_raises ArgumentError do
          Response.new(status, "hello")
        end
      end
    end

    it "serialize with body" do
      headers = HTTP::Headers.new
      headers["Content-Type"] = "text/plain"
      headers["Content-Length"] = "5"

      response = Response.new(200, "hello", headers)
      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nhello"
    end

    it "serialize with body and cookies" do
      headers = HTTP::Headers.new
      headers["Content-Type"] = "text/plain"
      headers["Content-Length"] = "5"
      headers["Set-Cookie"] = "foo=bar; path=/"

      response = Response.new(200, "hello", headers)

      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nSet-Cookie: foo=bar; path=/\r\n\r\nhello"

      assert response.cookies["foo"].value == "bar" # Force lazy initialization

      io.clear
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nSet-Cookie: foo=bar; path=/\r\n\r\nhello"

      response.cookies["foo"] = "baz"
      response.cookies << Cookie.new("quux", "baz")

      io.clear
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nSet-Cookie: foo=baz; path=/\r\nSet-Cookie: quux=baz; path=/\r\n\r\nhello"
    end

    it "sets content length from body" do
      response = Response.new(200, "hello")
      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello"
    end

    it "sets content length even without body" do
      response = Response.new(200)
      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
    end

    it "serialize as chunked with body_io" do
      response = Response.new(200, body_io: MemoryIO.new("hello"))
      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n0\r\n\r\n"
    end

    it "serialize as not chunked with body_io if HTTP/1.0" do
      response = Response.new(200, version: "HTTP/1.0", body_io: MemoryIO.new("hello"))
      io = MemoryIO.new
      response.to_io(io)
      assert io.to_s == "HTTP/1.0 200 OK\r\nContent-Length: 5\r\n\r\nhello"
    end

    it "returns no content_type when header is missing" do
      response = Response.new(200, "")
      assert response.content_type.nil?
      assert response.charset.nil?
    end

    it "returns content type and no charset" do
      response = Response.new(200, "", headers: HTTP::Headers{"Content-Type" => "text/plain"})
      assert response.content_type == "text/plain"
      assert response.charset.nil?
    end

    it "returns content type and charset, removes semicolon" do
      response = Response.new(200, "", headers: HTTP::Headers{"Content-Type" => "text/plain ; charset=UTF-8"})
      assert response.content_type == "text/plain"
      assert response.charset == "UTF-8"
    end

    it "returns content type and no charset, other parameter (#2520)" do
      response = Response.new(200, "", headers: HTTP::Headers{"Content-Type" => "text/plain ; colenc=U"})
      assert response.content_type == "text/plain"
      assert response.charset.nil?
    end

    it "returns content type and charset, removes semicolon, with multiple parameters (#2520)" do
      response = Response.new(200, "", headers: HTTP::Headers{"Content-Type" => "text/plain ; colenc=U ; charset=UTF-8"})
      assert response.content_type == "text/plain"
      assert response.charset == "UTF-8"
    end

    it "creates Response with status code 204, no body and Content-Length == 0 (#2512)" do
      response = Response.new(204, version: "HTTP/1.0", body: "", headers: HTTP::Headers{"Content-Length" => "0"})
      assert response.status_code == 204
      assert response.body == ""
    end

    describe "success?" do
      it "returns true for the 2xx" do
        response = Response.new(200)

        assert response.success? == true
      end

      it "returns false for other ranges" do
        response = Response.new(500)

        assert response.success? == false
      end
    end
  end
end
