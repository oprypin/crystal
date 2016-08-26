require "spec"
require "ecr/lexer"

describe "ECR::Lexer" do
  it "lexes without interpolation" do
    lexer = ECR::Lexer.new("hello")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello"
    assert token.line_number == 1
    assert token.column_number == 1

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <% %>" do
    lexer = ECR::Lexer.new("hello <% foo %> bar")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello "
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == " foo "
    assert token.line_number == 1
    assert token.column_number == 9
    assert token.supress_leading? == false
    assert token.supress_trailing? == false

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " bar"
    assert token.line_number == 1
    assert token.column_number == 16

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <%- %>" do
    lexer = ECR::Lexer.new("<%- foo %>")

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == " foo "
    assert token.line_number == 1
    assert token.column_number == 4
    assert token.supress_leading? == true
    assert token.supress_trailing? == false
  end

  it "lexes with <% -%>" do
    lexer = ECR::Lexer.new("<% foo -%>")

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == " foo "
    assert token.line_number == 1
    assert token.column_number == 3
    assert token.supress_leading? == false
    assert token.supress_trailing? == true
  end

  it "lexes with -% inside string" do
    lexer = ECR::Lexer.new("<% \"-%\" %>")

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == " \"-%\" "
  end

  it "lexes with <%= %>" do
    lexer = ECR::Lexer.new("hello <%= foo %> bar")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello "
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :OUTPUT
    assert token.value == " foo "
    assert token.line_number == 1
    assert token.column_number == 10
    assert token.supress_leading? == false
    assert token.supress_trailing? == false

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " bar"
    assert token.line_number == 1
    assert token.column_number == 17

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <%= -%>" do
    lexer = ECR::Lexer.new("<%= foo -%>")

    token = lexer.next_token
    assert token.type == :OUTPUT
    assert token.value == " foo "
    assert token.line_number == 1
    assert token.column_number == 4
    assert token.supress_leading? == false
    assert token.supress_trailing? == true
  end

  it "lexes with <%# %>" do
    lexer = ECR::Lexer.new("hello <%# foo %> bar")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello "
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == "# foo "
    assert token.line_number == 1
    assert token.column_number == 9
    assert token.supress_leading? == false
    assert token.supress_trailing? == false

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " bar"
    assert token.line_number == 1
    assert token.column_number == 17

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <%# -%>" do
    lexer = ECR::Lexer.new("<%# foo -%>")

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == "# foo "
    assert token.line_number == 1
    assert token.column_number == 3
    assert token.supress_leading? == false
    assert token.supress_trailing? == true
  end

  it "lexes with <%% %>" do
    lexer = ECR::Lexer.new("hello <%% foo %> bar")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello "
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "<% foo %>"
    assert token.line_number == 1
    assert token.column_number == 10
    assert token.supress_leading? == false
    assert token.supress_trailing? == false

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " bar"
    assert token.line_number == 1
    assert token.column_number == 17

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <%%= %>" do
    lexer = ECR::Lexer.new("hello <%%= foo %> bar")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hello "
    assert token.column_number == 1
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "<%= foo %>"
    assert token.line_number == 1
    assert token.column_number == 10
    assert token.supress_leading? == false
    assert token.supress_trailing? == false

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " bar"
    assert token.line_number == 1
    assert token.column_number == 18

    token = lexer.next_token
    assert token.type == :EOF
  end

  it "lexes with <% %> and correct location info" do
    lexer = ECR::Lexer.new("hi\nthere <% foo\nbar %> baz")

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == "hi\nthere "
    assert token.line_number == 1
    assert token.column_number == 1

    token = lexer.next_token
    assert token.type == :CONTROL
    assert token.value == " foo\nbar "
    assert token.line_number == 2
    assert token.column_number == 9

    token = lexer.next_token
    assert token.type == :STRING
    assert token.value == " baz"
    assert token.line_number == 3
    assert token.column_number == 7

    token = lexer.next_token
    assert token.type == :EOF
  end
end
