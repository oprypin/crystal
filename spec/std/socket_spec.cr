require "spec"
require "socket"

describe Socket do
  # Tests from libc-test:
  # http://repo.or.cz/libc-test.git/blob/master:/src/functional/inet_pton.c
  it "ip?" do
    # dotted-decimal notation
    assert Socket.ip?("0.0.0.0") == true
    assert Socket.ip?("127.0.0.1") == true
    assert Socket.ip?("10.0.128.31") == true
    assert Socket.ip?("255.255.255.255") == true

    # numbers-and-dots notation, but not dotted-decimal
    # Socket.ip?("1.2.03.4").should be_false # fails on darwin
    assert Socket.ip?("1.2.0x33.4") == false
    assert Socket.ip?("1.2.0XAB.4") == false
    assert Socket.ip?("1.2.0xabcd") == false
    assert Socket.ip?("1.0xabcdef") == false
    assert Socket.ip?("00377.0x0ff.65534") == false

    # invalid
    assert Socket.ip?(".1.2.3") == false
    assert Socket.ip?("1..2.3") == false
    assert Socket.ip?("1.2.3.") == false
    assert Socket.ip?("1.2.3.4.5") == false
    assert Socket.ip?("1.2.3.a") == false
    assert Socket.ip?("1.256.2.3") == false
    assert Socket.ip?("1.2.4294967296.3") == false
    assert Socket.ip?("1.2.-4294967295.3") == false
    assert Socket.ip?("1.2. 3.4") == false

    # ipv6
    assert Socket.ip?(":") == false
    assert Socket.ip?("::") == true
    assert Socket.ip?("::1") == true
    assert Socket.ip?(":::") == false
    assert Socket.ip?(":192.168.1.1") == false
    assert Socket.ip?("::192.168.1.1") == true
    assert Socket.ip?("0:0:0:0:0:0:192.168.1.1") == true
    assert Socket.ip?("0:0::0:0:0:192.168.1.1") == true
    # Socket.ip?("::012.34.56.78").should be_false # fails on darwin
    assert Socket.ip?(":ffff:192.168.1.1") == false
    assert Socket.ip?("::ffff:192.168.1.1") == true
    assert Socket.ip?(".192.168.1.1") == false
    assert Socket.ip?(":.192.168.1.1") == false
    assert Socket.ip?("a:0b:00c:000d:E:F::") == true
    # Socket.ip?("a:0b:00c:000d:0000e:f::").should be_false # fails on GNU libc
    assert Socket.ip?("1:2:3:4:5:6::") == true
    assert Socket.ip?("1:2:3:4:5:6:7::") == true
    assert Socket.ip?("1:2:3:4:5:6:7:8::") == false
    assert Socket.ip?("1:2:3:4:5:6:7::9") == false
    assert Socket.ip?("::1:2:3:4:5:6") == true
    assert Socket.ip?("::1:2:3:4:5:6:7") == true
    assert Socket.ip?("::1:2:3:4:5:6:7:8") == false
    assert Socket.ip?("a:b::c:d:e:f") == true
    assert Socket.ip?("ffff:c0a8:5e4") == false
    assert Socket.ip?(":ffff:c0a8:5e4") == false
    assert Socket.ip?("0:0:0:0:0:ffff:c0a8:5e4") == true
    assert Socket.ip?("0:0:0:0:ffff:c0a8:5e4") == false
    assert Socket.ip?("0::ffff:c0a8:5e4") == true
    assert Socket.ip?("::0::ffff:c0a8:5e4") == false
    assert Socket.ip?("c0a8") == false
  end
end

