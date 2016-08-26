require "spec"
require "process"
require "tempfile"

describe Process do
  it "runs true" do
    process = Process.new("true")
    assert process.wait.exit_code == 0
  end

  it "runs false" do
    process = Process.new("false")
    assert process.wait.exit_code == 1
  end

  it "returns status 127 if command could not be executed" do
    process = Process.new("foobarbaz")
    assert process.wait.exit_code == 127
  end

  it "run waits for the process" do
    assert Process.run("true").exit_code == 0
  end

  it "runs true in block" do
    Process.run("true") { }
    assert $?.exit_code == 0
  end

  it "receives arguments in array" do
    assert Process.run("/bin/sh", ["-c", "exit 123"]).exit_code == 123
  end

  it "receives arguments in tuple" do
    assert Process.run("/bin/sh", {"-c", "exit 123"}).exit_code == 123
  end

  it "redirects output to /dev/null" do
    # This doesn't test anything but no output should be seen while running tests
    assert Process.run("/bin/ls", output: false).exit_code == 0
  end

  it "gets output" do
    value = Process.run("/bin/sh", {"-c", "echo hello"}) do |proc|
      proc.output.gets_to_end
    end
    assert value == "hello\n"
  end

  it "sends input in IO" do
    value = Process.run("/bin/cat", input: MemoryIO.new("hello")) do |proc|
      assert proc.input?.nil?
      proc.output.gets_to_end
    end
    assert value == "hello"
  end

  it "sends output to IO" do
    output = MemoryIO.new
    Process.run("/bin/sh", {"-c", "echo hello"}, output: output)
    assert output.to_s == "hello\n"
  end

  it "sends error to IO" do
    error = MemoryIO.new
    Process.run("/bin/sh", {"-c", "echo hello 1>&2"}, error: error)
    assert error.to_s == "hello\n"
  end

  it "controls process in block" do
    value = Process.run("/bin/cat") do |proc|
      proc.input.print "hello"
      proc.input.close
      proc.output.gets_to_end
    end
    assert value == "hello"
  end

  it "closes ios after block" do
    Process.run("/bin/cat") { }
    assert $?.exit_code == 0
  end

  it "sets working directory" do
    parent = File.dirname(Dir.current)
    value = Process.run("pwd", shell: true, chdir: parent, output: nil) do |proc|
      proc.output.gets_to_end
    end
    assert value == "#{parent}\n"
  end

  it "disallows passing arguments to nowhere" do
    expect_raises ArgumentError, /args.+@/ do
      Process.run("foo bar", {"baz"}, shell: true)
    end
  end

  it "looks up programs in the $PATH with a shell" do
    proc = Process.run("uname", {"-a"}, shell: true, output: false)
    assert proc.exit_code == 0
  end

  it "allows passing huge argument lists to a shell" do
    proc = Process.new(%(echo "${@}"), {"a", "b"}, shell: true, output: nil)
    output = proc.output.gets_to_end
    proc.wait
    assert output == "a b\n"
  end

  it "does not run shell code in the argument list" do
    proc = Process.new("echo", {"`echo hi`"}, shell: true, output: nil)
    output = proc.output.gets_to_end
    proc.wait
    assert output == "`echo hi`\n"
  end

  describe "environ" do
    it "clears the environment" do
      value = Process.run("env", clear_env: true) do |proc|
        proc.output.gets_to_end
      end
      assert value == ""
    end

    it "sets an environment variable" do
      env = {"FOO" => "bar"}
      value = Process.run("env", clear_env: true, env: env) do |proc|
        proc.output.gets_to_end
      end
      assert value == "FOO=bar\n"
    end

    it "deletes an environment variable" do
      env = {"HOME" => nil}
      value = Process.run("env | egrep '^HOME='", env: env, shell: true) do |proc|
        proc.output.gets_to_end
      end
      assert value == ""
    end
  end

  describe "kill" do
    it "kills a process" do
      process = fork { loop { } }
      assert process.kill(Signal::KILL).nil?
    end

    it "kills many process" do
      process1 = fork { loop { } }
      process2 = fork { loop { } }
      assert process1.kill(Signal::KILL).nil?
      assert process2.kill(Signal::KILL).nil?
    end
  end

  it "gets the pgid of a process id" do
    process = fork { loop { } }
    assert Process.pgid(process.pid).is_a?(Int32)
    process.kill(Signal::KILL)
    assert Process.pgid == Process.pgid(Process.pid)
  end

  it "can link processes together" do
    buffer = MemoryIO.new
    Process.run("/bin/cat") do |cat|
      Process.run("/bin/cat", input: cat.output, output: buffer) do
        1000.times { cat.input.puts "line" }
        cat.close
      end
    end
    assert buffer.to_s.lines.size == 1000
  end

  it "executes the new process with exec" do
    tmpfile = Tempfile.new("crystal-spec-exec")
    tmpfile.close
    tmpfile.unlink
    assert File.exists?(tmpfile.path) == false

    fork = Process.fork do
      Process.exec("/usr/bin/touch", {tmpfile.path})
    end
    fork.wait

    assert File.exists?(tmpfile.path) == true
    tmpfile.unlink
  end

  it "checks for existence" do
    # We can't reliably check whether it ever returns false, since we can't predict
    # how PIDs are used by the system, a new process might be spawned in between
    # reaping the one we would spawn and checking for it, using the now available
    # pid.
    assert Process.exists?(Process.ppid) == true

    process = Process.fork { sleep 5 }
    assert process.exists? == true
    assert process.terminated? == false

    # Kill, zombie now
    process.kill
    assert process.exists? == true
    assert process.terminated? == false

    # Reap, gone now
    process.wait
    assert process.exists? == false
    assert process.terminated? == true
  end
end
