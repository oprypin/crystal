require "c/signal"
require "c/stdlib"
require "c/sys/resource"
require "c/unistd"

module Crystal::System::Process
  def self.exit(status)
    LibC.exit(status)
  end

  def self.pid
    LibC.getpid
  end

  def self.parent_pid
    LibC.getppid
  end

  def self.process_gid
    ret = LibC.getpgid(0)
    raise RuntimeError.from_errno("getpgid") if ret < 0
    ret
  end

  def self.process_gid(pid)
    # Disallow users from depending on ppid(0) instead of `process_gid`
    raise RuntimeError.from_errno("getpgid", Errno::EINVAL) if pid == 0

    ret = LibC.getpgid(pid)
    raise RuntimeError.from_errno("getpgid") if ret < 0
    ret
  end

  def self.signal(pid, signal)
    ret = LibC.kill(pid, signal)
    raise RuntimeError.from_errno("kill") if ret < 0
  end

  def self.exists?(pid)
    if LibC.kill(pid, 0) == 0
      true
    elsif Errno.value == Errno::ESRCH
      false
    else
      raise RuntimeError.from_errno("kill")
    end
  end

  def self.fork
    case pid = LibC.fork
    when -1
      raise RuntimeError.from_errno("fork")
    when 0
      nil
    else
      pid
    end
  end

  def self.spawn(command, args, env, clear_env, input, output, error, chdir) : Int32
    reader_pipe, writer_pipe = IO.pipe

    if pid = self.fork
      writer_pipe.close
      bytes = uninitialized UInt8[4]
      if reader_pipe.read(bytes.to_slice) == 4
        message_size = IO::ByteFormat::SystemEndian.decode(Int32, bytes.to_slice)
        if message_size > 0
          message = String.build(message_size) { |io| IO.copy(reader_pipe, io, message_size) }
        end
        reader_pipe.close
        raise RuntimeError.new("Error executing process: #{message}")
      end
      reader_pipe.close

      pid
    else
      begin
        reader_pipe.close
        writer_pipe.close_on_exec = true
        self.replace(command, args, env, clear_env, input, output, error, chdir)
      rescue ex
        writer_pipe.write_bytes(ex.message.try(&.bytesize) || 0)
        writer_pipe << ex.message
        writer_pipe.close
      ensure
        LibC._exit 127
      end
    end
  end

  private def self.to_real_fd(fd : IO::FileDescriptor)
    case fd
    when STDIN
      ORIGINAL_STDIN
    when STDOUT
      ORIGINAL_STDOUT
    when STDERR
      ORIGINAL_STDERR
    else
      fd
    end
  end

  private def self.reopen_io(src_io : IO::FileDescriptor, dst_io : IO::FileDescriptor)
    src_io = to_real_fd(src_io)

    if src_io.closed?
      dst_io.close
      return
    end
    dst_io.reopen(src_io) if src_io.fd != dst_io.fd
    dst_io.blocking = true
    dst_io.close_on_exec = false
  end

  def self.replace(command, args, env, clear_env, input, output, error, chdir) : NoReturn
    reopen_io(input, ORIGINAL_STDIN)
    reopen_io(output, ORIGINAL_STDOUT)
    reopen_io(error, ORIGINAL_STDERR)

    ENV.clear if clear_env
    env.try &.each do |key, val|
      if val
        ENV[key] = val
      else
        ENV.delete key
      end
    end

    ::Dir.cd(chdir) if chdir

    argv = [command.check_no_null_byte.to_unsafe]
    args.try &.each do |arg|
      argv << arg.check_no_null_byte.to_unsafe
    end
    argv << Pointer(UInt8).null

    LibC.execvp(command, argv)
    raise RuntimeError.from_errno
  end

  def self.wait(pid)
    Event::SignalChildHandler.instance.waitpid(pid)
  end
end