describe Socket::IPAddress do
  it "transforms an IPv4 address into a C struct and back again" do
    addr1 = Socket::IPAddress.new(Socket::Family::INET, "127.0.0.1", 8080.to_i16)
    addr2 = Socket::IPAddress.new(addr1.sockaddr, addr1.addrlen)

    assert addr1.family == addr2.family
    assert addr1.port == addr2.port
    assert addr1.address == addr2.address
    assert addr1.to_s == "127.0.0.1:8080"
  end

  it "transforms an IPv6 address into a C struct and back again" do
    addr1 = Socket::IPAddress.new(Socket::Family::INET6, "2001:db8:8714:3a90::12", 8080.to_i16)
    addr2 = Socket::IPAddress.new(addr1.sockaddr, addr1.addrlen)

    assert addr1.family == addr2.family
    assert addr1.port == addr2.port
    assert addr1.address == addr2.address
    assert addr1.to_s == "2001:db8:8714:3a90::12:8080"
  end
end

describe Socket::UNIXAddress do
  it "does to_s" do
    assert Socket::UNIXAddress.new("some_path").to_s == "some_path"
  end
end

describe UNIXServer do
  it "raises when path is too long" do
    path = "/tmp/crystal-test-too-long-unix-socket-#{("a" * 2048)}.sock"
    expect_raises(ArgumentError, "Path size exceeds the maximum size") { UNIXServer.new(path) }
    assert File.exists?(path) == false
  end

  it "creates the socket file" do
    path = "/tmp/crystal-test-unix-sock"

    UNIXServer.open(path) do
      assert File.exists?(path) == true
    end

    assert File.exists?(path) == false
  end

  it "deletes socket file on close" do
    path = "/tmp/crystal-test-unix-sock"

    begin
      server = UNIXServer.new(path)
      server.close
      assert File.exists?(path) == false
    rescue
      File.delete(path) if File.exists?(path)
    end
  end

  it "raises when socket file already exists" do
    path = "/tmp/crystal-test-unix-sock"
    server = UNIXServer.new(path)

    begin
      expect_raises(Errno) { UNIXServer.new(path) }
    ensure
      server.close
    end
  end

  describe "accept" do
    it "returns the client UNIXSocket" do
      UNIXServer.open("/tmp/crystal-test-unix-sock") do |server|
        UNIXSocket.open("/tmp/crystal-test-unix-sock") do |_|
          client = server.accept
          assert client.is_a?(UNIXSocket)
          client.close
        end
      end
    end

    it "raises when server is closed" do
      server = UNIXServer.new("/tmp/crystal-test-unix-sock")
      exception = nil

      spawn do
        begin
          server.accept
        rescue ex
          exception = ex
        end
      end

      server.close
      until exception
        Fiber.yield
      end

      assert exception.is_a?(IO::Error)
      assert exception.try(&.message) == "closed stream"
    end
  end

  describe "accept?" do
    it "returns the client UNIXSocket" do
      UNIXServer.open("/tmp/crystal-test-unix-sock") do |server|
        UNIXSocket.open("/tmp/crystal-test-unix-sock") do |_|
          client = server.accept?.not_nil!
          assert client.is_a?(UNIXSocket)
          client.close
        end
      end
    end

    it "returns nil when server is closed" do
      server = UNIXServer.new("/tmp/crystal-test-unix-sock")
      ret = :initial

      spawn { ret = server.accept? }
      server.close

      while ret == :initial
        Fiber.yield
      end

      assert ret.nil?
    end
  end
end

