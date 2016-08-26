require "spec"
require "big_int"

# This is a non-optimized version of MemoryIO so we can test
# raw IO. Optimizations for specific IOs are tested separately
# (for example in buffered_io_spec)
class SimpleMemoryIO
  include IO

  getter buffer : UInt8*
  getter bytesize : Int32
  @capacity : Int32
  @pos : Int32
  @max_read : Int32?

  def initialize(capacity = 64, @max_read = nil)
    @buffer = GC.malloc_atomic(capacity.to_u32).as(UInt8*)
    @bytesize = 0
    @capacity = capacity
    @pos = 0
  end

  def self.new(string : String, max_read = nil)
    io = new(string.bytesize, max_read: max_read)
    io << string
    io
  end

  def self.new(bytes : Slice(UInt8), max_read = nil)
    io = new(bytes.size, max_read: max_read)
    io.write(bytes)
    io
  end

  def read(slice : Slice(UInt8))
    count = slice.size
    count = Math.min(count, @bytesize - @pos)
    if max_read = @max_read
      count = Math.min(count, max_read)
    end
    slice.copy_from(@buffer + @pos, count)
    @pos += count
    count
  end

  def write(slice : Slice(UInt8))
    count = slice.size
    new_bytesize = bytesize + count
    if new_bytesize > @capacity
      resize_to_capacity(Math.pw2ceil(new_bytesize))
    end

    slice.copy_to(@buffer + @bytesize, count)
    @bytesize += count

    nil
  end

  def to_slice
    Slice.new(@buffer, @bytesize)
  end

  private def check_needs_resize
    resize_to_capacity(@capacity * 2) if @bytesize == @capacity
  end

  private def resize_to_capacity(capacity)
    @capacity = capacity
    @buffer = @buffer.realloc(@capacity)
  end
end

