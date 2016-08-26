require "spec"
require "tempfile"

describe Tempfile do
  it "creates and writes" do
    tempfile = Tempfile.new "foo"
    tempfile.print "Hello!"
    tempfile.close

    assert File.exists?(tempfile.path) == true
    assert File.read(tempfile.path) == "Hello!"
  end

  it "creates and deletes" do
    tempfile = Tempfile.new "foo"
    tempfile.close
    tempfile.delete

    assert File.exists?(tempfile.path) == false
  end

  it "doesn't delete on open with block" do
    tempfile = Tempfile.open("foo") do |f|
      f.print "Hello!"
    end
    assert File.exists?(tempfile.path) == true
  end

  it "creates and writes with TMPDIR environment variable" do
    old_tmpdir = ENV["TMPDIR"]?
    ENV["TMPDIR"] = "/tmp"

    begin
      tempfile = Tempfile.new "foo"
      tempfile.print "Hello!"
      tempfile.close

      assert File.exists?(tempfile.path) == true
      assert File.read(tempfile.path) == "Hello!"
    ensure
      ENV["TMPDIR"] = old_tmpdir if old_tmpdir
    end
  end

  it "is seekable" do
    tempfile = Tempfile.new "foo"
    tempfile.puts "Hello!"
    tempfile.seek(0, IO::Seek::Set)
    assert tempfile.tell == 0
    assert tempfile.pos == 0
    assert tempfile.gets == "Hello!\n"
    tempfile.pos = 0
    assert tempfile.gets == "Hello!\n"
    tempfile.close
  end

  it "returns default directory for tempfiles" do
    old_tmpdir = ENV["TMPDIR"]?
    ENV.delete("TMPDIR")
    assert Tempfile.dirname == "/tmp"
    ENV["TMPDIR"] = old_tmpdir if old_tmpdir
  end

  it "returns configure directory for tempfiles" do
    old_tmpdir = ENV["TMPDIR"]?
    ENV["TMPDIR"] = "/my/tmp"
    assert Tempfile.dirname == "/my/tmp"
    ENV["TMPDIR"] = old_tmpdir if old_tmpdir
  end
end
