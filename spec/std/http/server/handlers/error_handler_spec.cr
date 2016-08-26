require "spec"
require "http/server"

describe HTTP::ErrorHandler do
  it "rescues from exception" do
    io = MemoryIO.new
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = HTTP::ErrorHandler.new(verbose: true)
    handler.next = ->(ctx : HTTP::Server::Context) { raise "OH NO!" }
    handler.call(context)

    response.close

    io.rewind
    response2 = HTTP::Client::Response.from_io(io)
    assert response2.status_code == 500
    assert response2.status_message == "Internal Server Error"
    assert response2.body =~ /ERROR: OH NO!/
  end

  it "can return a generic error message" do
    io = MemoryIO.new
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = HTTP::ErrorHandler.new
    handler.next = ->(ctx : HTTP::Server::Context) { raise "OH NO!" }
    handler.call(context)
    assert io.to_s.match(/500 Internal Server Error/)
    assert io.to_s.match(/OH NO/).nil?
  end
end
