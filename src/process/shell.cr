class Process
  # Converts a sequence of strings to one joined string with each argument shell-quoted.
  #
  # This is then safe to pass to the current system's shell or as part of the command in `system()`.
  #
  # ```
  # files = ["my file.txt", "another.txt"]
  # `grep -E 'fo+' -- #{Process.shell_quote(files)}`
  # ```
  def self.shell_quote(args : Enumerable(String)) : String
    {% if flag?(:win32) %}
      shell_quote_windows(args)
    {% else %}
      shell_quote_posix(args)
    {% end %}
  end

  # Shell-quotes one item, same as `shell_quote({arg})`.
  def self.shell_quote(arg : String) : String
    shell_quote({arg})
  end

  # Converts a sequence of strings to one joined string with each argument shell-quoted.
  #
  # This is then safe to pass to a POSIX shell.
  #
  # ```
  # files = ["my file.txt", "another.txt"]
  # Process.shell_quote_posix(files) # => "'my file.txt' another.txt"
  # ```
  def self.shell_quote_posix(args : Enumerable(String)) : String
    args.join(' ') do |arg|
      if arg.empty?
        "''"
      elsif arg.matches? %r([^a-zA-Z0-9%+,\-./:=@_]) # not all characters are safe, needs quoting
        "'" + arg.gsub("'", %('"'"')) + "'"          # %(foo'ba#r) becomes %('foo'"'"'ba#r')
      else
        arg
      end
    end
  end

  # Shell-quotes one item, same as `shell_quote_posix({arg})`.
  def self.shell_quote_posix(arg : String) : String
    shell_quote_posix({arg})
  end

  # Converts a sequence of strings to one joined string with each argument shell-quoted.
  #
  # This is then safe to pass to the CMD shell or CreateProcess.
  #
  # ```
  # Process.shell_quote_windows({ %q(C:\"foo" project.txt) }) # => %q("C:\\\"foo\" project.txt")
  # ```
  def self.shell_quote_windows(args : Enumerable(String)) : String
    String.build { |io| shell_quote_windows(args, io) }
  end

  private def self.shell_quote_windows(args, io : IO)
    args.join(' ', io) do |arg|
      quotes = arg.empty? || arg.includes?(' ') || arg.includes?('\t')

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

  # Shell-quotes one item, same as `shell_quote_windows({arg})`.
  def self.shell_quote_windows(arg : String) : String
    shell_quote_windows({arg})
  end
end
