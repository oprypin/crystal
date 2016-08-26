require "spec"
require "http/params"

module HTTP
  describe Params do
    describe ".parse" do
      {
        {"", {} of String => Array(String)},
        {"   ", {"   " => [""]}},
        {"foo=bar", {"foo" => ["bar"]}},
        {"foo=bar&foo=baz", {"foo" => ["bar", "baz"]}},
        {"foo=bar&baz=qux", {"foo" => ["bar"], "baz" => ["qux"]}},
        {"foo=bar;baz=qux", {"foo" => ["bar"], "baz" => ["qux"]}},
        {"foo=hello%2Bworld", {"foo" => ["hello+world"]}},
        {"foo=hello+world", {"foo" => ["hello world"]}},
        {"foo=", {"foo" => [""]}},
        {"foo", {"foo" => [""]}},
        {"foo=&bar", {"foo" => [""], "bar" => [""]}},
        {"bar&foo", {"bar" => [""], "foo" => [""]}},
      }.each do |(from, to)|
        it "parses #{from}" do
          assert Params.parse(from) == Params.new(to)
        end
      end
    end

    describe ".build" do
      {
        {"foo=bar", {"foo" => ["bar"]}},
        {"foo=bar&foo=baz", {"foo" => ["bar", "baz"]}},
        {"foo=bar&baz=qux", {"foo" => ["bar"], "baz" => ["qux"]}},
        {"foo=hello%2Bworld", {"foo" => ["hello+world"]}},
        {"foo=hello+world", {"foo" => ["hello world"]}},
        {"foo=", {"foo" => [""]}},
        {"foo=&bar=", {"foo" => [""], "bar" => [""]}},
        {"bar=&foo=", {"bar" => [""], "foo" => [""]}},
      }.each do |(to, from)|
        it "builds form from #{from}" do
          encoded = Params.build do |form|
            from.each do |key, values|
              values.each do |value|
                form.add(key, value)
              end
            end
          end

          assert encoded == to
        end
      end
    end

    describe "#to_s" do
      it "serializes params to http form" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.to_s == "foo=bar&foo=baz&baz=qux"
      end
    end

    describe "#[](name)" do
      it "returns first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params["foo"] == "bar"
        assert params["baz"] == "qux"
      end

      it "raises KeyError when there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        expect_raises KeyError do
          params["non_existent_param"]
        end
      end
    end

    describe "#[]?(name)" do
      it "returns first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params["foo"]? == "bar"
        assert params["baz"]? == "qux"
      end

      it "return nil when there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params["non_existent_param"]? == nil
      end
    end

    describe "#has_key?(name)" do
      it "returns true if param with provided name exists" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.has_key?("foo") == true
        assert params.has_key?("baz") == true
      end

      it "return false if param with provided name does not exist" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.has_key?("non_existent_param") == false
      end
    end

    describe "#[]=(name, value)" do
      it "sets first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        params["foo"] = "notfoo"
        assert params.fetch_all("foo") == ["notfoo", "baz"]
      end

      it "adds new name => value pair if there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        params["non_existent_param"] = "test"
        assert params.fetch_all("non_existent_param") == ["test"]
      end
    end

    describe "#fetch(name)" do
      it "returns first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.fetch("foo") == "bar"
        assert params.fetch("baz") == "qux"
      end

      it "raises KeyError when there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        expect_raises KeyError do
          params.fetch("non_existent_param")
        end
      end
    end

    describe "#fetch(name, default)" do
      it "returns first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.fetch("foo", "aDefault") == "bar"
        assert params.fetch("baz", "aDefault") == "qux"
      end

      it "return default value when there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.fetch("non_existent_param", "aDefault") == "aDefault"
      end
    end

    describe "#fetch(name, &block)" do
      it "returns first value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.fetch("foo") { "fromBlock" } == "bar"
        assert params.fetch("baz") { "fromBlock" } == "qux"
      end

      it "return default value when there is no such param" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")
        assert params.fetch("non_existent_param") { "fromBlock" } == "fromBlock"
      end
    end

    describe "#fetch_all(name)" do
      it "fetches list of all values for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux&iamempty")
        assert params.fetch_all("foo") == ["bar", "baz"]
        assert params.fetch_all("baz") == ["qux"]
        assert params.fetch_all("iamempty") == [""]
        assert params.fetch_all("non_existent_param") == [] of String
      end
    end

    describe "#add(name, value)" do
      it "appends new value for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux&iamempty")

        params.add("foo", "zeit")
        assert params.fetch_all("foo") == ["bar", "baz", "zeit"]

        params.add("baz", "exit")
        assert params.fetch_all("baz") == ["qux", "exit"]

        params.add("iamempty", "not_empty_anymore")
        assert params.fetch_all("iamempty") == ["not_empty_anymore"]

        params.add("non_existent_param", "something")
        assert params.fetch_all("non_existent_param") == ["something"]
      end
    end

    describe "#set_all(name, values)" do
      it "sets values for provided param name" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")

        params.set_all("baz", ["hello", "world"])
        assert params.fetch_all("baz") == ["hello", "world"]

        params.set_all("foo", ["something"])
        assert params.fetch_all("foo") == ["something"]

        params.set_all("non_existent_param", ["something", "else"])
        assert params.fetch_all("non_existent_param") == ["something", "else"]
      end
    end

    describe "#each" do
      it "calls provided proc for each name, value pair, including multiple values per one param name" do
        received = [] of {String, String}

        params = Params.parse("foo=bar&foo=baz&baz=qux")
        params.each do |name, value|
          received << {name, value}
        end

        assert received == [
          {"foo", "bar"},
          {"foo", "baz"},
          {"baz", "qux"},
        ]
      end
    end

    describe "#delete" do
      it "deletes first value for provided param name and returns it" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")

        assert params.delete("foo") == "bar"
        assert params.fetch_all("foo") == ["baz"]

        assert params.delete("baz") == "qux"
        expect_raises KeyError do
          params.fetch("baz")
        end
      end
    end

    describe "#delete_all" do
      it "deletes all values for provided param name and returns them" do
        params = Params.parse("foo=bar&foo=baz&baz=qux")

        assert params.delete_all("foo") == ["bar", "baz"]
        expect_raises KeyError do
          params.fetch("foo")
        end
      end
    end
  end
end
