require "c/processthreadsapi"
require "c/winuser"
require "c/tlhelp32"

struct Crystal::System::Process
  getter pid : LibC::DWORD
  @thread_id : LibC::DWORD
  @process_handle : LibC::HANDLE

  def initialize(process_info)
    @pid = process_info.dwProcessId
    @thread_id = process_info.dwThreadId
    @process_handle = process_info.hProcess
  end

  def release
    close_handle(@process_handle)
  end

  def wait
    if LibC.WaitForSingleObject(@process_handle, LibC::INFINITE) != 0
      raise RuntimeError.from_winerror("WaitForSingleObject")
    end

    # WaitForSingleObject returns immediately once ExitProcess is called in the child, but
    # the process still has yet to be destructed by the OS and have it's memory unmapped.
    # Since the semantics on unix are that the resources of a process have been released once
    # waitpid returns, we wait 5 milliseconds to attempt to replicate this behaviour.
    sleep 5.milliseconds

    if LibC.GetExitCodeProcess(@process_handle, out exit_code) == 0
      raise RuntimeError.from_winerror("GetExitCodeProcess")
    end
    if exit_code == LibC::STILL_ACTIVE
      raise "BUG: process still active"
    end
    exit_code
  end

  def exists?
    Crystal::System::Process.exists?(@pid)
  end

  def terminate
    hwnd = find_main_window(@pid)
    if hwnd
      LibC.PostMessageW(hwnd, LibC::WM_CLOSE, 0, 0)
    else
      LibC.PostThreadMessageW(@thread_id, LibC::WM_QUIT, 0, 0)
    end
  end

  def self.exit(status)
    LibC.exit(status)
  end

  def self.pid
    LibC.GetCurrentProcessId
  end

  def self.pgid
    raise NotImplementedError.new("Process.pgid")
  end

  def self.pgid(pid)
    raise NotImplementedError.new("Process.pgid")
  end

  def self.ppid
    pid = LibC.GetCurrentProcessId
    snapshot = LibC.CreateToolhelp32Snapshot(LibC::TH32CS_SNAPPROCESS, 0)
    if snapshot == LibC::INVALID_HANDLE_VALUE
      raise RuntimeError.from_winerror("CreateToolhelp32Snapshot")
    end
    begin
      pe32 = LibC::PROCESSENTRY32.new
      pe32.dwSize = sizeof(LibC::PROCESSENTRY32)
      if LibC.Process32First(snapshot, pointerof(pe32)) == 0
        raise RuntimeError.from_winerror("Process32First")
      end

      loop do
        if pe32.th32ProcessID == pid
          return pe32.th32ParentProcessID
        end
        break if LibC.Process32Next(snapshot, pointerof(pe32)) == 0
      end
    ensure
      close_handle(snapshot)
    end
    raise RuntimeError.new("Could not determine parent PID")
  end

  def self.signal(pid, signal)
    raise NotImplementedError.new("Process.signal")
  end

  # TODO: Use this method
  def self.kill(pid)
    handle = LibC.OpenProcess(LibC::PROCESS_ALL_ACCESS, 0, pid)
    LibC.TerminateProcess(handle, -1)
    close_handle(handle)
  end

  struct FindMainWindowParam
    property process_id : LibC::DWORD = 0
    property window_handle : LibC::HANDLE = LibC::HANDLE.null
  end

  protected def find_main_window(process_id : LibC::DWORD) : LibC::HWND
    data = FindMainWindowParam.new
    data.process_id = process_id
    LibC.EnumWindows(->Process.enum_windows_callback(LibC::HWND, LibC::LPARAM), Box.box(data).address)
    data.window_handle
  end

  protected def self.enum_windows_callback(handle : LibC::HWND, lparam : LibC::LPARAM) : LibC::BOOL
    data = Box(FindMainWindowParam).unbox(Pointer(Void).new(lparam))
    process_id = LibC::DWORD.new(0)
    LibC.GetWindowThreadProcessId(handle, pointerof(process_id))
    if data.process_id != process_id || !is_main_window(handle)
      return 1
    else
      data.window_handle = handle
      return 0
    end
  end

  protected def self.is_main_window(handle : LibC::HWND) : Bool
    LibC.GetWindow(handle, LibC::GW_OWNER).address == 0 && LibC.IsWindowVisible(handle) == 1
  end

  def self.exists?(pid)
    handle = LibC.OpenProcess(LibC::PROCESS_QUERY_INFORMATION, 0, pid)
    return false if handle.nil?
    begin
      if LibC.GetExitCodeProcess(handle, out exit_code) == 0
        raise RuntimeError.from_winerror("GetExitCodeProcess")
      end
      exit_code == LibC::STILL_ACTIVE
    ensure
      close_handle(handle)
    end
  end

  def self.times
    raise NotImplementedError.new("Process.times")
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
    raise RuntimeError.from_winerror("_get_osfhandle") if ret == -1
    source_handle = LibC::HANDLE.new(ret)

    cur_proc = LibC.GetCurrentProcess
    if LibC.DuplicateHandle(cur_proc, source_handle, cur_proc, out new_handle, 0, true, LibC::DUPLICATE_SAME_ACCESS) == 0
      raise RuntimeError.from_winerror("DuplicateHandle")
    end

    new_handle
  end

  def self.spawn(command : String, args : Enumerable(String)?,
                 env : ::Process::Env, clear_env : Bool,
                 input, output, error,
                 chdir : String?)
    raise NotImplementedError.new("Process.new with env or clear_env options") if env || clear_env
    raise NotImplementedError.new("Process.new with chdir set") if chdir

    args = String.build { |io| args_to_string(command, args, io) }
    args = args.check_no_null_byte.to_utf16

    startup_info = LibC::STARTUPINFOW.new
    startup_info.cb = sizeof(LibC::STARTUPINFOW)
    startup_info.dwFlags = LibC::STARTF_USESTDHANDLES

    startup_info.hStdInput = handle_from_io(input, STDIN)
    startup_info.hStdOutput = handle_from_io(output, STDOUT)
    startup_info.hStdError = handle_from_io(error, STDERR)

    process_info = LibC::PROCESS_INFORMATION.new

    if LibC.CreateProcessW(
         nil, args, nil, nil, true, LibC::CREATE_UNICODE_ENVIRONMENT, create_env_block(env, clear_env), chdir.try &.check_no_null_byte.to_utf16,
         pointerof(startup_info), pointerof(process_info)
       ) == 0
      raise RuntimeError.from_winerror("Error executing process")
    end

    close_handle(process_info.hThread)

    close_handle(startup_info.hStdInput)
    close_handle(startup_info.hStdOutput)
    close_handle(startup_info.hStdError)

    process_info
  end

  def self.prepare_args(command, args, shell)
    if shell
      raise NotImplementedError.new("Process shell: true is not supported on Windows")
    end
    {command, args}
  end

  def self.replace(command, argv, env, clear_env, input, output, error, chdir) : NoReturn
    raise NotImplementedError.new("Process.exec")
  end

  # This function is used internally by `CreateProcess` to convert
  # the input to `lpEnvironment` to a string which the underlying C API
  # call will understand.
  #
  # An environment block consists of a null-terminated block of null-terminated strings. Each string is in the following form:
  # name=value\0
  #
  # Because the equal sign is used as a separator, it must not be used in the name of an environment variable.
  #
  # An environment block can contain Unicode characters because we includes CREATE_UNICODE_ENVIRONMENT flag in dwCreationFlags
  # A Unicode environment block is terminated by four zero bytes: two for the last string, two more to terminate the block.
  protected def self.create_env_block(env, clear_env : Bool)
    final_env = {} of String => String
    if LibC.CreateEnvironmentBlock(out pointer, nil, LibC::FALSE) == LibC::FALSE
      raise RuntimeError.from_winerror("CreateEnvironmentBlock")
    end
    env_block = pointer.as(Pointer(UInt16))
    begin
      Crystal::System::Env.parse_env_block(env_block) do |key, val|
        final_env[key] = val
      end
    ensure
      LibC.DestroyEnvironmentBlock(pointer)
    end
    if !clear_env
      ENV.each do |key, val|
        final_env[key] = val
      end
    end
    env.try &.each do |key, val|
      final_env[key] = val
    end
    builder = WinEnvBuilder.new
    final_env.each do |key, val|
      add_to_env_block(builder, key, val)
    end
    # terminate the block
    builder.write(0_u16)
    builder.buffer
  end

  private def self.add_to_env_block(block : WinEnvBuilder, key : String, val : String)
    # From Microsoft's documentation on `lpEnvironment`:
    # Because the equal sign is used as a separator, it must not be used
    # in the name of an environment variable.
    if !key.includes?('=') && !key.empty?
      block.write(key, val)
    end
  end

  private class WinEnvBuilder
    getter wchar_size : Int32
    getter capacity : Int32
    getter buffer : Pointer(UInt16)

    def initialize(capacity : Int = 1)
      @buffer = GC.malloc_atomic(capacity.to_u32*2).as(UInt16*)
      @capacity = capacity.to_i
      @wchar_size = 0
    end

    def slice
      Slice.new(buffer, wchar_size)
    end

    def bytes
      Slice.new(buffer.as(Pointer(UInt8)), wchar_size*2)
    end

    def write(key : String, val : String)
      key_val_pair = "#{key}=#{val}"
      write(key_val_pair.check_no_null_byte.to_utf16)
      write(0_u16)
    end

    private def write(slice : Slice(UInt16)) : Nil
      return if slice.empty?

      count = slice.size
      new_size = @wchar_size + count
      if new_size > @capacity
        resize_to_capacity(Math.pw2ceil(new_size))
      end

      slice.copy_to(@buffer + @wchar_size, count)
      @wchar_size += count

      nil
    end

    def write(wchar : UInt16)
      new_size = @wchar_size + 1
      if new_size > @capacity
        resize_to_capacity(Math.pw2ceil(new_size))
      end

      @buffer[@wchar_size] = wchar
      @wchar_size += 1

      nil
    end

    private def resize_to_capacity(capacity)
      @capacity = capacity
      @buffer = @buffer.realloc(@capacity*2)
    end
  end
end

private def close_handle(handle)
  if LibC.CloseHandle(handle) == 0
    raise RuntimeError.from_winerror("CloseHandle")
  end
end
