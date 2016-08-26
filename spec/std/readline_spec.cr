require "spec"
require "readline"

describe Readline do
  typeof(Readline.readline)
  typeof(Readline.readline("Hello", true))
  typeof(Readline.readline(prompt: "Hello"))
  typeof(Readline.readline(add_history: false))
  typeof(Readline.line_buffer)
  typeof(Readline.point)
  typeof(Readline.autocomplete { |s| %w(foo bar) })

  it "gets prefix in bytesize between two strings" do
    assert Readline.common_prefix_bytesize("", "foo") == 0
    assert Readline.common_prefix_bytesize("foo", "") == 0
    assert Readline.common_prefix_bytesize("a", "a") == 1
    assert Readline.common_prefix_bytesize("open", "operate") == 3
    assert Readline.common_prefix_bytesize("operate", "open") == 3
    assert Readline.common_prefix_bytesize(["operate", "open", "optional"]) == 2
  end
end
