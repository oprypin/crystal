require "spec"
require "zlib"

module Zlib
  describe Inflate do
    it "should be able to inflate" do
      io = MemoryIO.new
      "789c2bc9c82c5600a2448592d4e21285e292a2ccbc74054520e00200854f087b".scan(/../).each do |match|
        io.write_byte match[0].to_u8(16)
      end
      io.rewind

      inflate = Inflate.new(io)

      str = String::Builder.build do |builder|
        IO.copy(inflate, builder)
      end

      assert str == "this is a test string !!!!\n"
      assert inflate.read(Slice(UInt8).new(10)) == 0
    end

    it "can be closed without sync" do
      io = MemoryIO.new("")
      inflate = Inflate.new(io)
      inflate.close
      assert inflate.closed? == true
      assert io.closed? == false

      expect_raises IO::Error, "closed stream" do
        inflate.gets
      end
    end

    it "can be closed with sync (1)" do
      io = MemoryIO.new("")
      inflate = Inflate.new(io, sync_close: true)
      inflate.close
      assert inflate.closed? == true
      assert io.closed? == true
    end

    it "can be closed with sync (2)" do
      io = MemoryIO.new("")
      inflate = Inflate.new(io)
      inflate.sync_close = true
      inflate.close
      assert inflate.closed? == true
      assert io.closed? == true
    end

    it "should not inflate from empty stream" do
      io = MemoryIO.new("")
      inflate = Inflate.new(io)
      assert inflate.read_byte.nil?
    end

    it "should not freeze when reading empty slice" do
      io = MemoryIO.new
      "789c2bc9c82c5600a2448592d4e21285e292a2ccbc74054520e00200854f087b".scan(/../).each do |match|
        io.write_byte match[0].to_u8(16)
      end
      io.rewind
      inflate = Inflate.new(io)
      slice = Slice(UInt8).new(0)
      assert inflate.read(slice) == 0
    end
  end
end