describe UNIXSocket do
  it "raises when path is too long" do
    path = "/tmp/crystal-test-too-long-unix-socket-#{("a" * 2048)}.sock"
    expect_raises(ArgumentError, "Path size exceeds the maximum size") { UNIXSocket.new(path) }
    assert File.exists?(path) == false
  end

  it "sends and receives messages" do
    path = "/tmp/crystal-test-unix-sock"

    UNIXServer.open(path) do |server|
      assert server.local_address.family == Socket::Family::UNIX
      assert server.local_address.path == path

      UNIXSocket.open(path) do |client|
        assert client.local_address.family == Socket::Family::UNIX
        assert client.local_address.path == path

        server.accept do |sock|
          assert sock.sync? == server.sync?

          assert sock.local_address.family == Socket::Family::UNIX
          assert sock.local_address.path == ""

          assert sock.remote_address.family == Socket::Family::UNIX
          assert sock.remote_address.path == ""

          client << "ping"
          assert sock.gets(4) == "ping"
          sock << "pong"
          assert client.gets(4) == "pong"
        end
      end

      # test sync flag propagation after accept
      server.sync = !server.sync?

      UNIXSocket.open(path) do |client|
        server.accept do |sock|
          assert sock.sync? == server.sync?
        end
      end
    end
  end

  it "creates a pair of sockets" do
    UNIXSocket.pair do |left, right|
      assert left.local_address.family == Socket::Family::UNIX
      assert left.local_address.path == ""

      left << "ping"
      assert right.gets(4) == "ping"
      right << "pong"
      assert left.gets(4) == "pong"
    end
  end

  it "tests read and write timeouts" do
    UNIXSocket.pair do |left, right|
      # BUG: shrink the socket buffers first
      left.write_timeout = 0.0001
      right.read_timeout = 0.0001
      buf = ("a" * 4096).to_slice

      expect_raises(IO::Timeout, "write timed out") do
        loop { left.write buf }
      end

      expect_raises(IO::Timeout, "read timed out") do
        loop { right.read buf }
      end
    end
  end

  it "tests socket options" do
    UNIXSocket.pair do |left, right|
      size = 12000
      # linux returns size * 2
      sizes = [size, size * 2]

      assert (left.send_buffer_size = size) == size
      assert sizes.includes?(left.send_buffer_size)

      assert (left.recv_buffer_size = size) == size
      assert sizes.includes?(left.recv_buffer_size)
    end
  end
end

describe TCPServer do
  it "fails when port is in use" do
    expect_raises Errno, /(already|Address) in use/ do
      TCPServer.open("::", 0) do |server|
        TCPServer.open("::", server.local_address.port) { }
      end
    end
  end
end

describe TCPSocket do
  it "sends and receives messages" do
    port = TCPServer.open("::", 0) do |server|
      server.local_address.port
    end
    assert port > 0

    TCPServer.open("::", port) do |server|
      assert server.local_address.family == Socket::Family::INET6
      assert server.local_address.port == port
      assert server.local_address.address == "::"

      # test protocol specific socket options
      assert server.reuse_address? == true # defaults to true
      assert (server.reuse_address = false) == false
      assert server.reuse_address? == false
      assert (server.reuse_address = true) == true
      assert server.reuse_address? == true

      assert (server.keepalive = false) == false
      assert server.keepalive? == false
      assert (server.keepalive = true) == true
      assert server.keepalive? == true

      assert (server.linger = nil).nil?
      assert server.linger.nil?
      assert (server.linger = 42) == 42
      assert server.linger == 42

      TCPSocket.open("::", server.local_address.port) do |client|
        # The commented lines are actually dependent on the system configuration,
        # so for now we keep it commented. Once we can force the family
        # we can uncomment them.

        # client.local_address.family.should eq(Socket::Family::INET)
        # client.local_address.address.should eq("127.0.0.1")

        sock = server.accept
        assert sock.sync? == server.sync?

        # sock.local_address.family.should eq(Socket::Family::INET6)
        # sock.local_address.port.should eq(12345)
        # sock.local_address.address.should eq("::ffff:127.0.0.1")

        # sock.remote_address.family.should eq(Socket::Family::INET6)
        # sock.remote_address.address.should eq("::ffff:127.0.0.1")

        # test protocol specific socket options
        assert (client.tcp_nodelay = true) == true
        assert client.tcp_nodelay? == true
        assert (client.tcp_nodelay = false) == false
        assert client.tcp_nodelay? == false

        assert (client.tcp_keepalive_idle = 42) == 42
        assert client.tcp_keepalive_idle == 42
        assert (client.tcp_keepalive_interval = 42) == 42
        assert client.tcp_keepalive_interval == 42
        assert (client.tcp_keepalive_count = 42) == 42
        assert client.tcp_keepalive_count == 42

        client << "ping"
        assert sock.gets(4) == "ping"
        sock << "pong"
        assert client.gets(4) == "pong"
      end

      # test sync flag propagation after accept
      server.sync = !server.sync?

      TCPSocket.open("localhost", server.local_address.port) do |client|
        sock = server.accept
        assert sock.sync? == server.sync?
      end
    end
  end

  it "fails when connection is refused" do
    port = TCPServer.open("localhost", 0) do |server|
      server.local_address.port
    end

    expect_raises(Errno, "Error connecting to 'localhost:#{port}': Connection refused") do
      TCPSocket.new("localhost", port)
    end
  end

  it "fails when host doesn't exist" do
    expect_raises(Socket::Error, /^getaddrinfo: (.+ not known|no address .+|Non-recoverable failure in name resolution|Name does not resolve)$/i) do
      TCPSocket.new("localhostttttt", 12345)
    end
  end
