module LexerObjects
  class Strings
    @lexer : Lexer
    @token : Token

    def initialize(@lexer)
      @token = Token.new
    end

    def string_should_be_delimited_by(expected_start, expected_end)
      string_should_start_correctly
      assert token.delimiter_state.nest == expected_start
      assert token.delimiter_state.end == expected_end
      assert token.delimiter_state.open_count == 0
    end

    def string_should_start_correctly
      @token = lexer.next_token
      assert token.type == :DELIMITER_START
    end

    def next_token_should_be(expected_type, expected_value = nil)
      @token = lexer.next_token
      assert token.type == expected_type
      if expected_value
        assert token.value == expected_value
      end
    end

    def next_unicode_tokens_should_be(expected_unicode_codes : Array)
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :STRING
      assert token.value.as(String).chars.map(&.ord) == expected_unicode_codes
    end

    def next_unicode_tokens_should_be(expected_unicode_codes)
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :STRING
      assert token.value.as(String).char_at(0).ord == expected_unicode_codes
    end

    def next_string_token_should_be(expected_string)
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :STRING
      assert token.value == expected_string
    end

    def next_string_token_should_be_opening
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :STRING
      assert token.value == token.delimiter_state.nest.to_s
      assert token.delimiter_state.open_count == 1
    end

    def next_string_token_should_be_closing
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :STRING
      assert token.value == token.delimiter_state.end.to_s
      assert token.delimiter_state.open_count == 0
    end

    def string_should_have_an_interpolation_of(interpolated_variable_name)
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :INTERPOLATION_START

      @token = lexer.next_token
      assert token.type == :IDENT
      assert token.value == interpolated_variable_name

      @token = lexer.next_token
      assert token.type == :"}"
    end

    def token_should_be_at(line = nil, column = nil)
      assert token.line_number == line if line
      assert token.column_number == column if column
    end

    def next_token_should_be_at(line = nil, column = nil)
      @token = lexer.next_token
      token_should_be_at(line: line, column: column)
    end

    def string_should_end_correctly(eof = true)
      @token = lexer.next_string_token(token.delimiter_state)
      assert token.type == :DELIMITER_END
      if eof
        should_have_reached_eof
      end
    end

    def should_have_reached_eof
      @token = lexer.next_token
      assert token.type == :EOF
    end

    private getter :lexer, :token
  end
end
