require "spec"

class IO::BufferedWrapper
  include IO::Buffered

  getter called_unbuffered_read

  @io : IO
  @called_unbuffered_read : Bool

  def initialize(@io)
    @called_unbuffered_read = false
  end

  def self.new(io)
    buffered_io = new(io)
    yield buffered_io
    buffered_io.flush
    io
  end

  private def unbuffered_read(slice : Slice(UInt8))
    @called_unbuffered_read = true
    @io.read(slice)
  end

  private def unbuffered_write(slice : Slice(UInt8))
    @io.write(slice)
  end

  private def unbuffered_flush
    @io.flush
  end

  def fd
    @io.fd
  end

  private def unbuffered_close
    @io.close
  end

  def closed?
    @io.closed?
  end

  private def unbuffered_rewind
    @io.rewind
  end
end

describe "IO::Buffered" do
  it "does gets" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello\nworld\n"))
    assert io.gets == "hello\n"
    assert io.gets == "world\n"
    assert io.gets.nil?
  end

  it "does gets with big line" do
    big_line = "a" * 20_000
    io = IO::BufferedWrapper.new(MemoryIO.new("#{big_line}\nworld\n"))
    assert io.gets == "#{big_line}\n"
  end

  it "does gets with char delimiter" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello world"))
    assert io.gets('w') == "hello w"
    assert io.gets('r') == "or"
    assert io.gets('r') == "ld"
    assert io.gets('r').nil?
  end

  it "does gets with unicode char delimiter" do
    io = IO::BufferedWrapper.new(MemoryIO.new("こんにちは"))
    assert io.gets('ち') == "こんにち"
    assert io.gets('ち') == "は"
    assert io.gets('ち').nil?
  end

  it "does gets with limit" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello\nworld\n"))
    assert io.gets(3) == "hel"
    assert io.gets(10_000) == "lo\n"
    assert io.gets(10_000) == "world\n"
    assert io.gets(3).nil?
  end

  it "does gets with char and limit" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello\nworld\n"))
    assert io.gets('o', 2) == "he"
    assert io.gets('w', 10_000) == "llo\nw"
    assert io.gets('z', 10_000) == "orld\n"
    assert io.gets('a', 3).nil?
  end

  it "does gets with char and limit when not found in buffer" do
    io = IO::BufferedWrapper.new(MemoryIO.new(("a" * (IO::Buffered::BUFFER_SIZE + 10)) + "b"))
    assert io.gets('b', 2) == "aa"
  end

  it "does gets with char and limit when not found in buffer (2)" do
    base = "a" * (IO::Buffered::BUFFER_SIZE + 10)
    io = IO::BufferedWrapper.new(MemoryIO.new(base + "aabaaa"))
    assert io.gets('b', IO::Buffered::BUFFER_SIZE + 11) == base + "a"
  end

  it "raises if invoking gets with negative limit" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello\nworld\n"))
    expect_raises ArgumentError, "negative limit" do
      io.gets(-1)
    end
  end

  it "writes bytes" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    10_000.times { io.write_byte 'a'.ord.to_u8 }
    io.flush
    assert str.to_s == "a" * 10_000
  end

  it "reads char" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hi 世界"))
    assert io.read_char == 'h'
    assert io.read_char == 'i'
    assert io.read_char == ' '
    assert io.read_char == '世'
    assert io.read_char == '界'
    assert io.read_char.nil?

    io = MemoryIO.new
    io.write Bytes[0xf8, 0xff, 0xff, 0xff]
    io.rewind
    io = IO::BufferedWrapper.new(io)

    expect_raises(InvalidByteSequenceError) do
      io.read_char
    end

    io = MemoryIO.new
    io.write_byte 0x81_u8
    io.rewind
    io = IO::BufferedWrapper.new(io)
    expect_raises(InvalidByteSequenceError) do
      p io.read_char
    end
  end

  it "reads byte" do
    io = IO::BufferedWrapper.new(MemoryIO.new("hello"))
    assert io.read_byte == 'h'.ord
    assert io.read_byte == 'e'.ord
    assert io.read_byte == 'l'.ord
    assert io.read_byte == 'l'.ord
    assert io.read_byte == 'o'.ord
    assert io.read_char.nil?
  end

  it "does new with block" do
    str = MemoryIO.new
    res = IO::BufferedWrapper.new str, &.print "Hello"
    assert res.same?(str)
    assert str.to_s == "Hello"
  end

  it "rewinds" do
    str = MemoryIO.new("hello\nworld\n")
    io = IO::BufferedWrapper.new str
    assert io.gets == "hello\n"
    io.rewind
    assert io.gets == "hello\n"
  end

  it "reads more than the buffer's internal capacity" do
    s = String.build do |str|
      900.times do
        10.times do |i|
          str << ('a'.ord + i).chr
        end
      end
    end
    io = IO::BufferedWrapper.new(MemoryIO.new(s))

    slice = Slice(UInt8).new(9000)
    count = io.read(slice)
    assert count == 9000

    900.times do
      10.times do |i|
        assert slice[i] == 'a'.ord + i
      end
    end
  end

  it "writes more than the buffer's internal capacity" do
    s = String.build do |str|
      900.times do
        10.times do |i|
          str << ('a'.ord + i).chr
        end
      end
    end
    strio = MemoryIO.new
    strio << s
    strio.rewind
    io = IO::BufferedWrapper.new(strio)
    io.write(s.to_slice)
    assert strio.rewind.gets_to_end == s
  end

  it "does puts" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    io.puts "Hello"
    assert str.to_s == ""
    io.flush
    assert str.to_s == "Hello\n"
  end

  it "does puts with big string" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    s = "*" * 20_000
    io << "hello"
    io << s
    io.flush
    assert str.to_s == "hello#{s}"
  end

  it "does puts many times" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    10_000.times { io << "hello" }
    io.flush
    assert str.to_s == "hello" * 10_000
  end

  it "flushes on \n" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    io.flush_on_newline = true

    io << "hello\nworld"
    assert str.to_s == "hello\n"
    io.flush
    assert str.to_s == "hello\nworld"
  end

  it "doesn't write past count" do
    str = MemoryIO.new
    io = IO::BufferedWrapper.new(str)
    io.flush_on_newline = true

    slice = Slice.new(10) { |i| i == 9 ? '\n'.ord.to_u8 : ('a'.ord + i).to_u8 }
    io.write slice[0, 4]
    io.flush
    assert str.to_s == "abcd"
  end

  it "syncs" do
    str = MemoryIO.new

    io = IO::BufferedWrapper.new(str)
    assert io.sync? == false

    io.sync = true
    assert io.sync? == true

    io.write_byte 1_u8

    str.rewind
    assert str.read_byte == 1_u8
  end

  it "shouldn't call unbuffered read if reading to an empty slice" do
    str = MemoryIO.new("foo")
    io = IO::BufferedWrapper.new(str)
    io.read(Slice(UInt8).new(0))
    assert io.called_unbuffered_read == false
  end

  describe "encoding" do
    describe "decode" do
      it "gets_to_end" do
        str = "Hello world" * 200
        base_io = MemoryIO.new(str.encode("UCS-2LE"))
        io = IO::BufferedWrapper.new(base_io)
        io.set_encoding("UCS-2LE")
        assert io.gets_to_end == str
      end

      it "gets" do
        str = "Hello world\nFoo\nBar\n" + ("1234567890" * 1000)
        base_io = MemoryIO.new(str.encode("UCS-2LE"))
        io = IO::BufferedWrapper.new(base_io)
        io.set_encoding("UCS-2LE")
        assert io.gets == "Hello world\n"
        assert io.gets == "Foo\n"
        assert io.gets == "Bar\n"
      end

      it "gets big string" do
        str = "Hello\nWorld\n" * 10_000
        base_io = MemoryIO.new(str.encode("UCS-2LE"))
        io = IO::BufferedWrapper.new(base_io)
        io.set_encoding("UCS-2LE")
        10_000.times do |i|
          assert io.gets == "Hello\n"
          assert io.gets == "World\n"
        end
      end

      it "gets big GB2312 string" do
        str = ("你好我是人\n" * 1000).encode("GB2312")
        base_io = MemoryIO.new(str)
        io = IO::BufferedWrapper.new(base_io)
        io.set_encoding("GB2312")
        1000.times do
          assert io.gets == "你好我是人\n"
        end
      end

      it "reads char" do
        str = "x\nHello world" + ("1234567890" * 1000)
        base_io = MemoryIO.new(str.encode("UCS-2LE"))
        io = IO::BufferedWrapper.new(base_io)
        io.set_encoding("UCS-2LE")
        assert io.gets == "x\n"
        str = str[2..-1]
        str.each_char do |char|
          assert io.read_char == char
        end
        assert io.read_char.nil?
      end
    end
  end
end
