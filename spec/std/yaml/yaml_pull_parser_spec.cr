require "spec"
require "yaml"

private def assert_raw(string, expected = string, file = __FILE__, line = __LINE__)
  it "parses raw #{string.inspect}", file, line do
    pull = YAML::PullParser.new(string)
    pull.read_stream do
      pull.read_document do
        assert pull.read_raw == expected
      end
    end
  end
end

module YAML
  describe PullParser do
    it "reads empty stream" do
      parser = PullParser.new("")
      assert parser.kind == EventKind::STREAM_START
      assert parser.read_next == EventKind::STREAM_END
      assert parser.kind == EventKind::STREAM_END
    end

    it "reads an empty document" do
      parser = PullParser.new("---\n...\n")
      parser.read_stream do
        parser.read_document do
          assert parser.read_scalar == ""
        end
      end
    end

    it "reads a scalar" do
      parser = PullParser.new("--- foo\n...\n")
      parser.read_stream do
        parser.read_document do
          assert parser.read_scalar == "foo"
        end
      end
    end

    it "reads a sequence" do
      parser = PullParser.new("---\n- 1\n- 2\n- 3\n")
      parser.read_stream do
        parser.read_document do
          parser.read_sequence do
            assert parser.read_scalar == "1"
            assert parser.read_scalar == "2"
            assert parser.read_scalar == "3"
          end
        end
      end
    end

    it "reads a scalar with an anchor" do
      parser = PullParser.new("--- &foo bar\n...\n")
      parser.read_stream do
        parser.read_document do
          assert parser.anchor == "foo"
          assert parser.read_scalar == "bar"
        end
      end
    end

    it "reads a sequence with an anchor" do
      parser = PullParser.new("--- &foo []\n")
      parser.read_stream do
        parser.read_document do
          assert parser.anchor == "foo"
          parser.read_sequence do
          end
        end
      end
    end

    it "reads a mapping" do
      parser = PullParser.new(%(---\nfoo: 1\nbar: 2\n))
      parser.read_stream do
        parser.read_document do
          parser.read_mapping do
            assert parser.read_scalar == "foo"
            assert parser.read_scalar == "1"
            assert parser.read_scalar == "bar"
            assert parser.read_scalar == "2"
          end
        end
      end
    end

    it "reads a mapping with an anchor" do
      parser = PullParser.new(%(---\n&lala {}\n))
      parser.read_stream do
        parser.read_document do
          assert parser.anchor == "lala"
          parser.read_mapping do
          end
        end
      end
    end

    it "parses alias" do
      parser = PullParser.new("--- *foo\n")
      parser.read_stream do
        parser.read_document do
          assert parser.read_alias == "foo"
        end
      end
    end

    assert_raw %(hello)
    assert_raw %("hello"), %(hello)
    assert_raw %(["hello"])
    assert_raw %(["hello","world"])
    assert_raw %({"hello":"world"})
  end
end
