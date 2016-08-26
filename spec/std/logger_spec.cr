require "spec"
require "logger"

describe "Logger" do
  it "logs messages" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.debug "debug:skip"
      logger.info "info:show"

      logger.level = Logger::DEBUG
      logger.debug "debug:show"

      logger.level = Logger::WARN
      logger.debug "debug:skip:again"
      logger.info "info:skip"
      logger.error "error:show"

      assert r.gets =~ /info:show/
      assert r.gets =~ /debug:show/
      assert r.gets =~ /error:show/
    end
  end

  it "logs any object" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.info 12345

      assert r.gets =~ /12345/
    end
  end

  it "formats message" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.progname = "crystal"
      logger.warn "message"

      assert r.gets =~ /W, \[.+? #\d+\]  WARN -- crystal: message\n/
    end
  end

  it "uses custom formatter" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << severity[0] << " " << progname << ": " << message
      end
      logger.warn "message", "prog"

      assert r.gets == "W prog: message\n"
    end
  end

  it "yields message" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.error { "message" }
      logger.unknown { "another message" }

      assert r.gets =~ /ERROR -- : message\n/
      assert r.gets =~ /  ANY -- : another message\n/
    end
  end

  it "yields message with progname" do
    IO.pipe do |r, w|
      logger = Logger.new(w)
      logger.error("crystal") { "message" }
      logger.unknown("shard") { "another message" }

      assert r.gets =~ /ERROR -- crystal: message\n/
      assert r.gets =~ /  ANY -- shard: another message\n/
    end
  end

  it "can create a logger with nil (#3065)" do
    logger = Logger.new(nil)
    logger.error("ouch")
  end

  it "doesn't yield to the block with nil" do
    a = 0
    logger = Logger.new(nil)
    logger.info { a = 1 }
    assert a == 0
  end

  it "closes" do
    IO.pipe do |r, w|
      Logger.new(w).close
      assert w.closed? == true
    end
  end
end
