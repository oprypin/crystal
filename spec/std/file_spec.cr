require "spec"
require "tempfile"

private def base
  Dir.current
end

private def tmpdir
  "/tmp"
end

private def rootdir
  "/"
end

private def home
  ENV["HOME"]
end

private def it_raises_on_null_byte(operation, &block)
  it "errors on #{operation}" do
    expect_raises(ArgumentError, "string contains null byte") do
      block.call
    end
  end
end

describe "File" do
  it "gets path" do
    path = "#{__DIR__}/data/test_file.txt"
    file = File.new path
    assert file.path == path
  end

  it "reads entire file" do
    str = File.read "#{__DIR__}/data/test_file.txt"
    assert str == "Hello World\n" * 20
  end

  it "reads lines from file" do
    lines = File.read_lines "#{__DIR__}/data/test_file.txt"
    assert lines.size == 20
    assert lines.first == "Hello World\n"
  end

  it "reads lines from file with each" do
    idx = 0
    File.each_line("#{__DIR__}/data/test_file.txt") do |line|
      if idx == 0
        assert line == "Hello World\n"
      end
      idx += 1
    end
    assert idx == 20
  end

  it "reads lines from file with each as iterator" do
    idx = 0
    File.each_line("#{__DIR__}/data/test_file.txt").each do |line|
      if idx == 0
        assert line == "Hello World\n"
      end
      idx += 1
    end
    assert idx == 20
  end

  describe "exists?" do
    it "gives true" do
      assert File.exists?("#{__DIR__}/data/test_file.txt") == true
    end

    it "gives false" do
      assert File.exists?("#{__DIR__}/data/non_existing_file.txt") == false
    end
  end

  describe "executable?" do
    it "gives false" do
      assert File.executable?("#{__DIR__}/data/test_file.txt") == false
    end
  end

  describe "readable?" do
    it "gives true" do
      assert File.readable?("#{__DIR__}/data/test_file.txt") == true
    end
  end

  describe "writable?" do
    it "gives true" do
      assert File.writable?("#{__DIR__}/data/test_file.txt") == true
    end
  end

  describe "file?" do
    it "gives true" do
      assert File.file?("#{__DIR__}/data/test_file.txt") == true
    end

    it "gives false" do
      assert File.file?("#{__DIR__}/data") == false
    end
  end

  describe "directory?" do
    it "gives true" do
      assert File.directory?("#{__DIR__}/data") == true
    end

    it "gives false" do
      assert File.directory?("#{__DIR__}/data/test_file.txt") == false
    end
  end

  describe "link" do
    it "creates a hard link" do
      out_path = "#{__DIR__}/data/test_file_link.txt"
      begin
        File.link("#{__DIR__}/data/test_file.txt", out_path)
        assert File.exists?(out_path) == true
      ensure
        File.delete(out_path) if File.exists?(out_path)
      end
    end
  end

  describe "symlink" do
    it "creates a symbolic link" do
      out_path = "#{__DIR__}/data/test_file_symlink.txt"
      begin
        File.symlink("#{__DIR__}/data/test_file.txt", out_path)
        assert File.symlink?(out_path) == true
      ensure
        File.delete(out_path) if File.exists?(out_path)
      end
    end
  end

  describe "symlink?" do
    it "gives true" do
      assert File.symlink?("#{__DIR__}/data/symlink.txt") == true
    end

    it "gives false" do
      assert File.symlink?("#{__DIR__}/data/test_file.txt") == false
      assert File.symlink?("#{__DIR__}/data/unknown_file.txt") == false
    end
  end

  it "gets dirname" do
    assert File.dirname("/Users/foo/bar.cr") == "/Users/foo"
    assert File.dirname("foo") == "."
    assert File.dirname("") == "."
  end

  it "gets basename" do
    assert File.basename("/foo/bar/baz.cr") == "baz.cr"
    assert File.basename("/foo/") == "foo"
    assert File.basename("foo") == "foo"
    assert File.basename("") == ""
    assert File.basename("/") == "/"
  end

  it "gets basename removing suffix" do
    assert File.basename("/foo/bar/baz.cr", ".cr") == "baz"
  end

  it "gets extname" do
    assert File.extname("/foo/bar/baz.cr") == ".cr"
    assert File.extname("/foo/bar/baz.cr.cz") == ".cz"
    assert File.extname("/foo/bar/.profile") == ""
    assert File.extname("/foo/bar/.profile.sh") == ".sh"
    assert File.extname("/foo/bar/foo.") == ""
    assert File.extname("test") == ""
  end

  it "constructs a path from parts" do
    assert File.join(["///foo", "bar"]) == "///foo/bar"
    assert File.join(["///foo", "//bar"]) == "///foo//bar"
    assert File.join(["/foo/", "/bar"]) == "/foo/bar"
    assert File.join(["foo", "bar", "baz"]) == "foo/bar/baz"
    assert File.join(["foo", "//bar//", "baz///"]) == "foo//bar//baz///"
    assert File.join(["/foo/", "/bar/", "/baz/"]) == "/foo/bar/baz/"
  end

  it "gets stat for this file" do
    stat = File.stat(__FILE__)
    assert stat.blockdev? == false
    assert stat.chardev? == false
    assert stat.directory? == false
    assert stat.file? == true
    assert stat.symlink? == false
    assert stat.socket? == false
  end

  it "gets stat for this directory" do
    stat = File.stat(__DIR__)
    assert stat.blockdev? == false
    assert stat.chardev? == false
    assert stat.directory? == true
    assert stat.file? == false
    assert stat.symlink? == false
    assert stat.socket? == false
  end

  it "gets stat for a character device" do
    stat = File.stat("/dev/null")
    assert stat.blockdev? == false
    assert stat.chardev? == true
    assert stat.directory? == false
    assert stat.file? == false
    assert stat.symlink? == false
    assert stat.socket? == false
  end

  it "gets stat for a symlink" do
    stat = File.lstat("#{__DIR__}/data/symlink.txt")
    assert stat.blockdev? == false
    assert stat.chardev? == false
    assert stat.directory? == false
    assert stat.file? == false
    assert stat.symlink? == true
    assert stat.socket? == false
  end

  it "gets stat for open file" do
    File.open(__FILE__, "r") do |file|
      stat = file.stat
      assert stat.blockdev? == false
      assert stat.chardev? == false
      assert stat.directory? == false
      assert stat.file? == true
      assert stat.symlink? == false
      assert stat.socket? == false
    end
  end

  it "gets stat for non-existent file and raises" do
    expect_raises Errno do
      File.stat("non-existent")
    end
  end

  it "gets stat mtime for new file" do
    tmp = Tempfile.new "tmp"
    begin
      assert (tmp.stat.atime - Time.utc_now).total_seconds < 5
      assert (tmp.stat.ctime - Time.utc_now).total_seconds < 5
      assert (tmp.stat.mtime - Time.utc_now).total_seconds < 5
    ensure
      tmp.delete
    end
  end

  describe "size" do
    it { assert File.size("#{__DIR__}/data/test_file.txt") == 240 }
    it do
      File.open("#{__DIR__}/data/test_file.txt", "r") do |file|
        assert file.size == 240
      end
    end
  end

  describe "delete" do
    it "deletes a file" do
      filename = "#{__DIR__}/data/temp1.txt"
      File.open(filename, "w") { }
      assert File.exists?(filename) == true
      File.delete(filename)
      assert File.exists?(filename) == false
    end

    it "raises errno when file doesn't exist" do
      filename = "#{__DIR__}/data/temp1.txt"
      expect_raises Errno do
        File.delete(filename)
      end
    end
  end

  describe "rename" do
    it "renames a file" do
      filename = "#{__DIR__}/data/temp1.txt"
      filename2 = "#{__DIR__}/data/temp2.txt"
      File.open(filename, "w") { |f| f.puts "hello" }
      File.rename(filename, filename2)
      assert File.exists?(filename) == false
      assert File.exists?(filename2) == true
      assert File.read(filename2).strip == "hello"
      File.delete(filename2)
    end

    it "raises if old file doesn't exist" do
      filename = "#{__DIR__}/data/temp1.txt"
      expect_raises Errno do
        File.rename(filename, "#{filename}.new")
      end
    end
  end

  describe "expand_path" do
    it "converts a pathname to an absolute pathname" do
      assert File.expand_path("") == base
      assert File.expand_path("a") == File.join([base, "a"])
      assert File.expand_path("a", nil) == File.join([base, "a"])
    end

    it "converts a pathname to an absolute pathname, Ruby-Talk:18512" do
      assert File.expand_path(".a") == File.join([base, ".a"])
      assert File.expand_path("..a") == File.join([base, "..a"])
      assert File.expand_path("a../b") == File.join([base, "a../b"])
    end

    it "keeps trailing dots on absolute pathname" do
      assert File.expand_path("a.") == File.join([base, "a."])
      assert File.expand_path("a..") == File.join([base, "a.."])
    end

    it "converts a pathname to an absolute pathname, using a complete path" do
      assert File.expand_path("", "#{tmpdir}") == "#{tmpdir}"
      assert File.expand_path("a", "#{tmpdir}") == "#{tmpdir}/a"
      assert File.expand_path("../a", "#{tmpdir}/xxx") == "#{tmpdir}/a"
      assert File.expand_path(".", "#{rootdir}") == "#{rootdir}"
    end

    it "expands a path with multi-byte characters" do
      assert File.expand_path("Ångström") == "#{base}/Ångström"
    end

    it "expands /./dir to /dir" do
      assert File.expand_path("/./dir") == "/dir"
    end

    it "replaces multiple / with a single /" do
      assert File.expand_path("////some/path") == "/some/path"
      assert File.expand_path("/some////path") == "/some/path"
    end

    it "expand path with" do
      assert File.expand_path("../../bin", "/tmp/x") == "/bin"
      assert File.expand_path("../../bin", "/tmp") == "/bin"
      assert File.expand_path("../../bin", "/") == "/bin"
      assert File.expand_path("../bin", "tmp/x") == File.join([base, "tmp", "bin"])
      assert File.expand_path("../bin", "x/../tmp") == File.join([base, "bin"])
    end

    it "expand_path for commoms unix path  give a full path" do
      assert File.expand_path("/tmp/") == "/tmp"
      assert File.expand_path("/tmp/../../../tmp") == "/tmp"
      assert File.expand_path("") == base
      assert File.expand_path("./////") == base
      assert File.expand_path(".") == base
      assert File.expand_path(base) == base
    end

    it "converts a pathname to an absolute pathname, using ~ (home) as base" do
      assert File.expand_path("~/") == home
      assert File.expand_path("~/..badfilename") == File.join(home, "..badfilename")
      assert File.expand_path("..") == "/#{base.split("/")[0...-1].join("/")}".gsub(%r{\A//}, "/")
      assert File.expand_path("~/a", "~/b") == File.join(home, "a")
      assert File.expand_path("~") == home
      assert File.expand_path("~", "/tmp/gumby/ddd") == home
      assert File.expand_path("~/a", "/tmp/gumby/ddd") == File.join([home, "a"])
    end
  end

  describe "real_path" do
    it "expands paths for normal files" do
      assert File.real_path("/usr/share") == "/usr/share"
      assert File.real_path("/usr/share/..") == "/usr"
    end

    it "raises Errno if file doesn't exist" do
      expect_raises Errno do
        File.real_path("/usr/share/foo/bar")
      end
    end

    it "expands paths of symlinks" do
      symlink_path = "/tmp/test_file_symlink.txt"
      file_path = "#{__DIR__}/data/test_file.txt"
      begin
        File.symlink(file_path, symlink_path)
        real_symlink_path = File.real_path(symlink_path)
        real_file_path = File.real_path(file_path)
        assert real_symlink_path == real_file_path
      ensure
        File.delete(symlink_path) if File.exists?(symlink_path)
      end
    end
  end

  describe "write" do
    it "can write to a file" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello")
      assert File.read(filename) == "hello"
      File.delete(filename)
    end

    it "raises if trying to write to a file not opened for writing" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello")
      expect_raises(IO::Error, "File not open for writing") do
        File.open(filename) { |file| file << "hello" }
      end
      File.delete(filename)
    end
  end

  it "does to_s" do
    file = File.new(__FILE__)
    assert file.to_s == "#<File:0x#{file.object_id.to_s(16)}>"
    assert File.new(__FILE__).inspect == "#<File:#{__FILE__}>"
  end

  describe "close" do
    it "is not closed when opening" do
      file = File.new(__FILE__)
      assert file.closed? == false
    end

    it "is closed when closed" do
      file = File.new(__FILE__)
      file.close
      assert file.closed? == true
    end

    it "should not raise when closing twice" do
      file = File.new(__FILE__)
      file.close
      file.close
    end

    it "does to_s when closed" do
      file = File.new(__FILE__)
      file.close
      assert file.to_s == "#<File:0x#{file.object_id.to_s(16)}>"
      assert file.inspect == "#<File:#{__FILE__} (closed)>"
    end
  end

  it "opens with perm" do
    filename = "#{__DIR__}/data/temp_write.txt"
    perm = 0o600
    File.open(filename, "w", perm) do |file|
      assert file.stat.perm == perm
    end
    File.delete filename
  end

  it "clears the read buffer after a seek" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    assert file.gets(5) == "Hello"
    file.seek(1)
    assert file.gets(4) == "ello"
  end

  it "raises if invoking seek with a closed file" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    file.close
    expect_raises(IO::Error, "closed stream") { file.seek(1) }
  end

  it "returns the current read position with tell" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    assert file.tell == 0
    assert file.gets(5) == "Hello"
    assert file.tell == 5
    file.sync = true
    assert file.tell == 5
  end

  it "can navigate with pos" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    file.pos = 3
    assert file.gets(2) == "lo"
    file.pos -= 4
    assert file.gets(4) == "ello"
  end

  it "raises if invoking tell with a closed file" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    file.close
    expect_raises(IO::Error, "closed stream") { file.tell }
  end

  it "iterates with each_char" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    i = 0
    file.each_char do |char|
      case i
      when 0 then assert char == 'H'
      when 1 then assert char == 'e'
      else
        break
      end
      i += 1
    end
  end

  it "iterates with each_byte" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    i = 0
    file.each_byte do |byte|
      case i
      when 0 then assert byte == 'H'.ord
      when 1 then assert byte == 'e'.ord
      else
        break
      end
      i += 1
    end
  end

  it "rewinds" do
    file = File.new("#{__DIR__}/data/test_file.txt")
    content = file.gets_to_end
    assert content.size != 0
    file.rewind
    assert file.gets_to_end == content
  end

  describe "truncate" do
    it "truncates" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "0123456789")
      File.open(filename, "r+") do |f|
        assert f.gets_to_end == "0123456789"
        f.rewind
        f.puts("333")
        f.truncate(4)
      end

      assert File.read(filename) == "333\n"
      File.delete filename
    end

    it "truncates completely when no size is passed" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "0123456789")
      File.open(filename, "r+") do |f|
        f.puts("333")
        f.truncate
      end

      assert File.read(filename) == ""
      File.delete filename
    end

    it "requires a file opened for writing" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "0123456789")
      File.open(filename, "r") do |f|
        expect_raises(Errno) do
          f.truncate(4)
        end
      end
      File.delete filename
    end
  end

  describe "flock" do
    it "exlusively locks a file" do
      File.open(__FILE__) do |file1|
        File.open(__FILE__) do |file2|
          file1.flock_exclusive do
            # BUG: check for EWOULDBLOCK when exception filters are implemented
            expect_raises(Errno) do
              file2.flock_exclusive(blocking: false) { }
            end
          end
        end
      end
    end

    it "shared locks a file" do
      File.open(__FILE__) do |file1|
        File.open(__FILE__) do |file2|
          file1.flock_shared do
            file2.flock_shared(blocking: false) { }
          end
        end
      end
    end
  end

  describe "raises on null byte" do
    it_raises_on_null_byte "new" do
      File.new("foo\0bar")
    end

    it_raises_on_null_byte "join" do
      File.join("foo", "\0bar")
    end

    it_raises_on_null_byte "size" do
      File.size("foo\0bar")
    end

    it_raises_on_null_byte "rename (first arg)" do
      File.rename("foo\0bar", "baz")
    end

    it_raises_on_null_byte "rename (second arg)" do
      File.rename("baz", "foo\0bar")
    end

    it_raises_on_null_byte "stat" do
      File.stat("foo\0bar")
    end

    it_raises_on_null_byte "lstat" do
      File.lstat("foo\0bar")
    end

    it_raises_on_null_byte "exists?" do
      File.exists?("foo\0bar")
    end

    it_raises_on_null_byte "readable?" do
      File.readable?("foo\0bar")
    end

    it_raises_on_null_byte "writable?" do
      File.writable?("foo\0bar")
    end

    it_raises_on_null_byte "executable?" do
      File.executable?("foo\0bar")
    end

    it_raises_on_null_byte "file?" do
      File.file?("foo\0bar")
    end

    it_raises_on_null_byte "directory?" do
      File.directory?("foo\0bar")
    end

    it_raises_on_null_byte "dirname" do
      File.dirname("foo\0bar")
    end

    it_raises_on_null_byte "basename" do
      File.basename("foo\0bar")
    end

    it_raises_on_null_byte "basename 2, first arg" do
      File.basename("foo\0bar", "baz")
    end

    it_raises_on_null_byte "basename 2, second arg" do
      File.basename("foobar", "baz\0")
    end

    it_raises_on_null_byte "delete" do
      File.delete("foo\0bar")
    end

    it_raises_on_null_byte "extname" do
      File.extname("foo\0bar")
    end

    it_raises_on_null_byte "expand_path, first arg" do
      File.expand_path("foo\0bar")
    end

    it_raises_on_null_byte "expand_path, second arg" do
      File.expand_path("baz", "foo\0bar")
    end

    it_raises_on_null_byte "link, first arg" do
      File.link("foo\0bar", "baz")
    end

    it_raises_on_null_byte "link, second arg" do
      File.link("baz", "foo\0bar")
    end

    it_raises_on_null_byte "symlink, first arg" do
      File.symlink("foo\0bar", "baz")
    end

    it_raises_on_null_byte "symlink, second arg" do
      File.symlink("baz", "foo\0bar")
    end

    it_raises_on_null_byte "symlink?" do
      File.symlink?("foo\0bar")
    end
  end

  describe "encoding" do
    it "writes with encoding" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello", encoding: "UCS-2LE")
      assert File.read(filename).to_slice == "hello".encode("UCS-2LE")
      File.delete(filename)
    end

    it "reads with encoding" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello", encoding: "UCS-2LE")
      assert File.read(filename, encoding: "UCS-2LE") == "hello"
      File.delete(filename)
    end

    it "opens with encoding" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello", encoding: "UCS-2LE")
      File.open(filename, encoding: "UCS-2LE") do |file|
        assert file.gets_to_end == "hello"
      end
      File.delete filename
    end

    it "does each line with encoding" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello", encoding: "UCS-2LE")
      File.each_line(filename, encoding: "UCS-2LE") do |line|
        assert line == "hello"
      end
      File.delete filename
    end

    it "reads lines with encoding" do
      filename = "#{__DIR__}/data/temp_write.txt"
      File.write(filename, "hello", encoding: "UCS-2LE")
      assert File.read_lines(filename, encoding: "UCS-2LE") == ["hello"]
      File.delete filename
    end
  end

  describe "closed stream" do
    it "raises if writing on a closed stream" do
      io = File.open(__FILE__, "r")
      io.close

      expect_raises(IO::Error, "closed stream") { io.gets_to_end }
      expect_raises(IO::Error, "closed stream") { io.print "hi" }
      expect_raises(IO::Error, "closed stream") { io.puts "hi" }
      expect_raises(IO::Error, "closed stream") { io.seek(1) }
      expect_raises(IO::Error, "closed stream") { io.gets }
      expect_raises(IO::Error, "closed stream") { io.read_byte }
      expect_raises(IO::Error, "closed stream") { io.write_byte('a'.ord.to_u8) }
    end
  end
end
