require "spec"
require "yaml"

describe "YAML" do
  describe "parser" do
    it { assert YAML.parse("foo") == "foo" }
    it { assert YAML.parse("- foo\n- bar") == ["foo", "bar"] }
    it { assert YAML.parse_all("---\nfoo\n---\nbar\n") == ["foo", "bar"] }
    it { assert YAML.parse("foo: bar") == {"foo" => "bar"} }
    it { assert YAML.parse("--- []\n") == [] of YAML::Type }
    it { assert YAML.parse("---\n...") == "" }

    it "parses recursive sequence" do
      doc = YAML.parse("--- &foo\n- *foo\n")
      assert doc[0].raw.same?(doc.raw)
    end

    it "parses recursive mapping" do
      doc = YAML.parse(%(--- &1
        friends:
        - *1
        ))
      assert doc["friends"][0].raw.same?(doc.raw)
    end

    it "parses alias to scalar" do
      doc = YAML.parse("---\n- &x foo\n- *x\n")
      assert doc == ["foo", "foo"]
      assert doc[0].raw.same?(doc[1].raw)
    end

    describe "merging with << key" do
      it "merges other mapping" do
        doc = YAML.parse(%(---
          foo: bar
          <<:
            baz: foobar
          ))
        assert doc["baz"]? == "foobar"
      end

      it "raises if merging with missing alias" do
        expect_raises do
          YAML.parse(%(---
            foo:
              <<: *bar
          ))
        end
      end

      it "doesn't merge explicit string key <<" do
        doc = YAML.parse(%(---
          foo: &foo
            hello: world
          bar:
            !!str '<<': *foo
        ))
        assert doc == {"foo" => {"hello" => "world"}, "bar" => {"<<" => {"hello" => "world"}}}
      end

      it "doesn't merge empty mapping" do
        doc = YAML.parse(%(---
          foo: &foo
          bar:
            <<: *foo
        ))
        assert doc["bar"] == {"<<" => ""}
      end

      it "doesn't merge arrays" do
        doc = YAML.parse(%(---
          foo: &foo
            - 1
          bar:
            <<: *foo
        ))
        assert doc["bar"] == {"<<" => ["1"]}
      end

      it "has correct line/number info (#2585)" do
        begin
          YAML.parse <<-YAML
            ---
            level_one:
            - name: "test"
               attributes:
                 one: "broken"
            YAML
          fail "expected YAML.parse to raise"
        rescue ex : YAML::ParseException
          assert ex.line_number == 3
          assert ex.column_number == 3
        end
      end

      it "has correct line/number info (2)" do
        begin
          parser = YAML::PullParser.new <<-MSG

              authors:
                - [foo] bar
            MSG

          parser.read_stream do
            parser.read_document do
              parser.read_scalar
            end
          end
        rescue ex : YAML::ParseException
          assert ex.line_number == 1
          assert ex.column_number == 2
        end
      end

      it "parses from IO" do
        assert YAML.parse(MemoryIO.new("- foo\n- bar")) == ["foo", "bar"]
      end
    end
  end

  describe "dump" do
    it "returns YAML as a string" do
      assert YAML.dump(%w(1 2 3)) == "--- \n- 1\n- 2\n- 3"
    end

    it "writes YAML to a stream" do
      string = String.build do |str|
        YAML.dump(%w(1 2 3), str)
      end
      assert string == "--- \n- 1\n- 2\n- 3"
    end
  end
end
