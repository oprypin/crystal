require "../../spec_helper"

private def assert_token_column_number(lexer, type, column_number)
  token = lexer.next_token
  assert token.type == type
  assert token.column_number == column_number
end

describe "Lexer: location" do
  it "stores line numbers" do
    lexer = Lexer.new "1\n2"
    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.line_number == 1

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 2
  end

  it "stores column numbers" do
    lexer = Lexer.new "1;  ident; def;\n4"
    assert_token_column_number lexer, :NUMBER, 1
    assert_token_column_number lexer, :";", 2
    assert_token_column_number lexer, :SPACE, 3
    assert_token_column_number lexer, :IDENT, 5
    assert_token_column_number lexer, :";", 10
    assert_token_column_number lexer, :SPACE, 11
    assert_token_column_number lexer, :IDENT, 12
    assert_token_column_number lexer, :";", 15
    assert_token_column_number lexer, :NEWLINE, 16
    assert_token_column_number lexer, :NUMBER, 1
  end

  it "overrides location with pragma" do
    lexer = Lexer.new %(1 + #<loc:"foo",12,34>2)
    lexer.filename = "bar"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 1
    assert token.column_number == 1
    assert token.filename == "bar"

    token = lexer.next_token
    assert token.type == :SPACE
    assert token.line_number == 1
    assert token.column_number == 2

    token = lexer.next_token
    assert token.type == :"+"
    assert token.line_number == 1
    assert token.column_number == 3

    token = lexer.next_token
    assert token.type == :SPACE
    assert token.line_number == 1
    assert token.column_number == 4

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 12
    assert token.column_number == 34
    assert token.filename == "foo"
  end

  it "uses two consecutive loc pragma " do
    lexer = Lexer.new %(1#<loc:"foo",12,34>#<loc:"foo",56,78>2)
    lexer.filename = "bar"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 1
    assert token.column_number == 1
    assert token.filename == "bar"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.line_number == 56
    assert token.column_number == 78
    assert token.filename == "foo"
  end

  it "assigns correct loc location to node" do
    exps = Parser.parse(%[(#<loc:"foo.txt",2,3>1 + 2)]).as(Expressions)
    node = exps.expressions.first
    location = node.location.not_nil!
    assert location.line_number == 2
    assert location.column_number == 3
    assert location.filename == "foo.txt"
  end

  it "parses var/call right after loc (#491)" do
    exps = Parser.parse(%[(#<loc:"foo.txt",2,3>msg)]).as(Expressions)
    exp = exps.expressions.first.as(Call)
    assert exp.name == "msg"
  end

  it "locations in different files have no order" do
    loc1 = Location.new("file1", 1, 1)
    loc2 = Location.new("file2", 2, 2)

    assert (loc1 < loc2) == false
    assert (loc1 <= loc2) == false

    assert (loc1 > loc2) == false
    assert (loc1 >= loc2) == false
  end

  it "locations in same files are comparable based on line" do
    loc1 = Location.new("file1", 1, 1)
    loc2 = Location.new("file1", 2, 1)
    loc3 = Location.new("file1", 1, 1)
    assert (loc1 < loc2) == true
    assert (loc1 <= loc2) == true
    assert (loc1 <= loc3) == true

    assert (loc2 > loc1) == true
    assert (loc2 >= loc1) == true
    assert (loc3 >= loc1) == true

    assert (loc2 < loc1) == false
    assert (loc2 <= loc1) == false

    assert (loc1 > loc2) == false
    assert (loc1 >= loc2) == false

    assert (loc3 == loc1) == true
  end

  it "locations with virtual files shoud be comparable" do
    loc1 = Location.new("file1", 1, 1)
    loc2 = Location.new(VirtualFile.new(Macro.new("macro", [] of Arg, Nop.new), "", Location.new("f", 1, 1)), 2, 1)
    assert (loc1 < loc2) == false
    assert (loc2 < loc1) == false
  end
end