end

describe UDPSocket do
  it "sends and receives messages by reading and writing" do
    port = free_udp_socket_port

    server = UDPSocket.new(Socket::Family::INET6)
    server.bind("::", port)

    assert server.local_address.family == Socket::Family::INET6
    assert server.local_address.port == port
    assert server.local_address.address == "::"

    client = UDPSocket.new(Socket::Family::INET6)
    client.connect("::1", port)

    assert client.local_address.family == Socket::Family::INET6
    assert client.local_address.address == "::1"
    assert client.remote_address.family == Socket::Family::INET6
    assert client.remote_address.port == port
    assert client.remote_address.address == "::1"

    client << "message"
    assert server.gets(7) == "message"

    client.close
    server.close
  end

  it "sends and receives messages by send and receive over IPv4" do
    server = UDPSocket.new(Socket::Family::INET)
    server.bind("127.0.0.1", 0)

    client = UDPSocket.new(Socket::Family::INET)

    buffer = uninitialized UInt8[256]

    client.send("message equal to buffer", server.local_address)
    bytes_read, addr1 = server.receive(buffer.to_slice[0, 23])
    message1 = String.new(buffer.to_slice[0, bytes_read])
    assert message1 == "message equal to buffer"
    assert addr1.family == server.local_address.family
    assert addr1.address == server.local_address.address

    client.send("message less than buffer", server.local_address)
    bytes_read, addr2 = server.receive(buffer.to_slice)
    message2 = String.new(buffer.to_slice[0, bytes_read])
    assert message2 == "message less than buffer"
    assert addr2.family == server.local_address.family
    assert addr2.address == server.local_address.address

    server.close
    client.close
  end

  it "sends and receives messages by send and receive over IPv6" do
    server = UDPSocket.new(Socket::Family::INET6)
    server.bind("::1", 0)

    client = UDPSocket.new(Socket::Family::INET6)

    buffer = uninitialized UInt8[1500]

    client.send("message", server.local_address)
    bytes_read, addr = server.receive(buffer.to_slice)
    assert String.new(buffer.to_slice[0, bytes_read]) == "message"
    assert addr.family == server.local_address.family
    assert addr.address == server.local_address.address

    server.close
    client.close
  end

  it "broadcast messages" do
    port = free_udp_socket_port

    client = UDPSocket.new(Socket::Family::INET)
    client.broadcast = true
    assert client.broadcast? == true
    client.connect("255.255.255.255", port)
    assert client.send("broadcast") == 9
    client.close
  end
end

private def free_udp_socket_port
  server = UDPSocket.new(Socket::Family::INET6)
  server.bind("::", 0)
  port = server.local_address.port
  server.close
  assert port > 0
  port
end
