require "c/processthreadsapi"

module Crystal::System::Process
  def self.exit(status)
    LibC.exit(status)
  end

  def self.pid
    LibC.GetCurrentProcessId
  end

  def self.parent_pid
    # TODO: Implement this using CreateToolhelp32Snapshot
    raise NotImplementedError.new("Process.ppid")
  end

  def self.process_gid
    raise NotImplementedError.new("Process.pgid")
  end

  def self.process_gid(pid)
    raise NotImplementedError.new("Process.pgid")
  end

  def self.fork
    raise NotImplementedError.new("Process.fork")
  end

  private def self.args_to_string(command : String, args, io : IO)
    command_args = Array(String).new((args.try(&.size) || 0) + 1)
    command_args << command
    args.try &.each do |arg|
      command_args << arg
    end

    first_arg = true
    command_args.join(' ', io) do |arg|
      quotes = first_arg || arg.size == 0 || arg.includes?(' ') || arg.includes?('\t')
      first_arg = false

      io << '"' if quotes

      slashes = 0
      arg.each_char do |c|
        case c
        when '\\'
          slashes += 1
        when '"'
          (slashes + 1).times { io << '\\' }
          slashes = 0
        else
          slashes = 0
        end

        io << c
      end

      if quotes
        slashes.times { io << '\\' }
        io << '"'
      end
    end
  end

  private def self.handle_from_io(io : IO::FileDescriptor, parent_io)
    ret = LibC._get_osfhandle(io.fd)
    raise Errno.new("_get_osfhandle") if ret == -1
    source_handle = LibC::HANDLE.new(ret)

    cur_proc = LibC.GetCurrentProcess
    if LibC.DuplicateHandle(cur_proc, source_handle, cur_proc, out new_handle, 0, true, LibC::DUPLICATE_SAME_ACCESS) == 0
      raise WinError.new("DuplicateHandle")
    end

    new_handle
  end

  def self.spawn(command : String, args : Enumerable(String)?,
                 env : ::Process::Env, clear_env : Bool,
                 input, output, error,
                 chdir : String?) : UInt32
    raise NotImplementedError.new("Process.new with env or clear_env options") if env || clear_env
    raise NotImplementedError.new("Process.new with chdir set") if chdir

    args = String.build { |io| args_to_string(command, args, io) }

    puts
    puts args

    command = to_windows_string(command)
    args = to_windows_string(args)

    startup_info = LibC::STARTUPINFOW.new
    startup_info.cb = sizeof(LibC::STARTUPINFOW)
    startup_info.dwFlags = LibC::STARTF_USESTDHANDLES

    startup_info.hStdInput = handle_from_io(input, STDIN)
    startup_info.hStdOutput = handle_from_io(output, STDOUT)
    startup_info.hStdError = handle_from_io(error, STDERR)

    process_info = LibC::PROCESS_INFORMATION.new

    if LibC.CreateProcessW(
         nil, args, nil, nil, true, 0, nil, nil,
         pointerof(startup_info), pointerof(process_info)
       ) == 0
      raise WinError.new("CreateProcess")
    end

    close_handle(process_info.hProcess)
    close_handle(process_info.hThread)

    close_handle(startup_info.hStdInput)
    close_handle(startup_info.hStdOutput)
    close_handle(startup_info.hStdError)

    process_info.dwProcessId
  end

  private def self.close_handle(handle) : Nil
    if LibC.CloseHandle(handle) == 0
      raise WinError.new("CloseHandle")
    end
  end

  def self.replace(command, argv, env, clear_env, input, output, error, chdir) : NoReturn
    raise NotImplementedError.new("Process.exec")
  end

  def self.wait(pid)
    handle = LibC.OpenProcess(LibC::SYNCHRONIZE | LibC::PROCESS_QUERY_LIMITED_INFORMATION, false, pid)
    raise WinError.new("OpenProcess") if handle == 0

    if LibC.WaitForSingleObject(handle, LibC::INFINITE) != 0
      raise WinError.new("WaitForSingleObject")
    end

    # WaitForSingleObject returns immediately once ExitProcess is called in the child, but
    # the process still has yet to be destructed by the OS and have it's memory unmapped.
    # Since the semantics on unix are that the resources of a process have been released once
    # waitpid returns, we wait 5 milliseconds to attempt to replicate this behaviour.
    sleep 5.milliseconds

    if LibC.GetExitCodeProcess(handle, out exit_code) != 0
      if exit_code == LibC::STILL_ACTIVE
        raise "BUG: process still active"
      else
        exit_code
      end
    else
      raise WinError.new("GetExitCodeProcess")
    end
  end

  def self.kill(pid, signal)
    raise NotImplementedError.new("Process.kill with signals other than Signal::KILL") unless signal == 9
    raise NotImplementedError.new("Process.kill")
  end

  private def self.to_windows_string(string : String) : LibC::LPWSTR
    string.check_no_null_byte.to_utf16.to_unsafe
  end
end
