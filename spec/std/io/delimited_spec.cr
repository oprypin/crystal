require "spec"

class PartialReaderIO
  include IO

  @slice : Slice(UInt8)

  def initialize(data : String)
    @slice = data.to_slice
  end

  def read(slice : Bytes)
    return 0 if @slice.size == 0
    max_read_size = {slice.size, @slice.size}.min
    read_size = rand(1..max_read_size)
    slice.copy_from(@slice[0, read_size])
    @slice += read_size
    read_size
  end

  def write(slice : Bytes)
    raise "write"
  end
end

describe "IO::Delimited" do
  describe ".read" do
    it "doesn't read past the limit" do
      io = MemoryIO.new("abcderzzrfgzr")
      delimited = IO::Delimited.new(io, read_delimiter: "zr")

      assert delimited.gets_to_end == "abcderz"
      assert io.gets_to_end == "fgzr"
    end

    it "doesn't read past the limit (char-by-char)" do
      io = MemoryIO.new("abcderzzrfg")
      delimited = IO::Delimited.new(io, read_delimiter: "zr")

      assert delimited.read_char == 'a'
      assert delimited.read_char == 'b'
      assert delimited.read_char == 'c'
      assert delimited.read_char == 'd'
      assert delimited.read_char == 'e'
      assert delimited.read_char == 'r'
      assert delimited.read_char == 'z'
      assert delimited.read_char == nil
      assert delimited.read_char == nil
      assert delimited.read_char == nil
      assert delimited.read_char == nil

      assert io.read_char == 'f'
      assert io.read_char == 'g'
    end

    it "doesn't clobber active_delimiter_buffer" do
      io = MemoryIO.new("ab12312")
      delimited = IO::Delimited.new(io, read_delimiter: "12345")

      assert delimited.gets_to_end == "ab12312"
    end

    it "handles the delimiter at the start" do
      io = MemoryIO.new("ab12312")
      delimited = IO::Delimited.new(io, read_delimiter: "ab1")

      assert delimited.read_char == nil
    end

    it "handles the delimiter at the end" do
      io = MemoryIO.new("ab12312z")
      delimited = IO::Delimited.new(io, read_delimiter: "z")

      assert delimited.gets_to_end == "ab12312"
    end

    it "handles nearly a delimiter at the end" do
      io = MemoryIO.new("ab12312")
      delimited = IO::Delimited.new(io, read_delimiter: "122")

      assert delimited.gets_to_end == "ab12312"
    end

    it "doesn't clobber the buffer on closely-offset partial matches" do
      io = MemoryIO.new("abab1234abcdefgh")
      delimited = IO::Delimited.new(io, read_delimiter: "abcdefgh")

      assert delimited.gets_to_end == "abab1234"
    end

    it "handles partial reads" do
      io = PartialReaderIO.new("abab1234abcdefgh")
      delimited = IO::Delimited.new(io, read_delimiter: "abcdefgh")

      assert delimited.gets_to_end == "abab1234"
    end
  end

  describe ".write" do
    it "raises" do
      delimited = IO::Delimited.new(MemoryIO.new, read_delimiter: "zr")
      expect_raises(IO::Error, "Can't write to IO::Delimited") do
        delimited.puts "test string"
      end
    end
  end

  describe ".close" do
    it "stops reading" do
      io = MemoryIO.new "abcdefg"
      delimited = IO::Delimited.new(io, read_delimiter: "zr")

      assert delimited.read_char == 'a'
      assert delimited.read_char == 'b'

      delimited.close
      assert delimited.closed? == true
      expect_raises(IO::Error, "closed stream") do
        delimited.read_char
      end
    end

    it "closes the underlying stream if sync_close is true" do
      io = MemoryIO.new "abcdefg"
      delimited = IO::Delimited.new(io, read_delimiter: "zr", sync_close: true)
      assert delimited.sync_close? == true

      assert io.closed? == false
      delimited.close
      assert io.closed? == true
    end
  end
end
