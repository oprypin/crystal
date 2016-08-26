require "spec"
require "http/server"

describe HTTP::LogHandler do
  it "logs" do
    io = MemoryIO.new
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    called = false
    log_io = MemoryIO.new
    handler = HTTP::LogHandler.new(log_io)
    handler.next = ->(ctx : HTTP::Server::Context) { called = true }
    handler.call(context)
    assert log_io.to_s =~ %r(GET / - 200 \(\d.+\))
    assert called == true
  end

  it "does log errors" do
    io = MemoryIO.new
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    called = false
    log_io = MemoryIO.new
    handler = HTTP::LogHandler.new(log_io)
    handler.next = ->(ctx : HTTP::Server::Context) { raise "foo" }
    expect_raises do
      handler.call(context)
    end
    assert log_io.to_s =~ %r(GET / - Unhandled exception:)
  end
end
