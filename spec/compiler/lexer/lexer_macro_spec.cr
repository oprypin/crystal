require "../../spec_helper"

describe "Lexer macro" do
  it "lexes simple macro" do
    lexer = Lexer.new(%(hello end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "hello "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with expression" do
    lexer = Lexer.new(%(hello {{world}} end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "hello "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token_before_expression = token.dup

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "world"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(token_before_expression.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  ["begin", "do", "if", "unless", "class", "struct", "module", "def", "while", "until", "case", "macro", "fun", "lib", "union", "ifdef", "macro def"].each do |keyword|
    it "lexes macro with nested #{keyword}" do
      lexer = Lexer.new(%(hello\n  #{keyword} {{world}} end end))

      token = lexer.next_macro_token(Token::MacroState.default, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "hello\n  #{keyword} "
      assert token.macro_state.nest == 1

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_EXPRESSION_START

      token_before_expression = token.dup

      token = lexer.next_token
      assert token.type == :IDENT
      assert token.value == "world"

      assert lexer.next_token.type == :"}"
      assert lexer.next_token.type == :"}"

      token = lexer.next_macro_token(token_before_expression.macro_state, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == " "

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "end "

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_END
    end
  end

  it "lexes macro with nested enum" do
    lexer = Lexer.new(%(hello enum {{world}} end end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "hello "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "enum "
    assert token.macro_state.nest == 1

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token_before_expression = token.dup

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "world"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(token_before_expression.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "end "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro without nested if" do
    lexer = Lexer.new(%(helloif {{world}} end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "helloif "
    assert token.macro_state.nest == 0

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token_before_expression = token.dup

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "world"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(token_before_expression.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with nested abstract def" do
    lexer = Lexer.new(%(hello\n  abstract def {{world}} end end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "hello\n  abstract def "
    assert token.macro_state.nest == 0

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token_before_expression = token.dup

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "world"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(token_before_expression.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  {"class", "struct"}.each do |keyword|
    it "lexes macro with nested abstract #{keyword}" do
      lexer = Lexer.new(%(hello\n  abstract #{keyword} Foo; end; end))

      token = lexer.next_macro_token(Token::MacroState.default, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "hello\n  abstract #{keyword} Foo; "
      assert token.macro_state.nest == 1

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "end; "

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_END
    end
  end

  it "reaches end" do
    lexer = Lexer.new(%(fail))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "fail"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :EOF
  end

  it "keeps correct column and line numbers" do
    lexer = Lexer.new("\nfoo\nbarf{{var}}\nend")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "\nfoo\nbarf"
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "var"
    assert token.line_number == 3
    assert token.column_number == 7

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "\n"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with control" do
    lexer = Lexer.new("foo{% if ")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "foo"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_CONTROL_START
  end

  it "skips whitespace" do
    lexer = Lexer.new("   \n    coco")

    token = lexer.next_macro_token(Token::MacroState.default, true)
    assert token.type == :MACRO_LITERAL
    assert token.value == "coco"
  end

  it "lexes macro with embedded string" do
    lexer = Lexer.new(%(good " end " day end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %(good " end " day )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with embedded string and backslash" do
    lexer = Lexer.new("good \" end \\\" \" day end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "good \" end \\\" \" day "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with embedded string and expression" do
    lexer = Lexer.new(%(good " end {{foo}} " day end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %(good " end )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    macro_state = token.macro_state

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "foo"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %( " day )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  [{"(", ")"}, {"[", "]"}, {"<", ">"}].each do |(left, right)|
    it "lexes macro with embedded string with %#{left}" do
      lexer = Lexer.new("good %#{left} end #{right} day end")

      token = lexer.next_macro_token(Token::MacroState.default, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "good %#{left} end #{right} day "

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_END
    end

    it "lexes macro with embedded string with %#{left} ignores begin" do
      lexer = Lexer.new("good %#{left} begin #{right} day end")

      token = lexer.next_macro_token(Token::MacroState.default, false)
      assert token.type == :MACRO_LITERAL
      assert token.value == "good %#{left} begin #{right} day "

      token = lexer.next_macro_token(token.macro_state, false)
      assert token.type == :MACRO_END
    end
  end

  it "lexes macro with nested embedded string with %(" do
    lexer = Lexer.new("good %( ( ) end ) day end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "good %( ( ) end ) day "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with comments" do
    lexer = Lexer.new("good # end\n day end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "good "
    assert token.line_number == 1

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "# end\n"
    assert token.line_number == 2

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " day "
    assert token.line_number == 2

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
    assert token.line_number == 2
  end

  it "lexes macro with comments and expressions" do
    lexer = Lexer.new("good # {{name}} end\n day end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "good "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "# "
    assert token.macro_state.comment == true

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token_before_expression = token.dup
    assert token_before_expression.macro_state.comment == true

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "name"

    assert lexer.next_token.type == :"}"
    assert lexer.next_token.type == :"}"

    token = lexer.next_macro_token(token_before_expression.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " end\n"
    assert token.macro_state.comment == false

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == " day "
    assert token.line_number == 2

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
    assert token.line_number == 2
  end

  it "lexes macro with curly escape" do
    lexer = Lexer.new("good \\{{world}}\nend")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "good "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "{"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "{world}}\n"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with if as suffix" do
    lexer = Lexer.new("foo if bar end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "foo if bar "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with if as suffix after return" do
    lexer = Lexer.new("return if @end end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "return if @end "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with semicolon before end" do
    lexer = Lexer.new(";end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == ";"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with if after assign" do
    lexer = Lexer.new("x = if 1; 2; else; 3; end; end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "x = if 1; 2; "
    assert token.macro_state.nest == 1

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "else; 3; "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "end; "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro var" do
    lexer = Lexer.new("x = if %var; 2; else; 3; end; end")

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "x = if "
    assert token.macro_state.nest == 1

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_VAR
    assert token.value == "var"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "; 2; "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "else; 3; "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "end; "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "doesn't lex macro var if escaped" do
    lexer = Lexer.new(%(" \\%var " end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %(" )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "%"

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %(var " )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes macro with embedded char and sharp" do
    lexer = Lexer.new(%(good '#' day end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %(good '#' day )

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_END
  end

  it "lexes bug #654" do
    lexer = Lexer.new(%(l {{op}} end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "l "

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START

    token = lexer.next_token
    assert token.type == :IDENT
    assert token.value == "op"
  end

  it "lexes escaped quote inside string (#895)" do
    lexer = Lexer.new(%("\\"" end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %("\\"" )
  end

  it "lexes with if/end inside escaped macro (#1029)" do
    lexer = Lexer.new(%(\\{%    if true %} 2 \\{% end %} end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "{%    if"
    assert token.macro_state.beginning_of_line == false
    assert token.macro_state.nest == 1

    token = lexer.next_macro_token(token.macro_state, token.macro_state.beginning_of_line)
    assert token.type == :MACRO_LITERAL
    assert token.value == " true %} 2 "
    assert token.macro_state.beginning_of_line == false
    assert token.macro_state.nest == 1

    token = lexer.next_macro_token(token.macro_state, token.macro_state.beginning_of_line)
    assert token.type == :MACRO_LITERAL
    assert token.value == "{% end"
    assert token.macro_state.beginning_of_line == false
    assert token.macro_state.nest == 0
  end

  it "lexes with for inside escaped macro (#1029)" do
    lexer = Lexer.new(%(\\{%    for true %} 2 \\{% end %} end))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "{%    for"
    assert token.macro_state.beginning_of_line == false
    assert token.macro_state.nest == 1
  end

  it "lexes begin end" do
    lexer = Lexer.new(%(begin\nend end))
    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == "begin\n"

    token = lexer.next_macro_token(token.macro_state, token.macro_state.beginning_of_line)
    assert token.type == :MACRO_LITERAL
    assert token.value == "end "
    assert token.line_number == 2
  end

  it "lexes macro with string interpolation and double curly brace" do
    lexer = Lexer.new(%("\#{{{1}}}"))

    token = lexer.next_macro_token(Token::MacroState.default, false)
    assert token.type == :MACRO_LITERAL
    assert token.value == %("\#{)

    token = lexer.next_macro_token(token.macro_state, false)
    assert token.type == :MACRO_EXPRESSION_START
  end
end
