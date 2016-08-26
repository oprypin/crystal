require "spec"
require "zlib"

module Zlib
  describe Deflate do
    it "should be able to deflate" do
      message = "this is a test string !!!!\n"
      io = MemoryIO.new
      deflate = Deflate.new(io)
      deflate.print message
      deflate.close

      io.rewind
      inflate = Inflate.new(io)
      assert inflate.gets_to_end == message
    end

    it "can be closed without sync" do
      io = MemoryIO.new
      deflate = Deflate.new(io)
      deflate.close
      assert deflate.closed? == true
      assert io.closed? == false

      expect_raises IO::Error, "closed stream" do
        deflate.print "a"
      end
    end

    it "can be closed with sync (1)" do
      io = MemoryIO.new
      deflate = Deflate.new(io, sync_close: true)
      deflate.close
      assert deflate.closed? == true
      assert io.closed? == true
    end

    it "can be closed with sync (2)" do
      io = MemoryIO.new
      deflate = Deflate.new(io)
      deflate.sync_close = true
      deflate.close
      assert deflate.closed? == true
      assert io.closed? == true
    end

    it "can be flushed" do
      io = MemoryIO.new
      deflate = Deflate.new(io)

      deflate.print "this"
      assert io.to_slice.hexstring == "789c"

      deflate.flush
      assert (io.to_slice.hexstring.size > 4) == true

      deflate.print " is a test string !!!!\n"
      deflate.close

      io.rewind
      inflate = Inflate.new(io)
      assert inflate.gets_to_end == "this is a test string !!!!\n"
    end
  end
end