describe IO do
  describe ".select" do
    it "returns the available readable ios" do
      IO.pipe do |read, write|
        write.puts "hey"
        write.close
        assert IO.select({read}).includes?(read) == true
      end
    end

    it "returns the available writable ios" do
      IO.pipe do |read, write|
        assert IO.select(nil, {write}).includes?(write) == true
      end
    end

    it "times out" do
      IO.pipe do |read, write|
        assert IO.select({read}, nil, nil, 0.00001).nil?
      end
    end
  end

  describe "partial read" do
    it "doesn't block on first read.  blocks on 2nd read" do
      IO.pipe do |read, write|
        write.puts "hello"
        slice = Slice(UInt8).new 1024

        read.read_timeout = 1
        assert read.read(slice) == 6

        expect_raises(IO::Timeout) do
          read.read_timeout = 0.0000001
          read.read(slice)
        end
      end
    end
  end

  describe "IO iterators" do
    it "iterates by line" do
      io = MemoryIO.new("hello\nbye\n")
      lines = io.each_line
      assert lines.next == "hello\n"
      assert lines.next == "bye\n"
      assert lines.next.is_a?(Iterator::Stop)

      lines.rewind
      assert lines.next == "hello\n"
    end

    it "iterates by char" do
      io = MemoryIO.new("abあぼ")
      chars = io.each_char
      assert chars.next == 'a'
      assert chars.next == 'b'
      assert chars.next == 'あ'
      assert chars.next == 'ぼ'
      assert chars.next.is_a?(Iterator::Stop)

      chars.rewind
      assert chars.next == 'a'
    end

    it "iterates by byte" do
      io = MemoryIO.new("ab")
      bytes = io.each_byte
      assert bytes.next == 'a'.ord
      assert bytes.next == 'b'.ord
      assert bytes.next.is_a?(Iterator::Stop)

      bytes.rewind
      assert bytes.next == 'a'.ord
    end
  end

  it "copies" do
    string = "abあぼ"
    src = MemoryIO.new(string)
    dst = MemoryIO.new
    assert IO.copy(src, dst) == string.bytesize
    assert dst.to_s == string
  end

  it "copies with limit" do
    string = "abcあぼ"
    src = MemoryIO.new(string)
    dst = MemoryIO.new
    assert IO.copy(src, dst, 3) == 3
    assert dst.to_s == "abc"
  end

  it "raises on copy with negative limit" do
    string = "abcあぼ"
    src = MemoryIO.new(string)
    dst = MemoryIO.new
    expect_raises(ArgumentError, "negative limit") do
      IO.copy(src, dst, -10)
    end
  end

  it "reopens" do
    File.open("#{__DIR__}/../data/test_file.txt") do |file1|
      File.open("#{__DIR__}/../data/test_file.ini") do |file2|
        file2.reopen(file1)
        assert file2.gets == "Hello World\n"
      end
    end
  end

  describe "read operations" do
    it "does gets" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.gets == "hello\n"
      assert io.gets == "world\n"
      assert io.gets.nil?
    end

    it "does gets with big line" do
      big_line = "a" * 20_000
      io = SimpleMemoryIO.new("#{big_line}\nworld\n")
      assert io.gets == "#{big_line}\n"
    end

    it "does gets with char delimiter" do
      io = SimpleMemoryIO.new("hello world")
      assert io.gets('w') == "hello w"
      assert io.gets('r') == "or"
      assert io.gets('r') == "ld"
      assert io.gets('r').nil?
    end

    it "does gets with unicode char delimiter" do
      io = SimpleMemoryIO.new("こんにちは")
      assert io.gets('ち') == "こんにち"
      assert io.gets('ち') == "は"
      assert io.gets('ち').nil?
    end

    it "gets with string as delimiter" do
      io = SimpleMemoryIO.new("hello world")
      assert io.gets("lo") == "hello"
      assert io.gets("rl") == " worl"
      assert io.gets("foo") == "d"
    end

    it "gets with empty string as delimiter" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.gets("") == "hello\nworld\n"
    end

    it "gets with single byte string as delimiter" do
      io = SimpleMemoryIO.new("hello\nworld\nbye")
      assert io.gets("\n") == "hello\n"
      assert io.gets("\n") == "world\n"
      assert io.gets("\n") == "bye"
    end

    it "does gets with limit" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.gets(3) == "hel"
      assert io.gets(10_000) == "lo\n"
      assert io.gets(10_000) == "world\n"
      assert io.gets(3).nil?
    end

    it "does gets with char and limit" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.gets('o', 2) == "he"
      assert io.gets('w', 10_000) == "llo\nw"
      assert io.gets('z', 10_000) == "orld\n"
      assert io.gets('a', 3).nil?
    end

    it "raises if invoking gets with negative limit" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      expect_raises ArgumentError, "negative limit" do
        io.gets(-1)
      end
    end

    it "does read_line with limit" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.read_line(3) == "hel"
      assert io.read_line(10_000) == "lo\n"
      assert io.read_line(10_000) == "world\n"
      expect_raises(IO::EOFError) { io.read_line(3) }
    end

    it "does read_line with char and limit" do
      io = SimpleMemoryIO.new("hello\nworld\n")
      assert io.read_line('o', 2) == "he"
      assert io.read_line('w', 10_000) == "llo\nw"
      assert io.read_line('z', 10_000) == "orld\n"
      expect_raises(IO::EOFError) { io.read_line('a', 3) }
    end

    it "reads all remaining content" do
      io = SimpleMemoryIO.new("foo\nbar\nbaz\n")
      assert io.gets == "foo\n"
      assert io.gets_to_end == "bar\nbaz\n"
    end

    it "reads char" do
      io = SimpleMemoryIO.new("hi 世界")
      assert io.read_char == 'h'
      assert io.read_char == 'i'
      assert io.read_char == ' '
      assert io.read_char == '世'
      assert io.read_char == '界'
      assert io.read_char.nil?

      io.write Bytes[0xf8, 0xff, 0xff, 0xff]
      expect_raises(InvalidByteSequenceError) do
        io.read_char
      end

      io.write_byte 0x81_u8
      expect_raises(InvalidByteSequenceError) do
        io.read_char
      end
    end

    it "reads byte" do
      io = SimpleMemoryIO.new("hello")
      assert io.read_byte == 'h'.ord
      assert io.read_byte == 'e'.ord
      assert io.read_byte == 'l'.ord
      assert io.read_byte == 'l'.ord
      assert io.read_byte == 'o'.ord
      assert io.read_char.nil?
    end

    it "does each_line" do
      io = SimpleMemoryIO.new("a\nbb\ncc")
      counter = 0
      io.each_line do |line|
        case counter
        when 0
          assert line == "a\n"
        when 1
          assert line == "bb\n"
        when 2
          assert line == "cc"
        end
        counter += 1
      end
      assert counter == 3
    end

    it "raises on EOF with read_line" do
      str = SimpleMemoryIO.new("hello")
      assert str.read_line == "hello"

      expect_raises IO::EOFError, "end of file reached" do
        str.read_line
      end
    end

    it "raises on EOF with readline and delimiter" do
      str = SimpleMemoryIO.new("hello")
      assert str.read_line('e') == "he"
      assert str.read_line('e') == "llo"

      expect_raises IO::EOFError, "end of file reached" do
        str.read_line
      end
    end

    it "does read_fully" do
      str = SimpleMemoryIO.new("hello")
      slice = Slice(UInt8).new(4)
      str.read_fully(slice)
      assert String.new(slice) == "hell"

      expect_raises(IO::EOFError) do
        str.read_fully(slice)
      end
    end
  end

  describe "write operations" do
    it "does puts" do
      io = SimpleMemoryIO.new
      io.puts "Hello"
      assert io.gets_to_end == "Hello\n"
    end

    it "does puts with big string" do
      io = SimpleMemoryIO.new
      s = "*" * 20_000
      io << "hello"
      io << s
      assert io.gets_to_end == "hello#{s}"
    end

    it "does puts many times" do
      io = SimpleMemoryIO.new
      10_000.times { io << "hello" }
      assert io.gets_to_end == "hello" * 10_000
    end

    it "puts several arguments" do
      io = SimpleMemoryIO.new
      io.puts(1, "aaa", "\n")
      assert io.gets_to_end == "1\naaa\n\n"
    end

    it "prints" do
      io = SimpleMemoryIO.new
      io.print "foo"
      assert io.gets_to_end == "foo"
    end

    it "prints several arguments" do
      io = SimpleMemoryIO.new
      io.print "foo", "bar", "baz"
      assert io.gets_to_end == "foobarbaz"
    end

    it "writes bytes" do
      io = SimpleMemoryIO.new
      10_000.times { io.write_byte 'a'.ord.to_u8 }
      assert io.gets_to_end == "a" * 10_000
    end

    it "writes with printf" do
      io = SimpleMemoryIO.new
      io.printf "Hello %d", 123
      assert io.gets_to_end == "Hello 123"
    end

    it "writes with printf as an array" do
      io = SimpleMemoryIO.new
      io.printf "Hello %d", [123]
      assert io.gets_to_end == "Hello 123"
    end

    it "skips a few bytes" do
      io = SimpleMemoryIO.new
      io << "hello world"
      io.skip(6)
      assert io.gets_to_end == "world"
    end
  end

  describe "encoding" do
    describe "decode" do
      it "gets_to_end" do
        str = "Hello world" * 200
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets_to_end == str
      end

      it "gets" do
        str = "Hello world\nFoo\nBar"
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets == "Hello world\n"
        assert io.gets == "Foo\n"
        assert io.gets == "Bar"
        assert io.gets.nil?
      end

      it "gets big string" do
        str = "Hello\nWorld\n" * 10_000
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        10_000.times do |i|
          assert io.gets == "Hello\n"
          assert io.gets == "World\n"
        end
      end

      it "gets big GB2312 string" do
        2.times do
          str = ("你好我是人\n" * 1000).encode("GB2312")
          io = SimpleMemoryIO.new(str)
          io.set_encoding("GB2312")
          1000.times do
            assert io.gets == "你好我是人\n"
          end
        end
      end

      it "gets with limit" do
        str = "Hello\nWorld\n"
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets(3) == "Hel"
      end

      it "gets with limit (small, no newline)" do
        str = "Hello world" * 10_000
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets(3) == "Hel"
      end

      it "gets with limit (big)" do
        str = "Hello world" * 10_000
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets(20_000) == str[0, 20_000]
      end

      it "gets with string delimiter" do
        str = "Hello world\nFoo\nBar"
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        assert io.gets("wo") == "Hello wo"
        assert io.gets("oo") == "rld\nFoo"
        assert io.gets("xx") == "\nBar"
        assert io.gets("zz").nil?
      end

      it "reads char" do
        str = "Hello world"
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        str.each_char do |char|
          assert io.read_char == char
        end
        assert io.read_char.nil?
      end

      it "reads utf8 byte" do
        str = "Hello world"
        io = SimpleMemoryIO.new(str.encode("UCS-2LE"))
        io.set_encoding("UCS-2LE")
        str.each_byte do |byte|
          assert io.read_utf8_byte == byte
        end
        assert io.read_utf8_byte.nil?
      end

      it "reads utf8" do
        io = MemoryIO.new("你".encode("GB2312"))
        io.set_encoding("GB2312")

        buffer = uninitialized UInt8[1024]
        bytes_read = io.read_utf8(buffer.to_slice) # => 3
        assert bytes_read == 3
        assert buffer.to_slice[0, bytes_read].to_a == "你".bytes
      end

      it "raises on incomplete byte sequence" do
        io = SimpleMemoryIO.new("好".byte_slice(0, 1))
        io.set_encoding("GB2312")
        expect_raises ArgumentError, "incomplete multibyte sequence" do
          io.read_char
        end
      end

      it "says invalid byte sequence" do
        io = SimpleMemoryIO.new(Slice.new(1, 140_u8))
        io.set_encoding("GB2312")
        expect_raises ArgumentError, "invalid multibyte sequence" do
          io.read_char
        end
      end

      it "skips invalid byte sequences" do
        string = String.build do |str|
          str.write "好".encode("GB2312")
          str.write_byte 140_u8
          str.write "是".encode("GB2312")
        end
        io = SimpleMemoryIO.new(string)
        io.set_encoding("GB2312", invalid: :skip)
        assert io.read_char == '好'
        assert io.read_char == '是'
        assert io.read_char.nil?
      end

      it "says invalid 'invalid' option" do
        io = SimpleMemoryIO.new
        expect_raises ArgumentError, "valid values for `invalid` option are `nil` and `:skip`, not :foo" do
          io.set_encoding("GB2312", invalid: :foo)
        end
      end

      it "says invalid encoding" do
        io = SimpleMemoryIO.new("foo")
        io.set_encoding("FOO")
        expect_raises ArgumentError, "invalid encoding: FOO" do
          io.gets_to_end
        end
      end
    end

    describe "encode" do
      it "prints a string" do
        str = "Hello world"
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print str
        slice = io.to_slice
        assert slice == str.encode("UCS-2LE")
      end

      it "prints numbers" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print 0
        io.print 1_u8
        io.print 2_u16
        io.print 3_u32
        io.print 4_u64
        io.print 5_i8
        io.print 6_i16
        io.print 7_i32
        io.print 8_i64
        io.print 9.1_f32
        io.print 10.11_f64
        slice = io.to_slice
        assert slice == "0123456789.110.11".encode("UCS-2LE")
      end

      it "prints bool" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print true
        io.print false
        slice = io.to_slice
        assert slice == "truefalse".encode("UCS-2LE")
      end

      it "prints char" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print 'a'
        slice = io.to_slice
        assert slice == "a".encode("UCS-2LE")
      end

      it "prints symbol" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print :foo
        slice = io.to_slice
        assert slice == "foo".encode("UCS-2LE")
      end

      it "prints big int" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.print 123_456.to_big_i
        slice = io.to_slice
        assert slice == "123456".encode("UCS-2LE")
      end

      it "puts" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.puts 1
        io.puts
        slice = io.to_slice
        assert slice == "1\n\n".encode("UCS-2LE")
      end

      it "printf" do
        io = SimpleMemoryIO.new
        io.set_encoding("UCS-2LE")
        io.printf "%s-%d-%.2f", "hi", 123, 45.67
        slice = io.to_slice
        assert slice == "hi-123-45.67".encode("UCS-2LE")
      end

      it "raises on invalid byte sequence" do
        io = SimpleMemoryIO.new
        io.set_encoding("GB2312")
        expect_raises ArgumentError, "invalid multibyte sequence" do
          io.print "ñ"
        end
      end

      it "skips on invalid byte sequence" do
        io = SimpleMemoryIO.new
        io.set_encoding("GB2312", invalid: :skip)
        io.print "ñ"
        io.print "foo"
      end

      it "raises on incomplete byte sequence" do
        io = SimpleMemoryIO.new
        io.set_encoding("GB2312")
        expect_raises ArgumentError, "incomplete multibyte sequence" do
          io.print "好".byte_slice(0, 1)
        end
      end

      it "says invalid encoding" do
        io = SimpleMemoryIO.new
        io.set_encoding("FOO")
        expect_raises ArgumentError, "invalid encoding: FOO" do
          io.puts "a"
        end
      end
    end

    describe "#encoding" do
      it "returns \"UTF-8\" if the encoding is not manually set" do
        assert SimpleMemoryIO.new.encoding == "UTF-8"
      end

      it "returns the name of the encoding set via #set_encoding" do
        io = SimpleMemoryIO.new
        io.set_encoding("UTF-16LE")
        assert io.encoding == "UTF-16LE"
      end
    end
  end
end
