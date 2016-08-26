require "spec"

describe "IO::Sized" do
  describe ".read" do
    it "doesn't read past the limit when reading char-by-char" do
      io = MemoryIO.new "abcdefg"
      sized = IO::Sized.new(io, read_size: 5)

      assert sized.read_char == 'a'
      assert sized.read_char == 'b'
      assert sized.read_char == 'c'
      assert sized.read_remaining == 2
      assert sized.read_char == 'd'
      assert sized.read_char == 'e'
      assert sized.read_remaining == 0
      assert sized.read_char.nil?
      assert sized.read_remaining == 0
      assert sized.read_char.nil?
    end

    it "doesn't read past the limit when reading the correct size" do
      io = MemoryIO.new("1234567")
      sized = IO::Sized.new(io, read_size: 5)
      slice = Bytes.new(5)

      assert sized.read(slice) == 5
      assert String.new(slice) == "12345"

      assert sized.read(slice) == 0
      assert String.new(slice) == "12345"
    end

    it "reads partially when supplied with a larger slice" do
      io = MemoryIO.new("1234567")
      sized = IO::Sized.new(io, read_size: 5)
      slice = Bytes.new(10)

      assert sized.read(slice) == 5
      assert String.new(slice) == "12345\0\0\0\0\0"
    end

    it "raises on negative numbers" do
      io = MemoryIO.new
      expect_raises(ArgumentError, "negative read_size") do
        IO::Sized.new(io, read_size: -1)
      end
    end
  end

  describe ".write" do
    it "raises" do
      sized = IO::Sized.new(MemoryIO.new, read_size: 5)
      expect_raises(IO::Error, "Can't write to IO::Sized") do
        sized.puts "test string"
      end
    end
  end

  describe ".close" do
    it "stops reading" do
      io = MemoryIO.new "abcdefg"
      sized = IO::Sized.new(io, read_size: 5)

      assert sized.read_char == 'a'
      assert sized.read_char == 'b'

      sized.close
      assert sized.closed? == true
      expect_raises(IO::Error, "closed stream") do
        sized.read_char
      end
    end

    it "closes the underlying stream if sync_close is true" do
      io = MemoryIO.new "abcdefg"
      sized = IO::Sized.new(io, read_size: 5, sync_close: true)
      assert sized.sync_close? == true

      assert io.closed? == false
      sized.close
      assert io.closed? == true
    end
  end
end
