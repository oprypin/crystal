require "spec"
require "colorize"

describe "colorize" do
  it "colorizes without change" do
    assert "hello".colorize.to_s == "hello"
  end

  it "colorizes foreground" do
    assert "hello".colorize.black.to_s == "\e[30mhello\e[0m"
    assert "hello".colorize.red.to_s == "\e[31mhello\e[0m"
    assert "hello".colorize.green.to_s == "\e[32mhello\e[0m"
    assert "hello".colorize.yellow.to_s == "\e[33mhello\e[0m"
    assert "hello".colorize.blue.to_s == "\e[34mhello\e[0m"
    assert "hello".colorize.magenta.to_s == "\e[35mhello\e[0m"
    assert "hello".colorize.cyan.to_s == "\e[36mhello\e[0m"
    assert "hello".colorize.light_gray.to_s == "\e[37mhello\e[0m"
    assert "hello".colorize.dark_gray.to_s == "\e[90mhello\e[0m"
    assert "hello".colorize.light_red.to_s == "\e[91mhello\e[0m"
    assert "hello".colorize.light_green.to_s == "\e[92mhello\e[0m"
    assert "hello".colorize.light_yellow.to_s == "\e[93mhello\e[0m"
    assert "hello".colorize.light_blue.to_s == "\e[94mhello\e[0m"
    assert "hello".colorize.light_magenta.to_s == "\e[95mhello\e[0m"
    assert "hello".colorize.light_cyan.to_s == "\e[96mhello\e[0m"
    assert "hello".colorize.white.to_s == "\e[97mhello\e[0m"
  end

  it "colorizes background" do
    assert "hello".colorize.on_black.to_s == "\e[40mhello\e[0m"
    assert "hello".colorize.on_red.to_s == "\e[41mhello\e[0m"
    assert "hello".colorize.on_green.to_s == "\e[42mhello\e[0m"
    assert "hello".colorize.on_yellow.to_s == "\e[43mhello\e[0m"
    assert "hello".colorize.on_blue.to_s == "\e[44mhello\e[0m"
    assert "hello".colorize.on_magenta.to_s == "\e[45mhello\e[0m"
    assert "hello".colorize.on_cyan.to_s == "\e[46mhello\e[0m"
    assert "hello".colorize.on_light_gray.to_s == "\e[47mhello\e[0m"
    assert "hello".colorize.on_dark_gray.to_s == "\e[100mhello\e[0m"
    assert "hello".colorize.on_light_red.to_s == "\e[101mhello\e[0m"
    assert "hello".colorize.on_light_green.to_s == "\e[102mhello\e[0m"
    assert "hello".colorize.on_light_yellow.to_s == "\e[103mhello\e[0m"
    assert "hello".colorize.on_light_blue.to_s == "\e[104mhello\e[0m"
    assert "hello".colorize.on_light_magenta.to_s == "\e[105mhello\e[0m"
    assert "hello".colorize.on_light_cyan.to_s == "\e[106mhello\e[0m"
    assert "hello".colorize.on_white.to_s == "\e[107mhello\e[0m"
  end

  it "colorizes mode" do
    assert "hello".colorize.bold.to_s == "\e[1mhello\e[0m"
    assert "hello".colorize.bright.to_s == "\e[1mhello\e[0m"
    assert "hello".colorize.dim.to_s == "\e[2mhello\e[0m"
    assert "hello".colorize.underline.to_s == "\e[4mhello\e[0m"
    assert "hello".colorize.blink.to_s == "\e[5mhello\e[0m"
    assert "hello".colorize.reverse.to_s == "\e[7mhello\e[0m"
    assert "hello".colorize.hidden.to_s == "\e[8mhello\e[0m"
  end

  it "colorizes mode combination" do
    assert "hello".colorize.bold.dim.underline.blink.reverse.hidden.to_s == "\e[1;2;4;5;7;8mhello\e[0m"
  end

  it "colorizes foreground with background" do
    assert "hello".colorize.blue.on_green.to_s == "\e[34;42mhello\e[0m"
  end

  it "colorizes foreground with background with mode" do
    assert "hello".colorize.blue.on_green.bold.to_s == "\e[34;42;1mhello\e[0m"
  end

  it "colorizes foreground with symbol" do
    assert "hello".colorize(:red).to_s == "\e[31mhello\e[0m"
    assert "hello".colorize.fore(:red).to_s == "\e[31mhello\e[0m"
  end

  it "colorizes mode with symbol" do
    assert "hello".colorize.mode(:bold).to_s == "\e[1mhello\e[0m"
  end

  it "raises on unknown foreground color" do
    expect_raises ArgumentError, "unknown color: brown" do
      "hello".colorize(:brown)
    end
  end

  it "raises on unknown background color" do
    expect_raises ArgumentError, "unknown color: brown" do
      "hello".colorize.back(:brown)
    end
  end

  it "raises on unknown mode" do
    expect_raises ArgumentError, "unknown mode: bad" do
      "hello".colorize.mode(:bad)
    end
  end

  it "inspects" do
    assert "hello".colorize(:red).inspect == "\e[31m\"hello\"\e[0m"
  end

  it "colorizes io with method" do
    io = MemoryIO.new
    with_color.red.surround(io) do
      io << "hello"
    end
    assert io.to_s == "\e[31mhello\e[0m"
  end

  it "colorizes io with symbol" do
    io = MemoryIO.new
    with_color(:red).surround(io) do
      io << "hello"
    end
    assert io.to_s == "\e[31mhello\e[0m"
  end

  it "colorizes with push and pop" do
    io = MemoryIO.new
    with_color.red.push(io) do
      io << "hello"
      with_color.green.push(io) do
        io << "world"
      end
      io << "bye"
    end
    assert io.to_s == "\e[31mhello\e[0;32mworld\e[0;31mbye\e[0m"
  end

  it "colorizes with push and pop resets" do
    io = MemoryIO.new
    with_color.red.push(io) do
      io << "hello"
      with_color.green.bold.push(io) do
        io << "world"
      end
      io << "bye"
    end
    assert io.to_s == "\e[31mhello\e[0;32;1mworld\e[0;31mbye\e[0m"
  end

  it "toggles off" do
    assert "hello".colorize.black.toggle(false).to_s == "hello"
    assert "hello".colorize.toggle(false).black.to_s == "hello"
  end

  it "toggles off and on" do
    assert "hello".colorize.toggle(false).black.toggle(true).to_s == "\e[30mhello\e[0m"
  end
end
