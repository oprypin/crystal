require "spec"
require "process"
require "./spec_helper"
require "../spec_helper"

describe Process do
  it "runs true" do
    process = Process.new("true")
    process.wait.exit_code.should eq(0)
  end

  it "runs false" do
    process = Process.new("false")
    process.wait.exit_code.should eq(1)
  end

  it "raises if command could not be executed" do
    expect_raises(RuntimeError, "Error executing process: No such file or directory") do
      Process.new("foobarbaz", ["foo"])
    end
  end

  it "run waits for the process" do
    Process.run("true").exit_code.should eq(0)
  end

  it "runs true in block" do
    Process.run("true") { }
    $?.exit_code.should eq(0)
  end

  it "receives arguments in array" do
    Process.run("/bin/sh", ["-c", "exit 123"]).exit_code.should eq(123)
  end

  it "receives arguments in tuple" do
    Process.run("/bin/sh", {"-c", "exit 123"}).exit_code.should eq(123)
  end

  it "redirects output to /dev/null" do
    # This doesn't test anything but no output should be seen while running tests
    Process.run("/bin/ls", output: Process::Redirect::Close).exit_code.should eq(0)
  end

  it "gets output" do
    value = Process.run("/bin/sh", {"-c", "echo hello"}) do |proc|
      proc.output.gets_to_end
    end
    value.should eq("hello\n")
  end

  it "sends input in IO" do
    value = Process.run("/bin/cat", input: IO::Memory.new("hello")) do |proc|
      proc.input?.should be_nil
      proc.output.gets_to_end
    end
    value.should eq("hello")
  end

  it "sends output to IO" do
    output = IO::Memory.new
    Process.run("/bin/sh", {"-c", "echo hello"}, output: output)
    output.to_s.should eq("hello\n")
  end

  it "sends error to IO" do
    error = IO::Memory.new
    Process.run("/bin/sh", {"-c", "echo hello 1>&2"}, error: error)
    error.to_s.should eq("hello\n")
  end

  it "controls process in block" do
    value = Process.run("/bin/cat") do |proc|
      proc.input.print "hello"
      proc.input.close
      proc.output.gets_to_end
    end
    value.should eq("hello")
  end

  it "closes ios after block" do
    Process.run("/bin/cat") { }
    $?.exit_code.should eq(0)
  end

  it "chroot raises when unprivileged" do
    status, output = build_and_run <<-'CODE'
      begin
        Process.chroot("/usr")
        puts "FAIL"
      rescue ex
        puts ex.inspect
      end
    CODE

    status.success?.should be_true
    output.should eq("#<RuntimeError:Failed to chroot: Operation not permitted>\n")
  end

  it "sets working directory" do
    parent = File.dirname(Dir.current)
    value = Process.run("pwd", shell: true, chdir: parent, output: Process::Redirect::Pipe) do |proc|
      proc.output.gets_to_end
    end
    value.should eq "#{parent}\n"
  end

  it "disallows passing arguments to nowhere" do
    expect_raises ArgumentError, /args.+@/ do
      Process.run("foo bar", {"baz"}, shell: true)
    end
  end

  it "looks up programs in the $PATH with a shell" do
    proc = Process.run("uname", {"-a"}, shell: true, output: Process::Redirect::Close)
    proc.exit_code.should eq(0)
  end

  it "allows passing huge argument lists to a shell" do
    proc = Process.new(%(echo "${@}"), {"a", "b"}, shell: true, output: Process::Redirect::Pipe)
    output = proc.output.gets_to_end
    proc.wait
    output.should eq "a b\n"
  end

  it "does not run shell code in the argument list" do
    proc = Process.new("echo", {"`echo hi`"}, shell: true, output: Process::Redirect::Pipe)
    output = proc.output.gets_to_end
    proc.wait
    output.should eq "`echo hi`\n"
  end

  describe "environ" do
    it "clears the environment" do
      value = Process.run("env", clear_env: true) do |proc|
        proc.output.gets_to_end
      end
      value.should eq("")
    end

    it "sets an environment variable" do
      env = {"FOO" => "bar"}
      value = Process.run("env", clear_env: true, env: env) do |proc|
        proc.output.gets_to_end
      end
      value.should eq("FOO=bar\n")
    end

    it "deletes an environment variable" do
      env = {"HOME" => nil}
      value = Process.run("env | egrep '^HOME='", env: env, shell: true) do |proc|
        proc.output.gets_to_end
      end
      value.should eq("")
    end
  end

  describe "signal" do
    it "kills a process" do
      process = Process.new("yes")
      process.signal(Signal::KILL).should be_nil
    end

    it "kills many process" do
      process1 = Process.new("yes")
      process2 = Process.new("yes")
      process1.signal(Signal::KILL).should be_nil
      process2.signal(Signal::KILL).should be_nil
    end
  end

  it "gets the pgid of a process id" do
    process = Process.new("yes")
    Process.pgid(process.pid).should be_a(Int64)
    process.signal(Signal::KILL)
    Process.pgid.should eq(Process.pgid(Process.pid))
  end

  it "can link processes together" do
    buffer = IO::Memory.new
    Process.run("/bin/cat") do |cat|
      Process.run("/bin/cat", input: cat.output, output: buffer) do
        1000.times { cat.input.puts "line" }
        cat.close
      end
    end
    buffer.to_s.lines.size.should eq(1000)
  end

  {% unless flag?(:preview_mt) %}
    it "executes the new process with exec" do
      with_tempfile("crystal-spec-exec") do |path|
        File.exists?(path).should be_false

        fork = Process.fork do
          Process.exec("/usr/bin/env", {"touch", path})
        end
        fork.wait

        File.exists?(path).should be_true
      end
    end
  {% end %}

  it "checks for existence" do
    # We can't reliably check whether it ever returns false, since we can't predict
    # how PIDs are used by the system, a new process might be spawned in between
    # reaping the one we would spawn and checking for it, using the now available
    # pid.
    Process.exists?(Process.ppid).should be_true

    process = Process.new("yes")
    process.exists?.should be_true
    process.terminated?.should be_false

    # Kill, zombie now
    process.signal(Signal::KILL)
    process.exists?.should be_true
    process.terminated?.should be_false

    # Reap, gone now
    process.wait
    process.exists?.should be_false
    process.terminated?.should be_true
  end

  it "terminates the process" do
    process = Process.new("yes")
    process.exists?.should be_true
    process.terminated?.should be_false

    process.terminate
    process.wait
  end

  describe "executable_path" do
    it "searches executable" do
      Process.executable_path.should be_a(String | Nil)
    end
  end

  describe "find_executable" do
    pwd = Process::INITIAL_PWD
    crystal_path = File.join(pwd, "bin", "crystal")

    it "resolves absolute executable" do
      Process.find_executable(File.join(pwd, "bin", "crystal")).should eq(crystal_path)
    end

    it "resolves relative executable" do
      Process.find_executable(File.join("bin", "crystal")).should eq(crystal_path)
      Process.find_executable(File.join("..", File.basename(pwd), "bin", "crystal")).should eq(crystal_path)
    end

    it "searches within PATH" do
      (path = Process.find_executable("ls")).should_not be_nil
      path.not_nil!.should match(/#{File::SEPARATOR}ls$/)

      (path = Process.find_executable("crystal")).should_not be_nil
      path.not_nil!.should match(/#{File::SEPARATOR}crystal$/)

      Process.find_executable("some_very_unlikely_file_to_exist").should be_nil
    end
  end

  describe "quote_posix" do
    it { Process.quote_posix("").should eq "''" }
    it { Process.quote_posix(" ").should eq "' '" }
    it { Process.quote_posix("$hi").should eq "'$hi'" }
    it { Process.quote_posix(orig = "aZ5+,-./:=@_").should eq orig }
    it { Process.quote_posix(orig = "cafe").should eq orig }
    it { Process.quote_posix("café").should eq "'café'" }
    it { Process.quote_posix("I'll").should eq %('I'"'"'ll') }
    it { Process.quote_posix("'").should eq %(''"'"'') }
    it { Process.quote_posix("\\").should eq "'\\'" }

    context "join" do
      it { Process.quote_posix([] of String).should eq "" }
      it { Process.quote_posix(["my file.txt", "another.txt"]).should eq "'my file.txt' another.txt" }
      it { Process.quote_posix(["foo ", "", " ", " bar"]).should eq "'foo ' '' ' ' ' bar'" }
      it { Process.quote_posix(["foo'", "\"bar"]).should eq %('foo'"'"'' '"bar') }
    end
  end

  describe "quote_windows" do
    it { Process.quote_windows("").should eq %("") }
    it { Process.quote_windows(" ").should eq %(" ") }
    it { Process.quote_windows(orig = "%hi%").should eq orig }
    it { Process.quote_windows(%q(C:\"foo" project.txt)).should eq %q("C:\\\"foo\" project.txt") }
    it { Process.quote_windows(%q(C:\"foo"_project.txt)).should eq %q(C:\\\"foo\"_project.txt) }
    it { Process.quote_windows(%q(C:\Program Files\Foo Bar\foobar.exe)).should eq %q("C:\Program Files\Foo Bar\foobar.exe") }
    it { Process.quote_windows(orig = "café").should eq orig }
    it { Process.quote_windows(%(")).should eq %q(\") }
    it { Process.quote_windows(%q(a\\b\ c\)).should eq %q("a\\b\ c\\") }
    it { Process.quote_windows(orig = %q(a\\b\c\)).should eq orig }

    context "join" do
      it { Process.quote_windows([] of String).should eq "" }
      it { Process.quote_windows(["my file.txt", "another.txt"]).should eq %("my file.txt" another.txt) }
      it { Process.quote_windows(["foo ", "", " ", " bar"]).should eq %("foo " "" " " " bar") }
    end
  end
end
