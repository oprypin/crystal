require "spec"

describe "MemoryIO" do
  it "writes" do
    io = MemoryIO.new
    assert io.bytesize == 0
    io.write Slice.new("hello".to_unsafe, 3)
    assert io.bytesize == 3
    io.rewind
    assert io.gets_to_end == "hel"
  end

  it "writes big" do
    s = "hi" * 100
    io = MemoryIO.new
    io.write Slice.new(s.to_unsafe, s.bytesize)
    io.rewind
    assert io.gets_to_end == s
  end

  it "reads byte" do
    io = MemoryIO.new("abc")
    assert io.read_byte == 'a'.ord
    assert io.read_byte == 'b'.ord
    assert io.read_byte == 'c'.ord
    assert io.read_byte.nil?
  end

  it "raises if reading when closed" do
    io = MemoryIO.new("abc")
    io.close
    buffer = uninitialized UInt8[3]
    expect_raises(IO::Error, "closed stream") do
      io.read(buffer.to_slice)
    end
  end

  it "raises if clearing when closed" do
    io = MemoryIO.new("abc")
    io.close
    expect_raises(IO::Error, "closed stream") do
      io.clear
    end
  end

  it "appends to another buffer" do
    s1 = MemoryIO.new
    s1 << "hello"

    s2 = MemoryIO.new
    s1.to_s(s2)
    assert s2.to_s == "hello"
  end

  it "reads single line content" do
    io = MemoryIO.new("foo")
    assert io.gets == "foo"
  end

  it "reads each line" do
    io = MemoryIO.new("foo\r\nbar\r\n")
    assert io.gets == "foo\r\n"
    assert io.gets == "bar\r\n"
    assert io.gets == nil
  end

  it "gets with char as delimiter" do
    io = MemoryIO.new("hello world")
    assert io.gets('w') == "hello w"
    assert io.gets('r') == "or"
    assert io.gets('r') == "ld"
    assert io.gets('r') == nil
  end

  it "does gets with char and limit" do
    io = MemoryIO.new("hello\nworld\n")
    assert io.gets('o', 2) == "he"
    assert io.gets('w', 10_000) == "llo\nw"
    assert io.gets('z', 10_000) == "orld\n"
    assert io.gets('a', 3).nil?
  end

  it "does gets with limit" do
    io = MemoryIO.new("hello\nworld")
    assert io.gets(3) == "hel"
    assert io.gets(3) == "lo\n"
    assert io.gets(3) == "wor"
    assert io.gets(3) == "ld"
    assert io.gets(3).nil?
  end

  it "raises if invoking gets with negative limit" do
    io = MemoryIO.new("hello\nworld\n")
    expect_raises ArgumentError, "negative limit" do
      io.gets(-1)
    end
  end

  it "write single byte" do
    io = MemoryIO.new
    io.write_byte 97_u8
    assert io.to_s == "a"
  end

  it "writes and reads" do
    io = MemoryIO.new
    io << "foo" << "bar"
    io.rewind
    assert io.gets == "foobar"
  end

  it "can be converted to slice" do
    str = MemoryIO.new
    str.write_byte 0_u8
    str.write_byte 1_u8
    slice = str.to_slice
    assert slice.size == 2
    assert slice[0] == 0_u8
    assert slice[1] == 1_u8
  end

  it "reads more than available (#1229)" do
    s = "h" * (10 * 1024)
    str = MemoryIO.new(s)
    assert str.gets(11 * 1024) == s
  end

  it "writes after reading" do
    io = MemoryIO.new
    io << "abcdefghi"
    io.rewind
    io.gets(3)
    io.print("xyz")
    io.rewind
    assert io.gets_to_end == "abcxyzghi"
  end

  it "has a size" do
    assert MemoryIO.new("foo").size == 3
  end

  it "can tell" do
    io = MemoryIO.new("foo")
    assert io.tell == 0
    io.gets(2)
    assert io.tell == 2
  end

  it "can seek set" do
    io = MemoryIO.new("abcdef")
    io.seek(3)
    assert io.tell == 3
    assert io.gets(1) == "d"
  end

  it "raises if seek set is negative" do
    io = MemoryIO.new("abcdef")
    expect_raises(ArgumentError, "negative pos") do
      io.seek(-1)
    end
  end

  it "can seek past the end" do
    io = MemoryIO.new
    io << "abc"
    io.rewind
    io.seek(6)
    assert io.gets_to_end == ""
    io.print("xyz")
    io.rewind
    assert io.gets_to_end == "abc\u{0}\u{0}\u{0}xyz"
  end

  it "can seek current" do
    io = MemoryIO.new("abcdef")
    io.seek(2)
    io.seek(1, IO::Seek::Current)
    assert io.gets(1) == "d"
  end

  it "raises if seek current leads to negative value" do
    io = MemoryIO.new("abcdef")
    io.seek(2)
    expect_raises(ArgumentError, "negative pos") do
      io.seek(-3, IO::Seek::Current)
    end
  end

  it "can seek from the end" do
    io = MemoryIO.new("abcdef")
    io.seek(-2, IO::Seek::End)
    assert io.gets(1) == "e"
  end

  it "can be closed" do
    io = MemoryIO.new
    io << "abc"
    io.close
    assert io.closed? == true

    expect_raises(IO::Error, "closed stream") { io.gets_to_end }
    expect_raises(IO::Error, "closed stream") { io.print "hi" }
    expect_raises(IO::Error, "closed stream") { io.seek(1) }
    expect_raises(IO::Error, "closed stream") { io.gets }
    expect_raises(IO::Error, "closed stream") { io.read_byte }
  end

  it "seeks with pos and pos=" do
    io = MemoryIO.new("abcdef")
    io.pos = 4
    assert io.gets(1) == "e"
    io.pos -= 2
    assert io.gets(1) == "d"
  end

  it "clears" do
    io = MemoryIO.new
    io << "abc"
    io.rewind
    io.gets(1)
    io.clear
    assert io.pos == 0
    assert io.gets_to_end == ""
  end

  it "raises if negative capacity" do
    expect_raises(ArgumentError, "negative capacity") do
      MemoryIO.new(-1)
    end
  end

  it "raises if capacity too big" do
    expect_raises(ArgumentError, "capacity too big") do
      MemoryIO.new(UInt32::MAX)
    end
  end

  it "creates from string" do
    io = MemoryIO.new "abcdef"
    assert io.gets(2) == "ab"
    assert io.gets(3) == "cde"

    expect_raises(IO::Error, "read-only stream") do
      io.print 1
    end
  end

  it "creates from slice" do
    slice = Slice.new(6) { |i| ('a'.ord + i).to_u8 }
    io = MemoryIO.new slice
    assert io.gets(2) == "ab"
    assert io.gets(3) == "cde"
    io.print 'x'

    assert String.new(slice) == "abcdex"

    expect_raises(IO::Error, "non-resizeable stream") do
      io.print 'z'
    end
  end

  it "creates from slice, non-writeable" do
    slice = Slice.new(6) { |i| ('a'.ord + i).to_u8 }
    io = MemoryIO.new slice, writeable: false

    expect_raises(IO::Error, "read-only stream") do
      io.print 'z'
    end
  end

  it "writes past end" do
    io = MemoryIO.new
    io.pos = 1000
    io.print 'a'
    assert io.to_slice.to_a == [0] * 1000 + [97]
  end

  it "writes past end with write_byte" do
    io = MemoryIO.new
    io.pos = 1000
    io.write_byte 'a'.ord.to_u8
    assert io.to_slice.to_a == [0] * 1000 + [97]
  end

  describe "encoding" do
    describe "decode" do
      it "gets_to_end" do
        str = "Hello world" * 200
        io = MemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets_to_end == str
      end

      it "gets" do
        str = "Hello world\nFoo\nBar\n" + ("1234567890" * 1000)
        io = MemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets == "Hello world\n"
        assert io.gets == "Foo\n"
        assert io.gets == "Bar\n"
      end

      it "reads char" do
        str = "x\nHello world" + ("1234567890" * 1000)
        io = MemoryIO.new(str.encode("UCS-2LE"))
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
