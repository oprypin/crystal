# The status of a terminated process. Returned by `Process#wait`
class Process::Status
  {% if flag?(:win32) %}
    # :nodoc:
    def initialize(@exit_status : UInt32)
    end
  {% else %}
    # :nodoc:
    def initialize(@exit_status : Int32)
    end
  {% end %}

  # Returns `true` if the process was terminated by a signal.
  def signal_exit? : Bool
    {% if flag?(:win32) %}
      false
    {% else %}
      # define __WIFSIGNALED(status) (((signed char) (((status) & 0x7f) + 1) >> 1) > 0)
      ((LibC::SChar.new(@exit_status & 0x7f) + 1) >> 1) > 0
    {% end %}
  end

  # Returns `true` if the process terminated normally.
  def normal_exit? : Bool
    {% if flag?(:win32) %}
      true
    {% else %}
      # define __WIFEXITED(status) (__WTERMSIG(status) == 0)
      signal_code == 0
    {% end %}
  end

  # If `signal_exit?` is `true`, returns the *Signal* the process
  # received and didn't handle. Will raise if `signal_exit?` is `false`.
  def exit_signal : Signal
    {% if flag?(:win32) %}
      raise NotImplementedError.new("Process::Status#exit_signal")
    {% else %}
      Signal.from_value(signal_code)
    {% end %}
  end

  # If `normal_exit?` is `true`, returns the exit code of the process.
  def exit_code : Int32
    {% if flag?(:win32) %}
      @exit_status.to_i32
    {% else %}
      # define __WEXITSTATUS(status) (((status) & 0xff00) >> 8)
      (@exit_status & 0xff00) >> 8
    {% end %}
  end

  # Returns `true` if the process exited normally with an exit code of `0`.
  def success? : Bool
    normal_exit? && exit_code == 0
  end

  private def signal_code
    # define __WTERMSIG(status) ((status) & 0x7f)
    @exit_status & 0x7f
  end
end
