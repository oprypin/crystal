require "../../spec_helper"

describe "Lexer doc" do
  it "lexes without doc enabled" do
    lexer = Lexer.new(%(1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc.nil?
  end

  it "lexes with doc enabled but without docs" do
    lexer = Lexer.new(%(1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc.nil?
  end

  it "lexes with doc enabled and docs" do
    lexer = Lexer.new(%(# hello\n1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc == "hello"
  end

  it "lexes with doc enabled and docs, two line comment" do
    lexer = Lexer.new(%(# hello\n# world\n1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello\nworld"
  end

  it "lexes with doc enabled and docs, two line comment with leading whitespace" do
    lexer = Lexer.new(%(# hello\n    # world\n1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :SPACE
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello\nworld"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc == "hello\nworld"
  end

  it "lexes with doc enabled and docs, one line comment with two newlines and another comment" do
    lexer = Lexer.new(%(# hello\n\n    # world\n1))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc.nil?

    token = lexer.next_token
    assert token.type == :SPACE
    assert token.doc.nil?

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "world"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc == "world"
  end

  it "resets doc after non newline or space token" do
    lexer = Lexer.new(%(# hello\n1 2))
    lexer.doc_enabled = true

    token = lexer.next_token
    assert token.type == :NEWLINE
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc == "hello"

    token = lexer.next_token
    assert token.type == :SPACE
    assert token.doc.nil?

    token = lexer.next_token
    assert token.type == :NUMBER
    assert token.doc.nil?
  end
end
