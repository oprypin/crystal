require "crsfml"
require "imgui"
require "imgui-sfml"

class Crystal::Repl
  property prelude : String = "prelude"
  getter program : Program
  getter context : Context

  def initialize
    @program = Program.new
    @context = Context.new(@program)
    @nest = 0
    @incomplete = false
    @line_number = 1
    @main_visitor = MainVisitor.new(@program)

    @interpreter = Interpreter.new(@context)

    @buffer = ImGui::TextBuffer.new
  end

  def run
    load_prelude

    Colorize.enabled = false

    window = SF::RenderWindow.new(SF::VideoMode.new(1280, 720), "crystal i")
    window.framerate_limit = 30

    ImGui::SFML.init(window)
    io = ImGui.get_io
    io.ini_filename = nil

    delta_clock = SF::Clock.new
    output = Array({ImGui::ImVec4, String}).new
    scroll_to_bottom = false

    while window.open?
      while (event = window.poll_event)
        ImGui::SFML.process_event(window, event)

        if event.is_a? SF::Event::Closed
          window.close
        end
      end

      ImGui::SFML.update(window, delta_clock.restart)

      viewport = ImGui.get_main_viewport

      ImGui.set_next_window_pos(ImGui::ImVec2.new(viewport.work_size.x / 2, 0), ImGui::ImGuiCond::Once)
      ImGui.set_next_window_size(ImGui::ImVec2.new(viewport.work_size.x / 2, viewport.work_size.y), ImGui::ImGuiCond::Once)

      ImGui.begin("State")

      @interpreter.draw_state

      ImGui.end

      ImGui.set_next_window_pos(ImGui::ImVec2.new(0, 0), ImGui::ImGuiCond::Once)
      ImGui.set_next_window_size(ImGui::ImVec2.new(viewport.work_size.x / 2, viewport.work_size.y), ImGui::ImGuiCond::Once)

      ImGui.begin("Console")

      footer_height_to_reserve = ImGui.get_style.item_spacing.y + ImGui.get_frame_height_with_spacing
      ImGui.begin_child("ScrollingRegion", ImGui::ImVec2.new(0, -footer_height_to_reserve), false, ImGui::ImGuiWindowFlags::HorizontalScrollbar)

      ImGui.push_text_wrap_pos(0.0)
      output.each do |(color, str)|
        ImGui.push_style_color(ImGui::ImGuiCol::Text, color)
        ImGui.text_unformatted(str)
        ImGui.pop_style_color
      end
      ImGui.pop_text_wrap_pos

      if scroll_to_bottom
        ImGui.set_scroll_here_y(1)
        scroll_to_bottom = false
      end

      ImGui.end_child

      ImGui.separator

      prompt = String.build do |io|
        io.print "icr:#{@line_number}:#{@nest}"
        io.print(@incomplete ? '*' : '>')
        io.print ' '
        io.print "  " * @nest if @nest > 0
      end

      ImGui.text_unformatted(prompt)
      ImGui.same_line
      flags = ImGui::ImGuiInputTextFlags::EnterReturnsTrue | ImGui::ImGuiInputTextFlags::CallbackResize | ImGui::ImGuiInputTextFlags::CtrlEnterForNewLine
      got_command = ImGui.input_text("##input", @buffer, flags)

      ImGui.set_item_default_focus

      if got_command
        scroll_to_bottom = true

        run_command(prompt, output)
        ImGui.set_keyboard_focus_here(-1)
      end

      ImGui.end

      window.clear
      ImGui::SFML.render(window)
      window.display
    end

    interpret_exit
    ImGui::SFML.shutdown
  end

  private def run_command(prompt, output)
    begin
      new_buffer = @buffer.to_s

      if new_buffer.blank?
        @line_number += 1
        return
      end

      parser = Parser.new(
        new_buffer,
        string_pool: @program.string_pool,
        var_scopes: [@interpreter.local_vars.names_at_block_level_zero.to_set]
      )

      begin
        node = parser.parse
      rescue ex : Crystal::SyntaxException
        # TODO: improve this
        if ex.message.in?("unexpected token: EOF", "expecting identifier 'end', not 'EOF'")
          @nest = parser.type_nest + parser.def_nest + parser.fun_nest
          @buffer.puts
          @line_number += 1
          @incomplete = @nest == 0
        elsif ex.message == "expecting token ']', not 'EOF'"
          @nest = parser.type_nest + parser.def_nest + parser.fun_nest
          @buffer.puts
          @line_number += 1
          @incomplete = true
        else
          output << {ImGui.rgb(1.0, 0.4, 0.4), "Error: #{ex.message}"}
          @nest = 0
          @buffer.clear
          @incomplete = false
        end
        output << {ImGui.rgb(1, 1, 1), "#{prompt}#{new_buffer}"} unless @incomplete
        return
      else
        @nest = 0
        @buffer.clear
        @line_number += 1
      end

      output << {ImGui.rgb(1, 1, 1), "#{prompt}#{new_buffer}"}

      begin
        value = interpret(node)

        output << {ImGui.rgb(0.8, 1.0, 1.0), "=> #{value}"}
      rescue ex : EscapingException
        @nest = 0
        @buffer.clear
        @line_number += 1

        output << {ImGui.rgb(1.0, 0.4, 0.4), "Unhandled exception: #{ex}"}
      rescue ex : Crystal::CodeError
        @nest = 0
        @buffer.clear
        @line_number += 1

        ex.color = true
        ex.error_trace = true
        output << {ImGui.rgb(1.0, 0.4, 0.4), ex.to_s}
      rescue ex : Exception
        @nest = 0
        @buffer.clear
        @line_number += 1

        output << {ImGui.rgb(1.0, 0.4, 0.4), ex.inspect_with_backtrace}
      end
    end
  end

  def run_file(filename, argv)
    @interpreter.argv = argv

    prelude_node = parse_prelude
    other_node = parse_file(filename)
    file_node = FileNode.new(other_node, filename)
    exps = Expressions.new([prelude_node, file_node] of ASTNode)

    interpret_and_exit_on_error(exps)

    # Explicitly call exit at the end so at_exit handlers run
    interpret_exit
  end

  def run_code(code, argv = [] of String)
    @interpreter.argv = argv

    prelude_node = parse_prelude
    other_node = parse_code(code)
    exps = Expressions.new([prelude_node, other_node] of ASTNode)

    interpret(exps)
  end

  private def load_prelude
    node = parse_prelude

    interpret_and_exit_on_error(node)
  end

  private def interpret(node : ASTNode)
    node = @program.normalize(node)
    node = @program.semantic(node, main_visitor: @main_visitor)
    @interpreter.interpret(node, @main_visitor.meta_vars)
  end

  private def interpret_and_exit_on_error(node : ASTNode)
    interpret(node)
  rescue ex : EscapingException
    # First run at_exit handlers by calling Crystal.exit
    interpret_crystal_exit(ex)
    exit 1
  rescue ex : Crystal::CodeError
    ex.color = true
    ex.error_trace = true
    puts ex
    exit 1
  rescue ex : Exception
    ex.inspect_with_backtrace(STDOUT)
    exit 1
  end

  private def parse_prelude
    filenames = @program.find_in_path(prelude)
    parsed_nodes = filenames.map { |filename| parse_file(filename) }
    Expressions.new(parsed_nodes)
  end

  private def parse_file(filename)
    parse_code File.read(filename), filename
  end

  private def parse_code(code, filename = "")
    parser = Parser.new code, @program.string_pool
    parser.filename = filename
    parsed_nodes = parser.parse
    @program.normalize(parsed_nodes, inside_exp: false)
  end

  private def interpret_exit
    interpret(Call.new(nil, "exit", global: true))
  end

  private def interpret_crystal_exit(exception : EscapingException)
    decl = UninitializedVar.new(Var.new("ex"), TypeNode.new(@context.program.exception.virtual_type))
    call = Call.new(Path.global("Crystal"), "exit", [NumberLiteral.new(1), Var.new("ex")] of ASTNode)
    exps = Expressions.new([decl, call] of ASTNode)

    begin
      Interpreter.interpret(@context, exps) do |stack|
        stack.as(UInt8**).value = exception.exception_pointer
      end
    rescue ex
      puts "Error while calling Crystal.exit: #{ex.message}"
    end
  end
end
