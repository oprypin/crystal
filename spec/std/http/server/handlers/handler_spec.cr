require "spec"
require "http/server"

class EmptyHTTPHandler < HTTP::Handler
  def call(context)
    call_next(context)
  end
end

describe HTTP::Handler do
  it "responds with not found if there's no next handler" do
    io = MemoryIO.new
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = EmptyHTTPHandler.new
    handler.call(context)
    response.close

    io.rewind
    response = HTTP::Client::Response.from_io(io)
    assert response.status_code == 404
    assert response.body == "Not Found\n"
  end
end
