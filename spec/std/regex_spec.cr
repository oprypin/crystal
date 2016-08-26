require "spec"

describe "Regex" do
  it "compare to other instances" do
    assert Regex.new("foo") == Regex.new("foo")
    assert Regex.new("foo") != Regex.new("bar")
  end

  it "does =~" do
    assert (/foo/ =~ "bar foo baz") == 4
    assert $~.size == 0
  end

  it "does inspect" do
    assert /foo/.inspect == "/foo/"
    assert /foo/.inspect == "/foo/"
    assert /foo/imx.inspect == "/foo/imx"
  end

  it "does to_s" do
    assert /foo/.to_s == "(?-imsx:foo)"
    assert /foo/im.to_s == "(?ims-x:foo)"
    assert /foo/imx.to_s == "(?imsx-:foo)"

    assert "Crystal".match(/(?<bar>C)#{/(?<foo>R)/i}/)
    assert !"Crystal".match(/(?<bar>C)#{/(?<foo>R)/}/i)

    md = "Crystal".match(/(?<bar>.)#{/(?<foo>.)/}/).not_nil!
    assert md[0] == "Cr"
    assert md["bar"] == "C"
    assert md["foo"] == "r"
  end

  it "doesn't crash when PCRE tries to free some memory (#771)" do
    expect_raises(ArgumentError) { Regex.new("foo)") }
  end

  it "escapes" do
    assert Regex.escape(" .\\+*?[^]$(){}=!<>|:-hello") == "\\ \\.\\\\\\+\\*\\?\\[\\^\\]\\$\\(\\)\\{\\}\\=\\!\\<\\>\\|\\:\\-hello"
  end

  it "matches ignore case" do
    assert ("HeLlO" =~ /hello/).nil?
    assert ("HeLlO" =~ /hello/i) == 0
  end

  it "matches lines beginnings on ^ in multiline mode" do
    assert ("foo\nbar" =~ /^bar/).nil?
    assert ("foo\nbar" =~ /^bar/m) == 4
  end

  it "matches multiline" do
    assert ("foo\n<bar\n>baz" =~ /<bar.*?>/).nil?
    assert ("foo\n<bar\n>baz" =~ /<bar.*?>/m) == 4
  end

  it "matches with =~ and captures" do
    assert ("fooba" =~ /f(o+)(bar?)/) == 0
    assert $~.size == 2
    assert $1 == "oo"
    assert $2 == "ba"
  end

  it "matches with =~ and gets utf-8 codepoint index" do
    index = "こんに" =~ /ん/
    assert index == 1
  end

  it "matches with === and captures" do
    "foo" =~ /foo/
    assert (/f(o+)(bar?)/ === "fooba") == true
    assert $~.size == 2
    assert $1 == "oo"
    assert $2 == "ba"
  end

  describe "name_table" do
    it "is a map of capture group number to name" do
      table = (/(?<date> (?<year>(\d\d)?\d\d) - (?<month>\d\d) - (?<day>\d\d) )/x).name_table
      assert table[1] == "date"
      assert table[2] == "year"
      assert table[3]?.nil?
      assert table[4] == "month"
      assert table[5] == "day"
    end
  end

  it "raises exception with invalid regex" do
    expect_raises(ArgumentError) { Regex.new("+") }
  end

  it "raises if outside match range with []" do
    "foo" =~ /foo/
    expect_raises(IndexError) { $1 }
  end

  describe ".union" do
    it "constructs a Regex that matches things any of its arguments match" do
      re = Regex.union(/skiing/i, "sledding")
      assert re.match("Skiing").not_nil![0] == "Skiing"
      assert re.match("sledding").not_nil![0] == "sledding"
    end

    it "returns a regular expression that will match passed arguments" do
      assert Regex.union("penzance") == /penzance/
      assert Regex.union("skiing", "sledding") == /skiing|sledding/
      assert Regex.union(/dogs/, /cats/i) == /(?-imsx:dogs)|(?i-msx:cats)/
    end

    it "quotes any string arguments" do
      assert Regex.union("n", ".") == /n|\./
    end

    it "returns a Regex with an Array(String) with special characters" do
      assert Regex.union(["+", "-"]) == /\+|\-/
    end

    it "accepts a single Array(String | Regex) argument" do
      assert Regex.union(["skiing", "sledding"]) == /skiing|sledding/
      assert Regex.union([/dogs/, /cats/i]) == /(?-imsx:dogs)|(?i-msx:cats)/
      assert (/dogs/ + /cats/i) == /(?-imsx:dogs)|(?i-msx:cats)/
    end

    it "accepts a single Tuple(String | Regex) argument" do
      assert Regex.union({"skiing", "sledding"}) == /skiing|sledding/
      assert Regex.union({/dogs/, /cats/i}) == /(?-imsx:dogs)|(?i-msx:cats)/
      assert (/dogs/ + /cats/i) == /(?-imsx:dogs)|(?i-msx:cats)/
    end

    it "combines Regex objects in the same way as Regex#+" do
      assert Regex.union(/skiing/i, /sledding/) == /skiing/i + /sledding/
    end
  end

  it "dups" do
    regex = /foo/
    assert regex.dup.same?(regex)
  end

  it "clones" do
    regex = /foo/
    assert regex.clone.same?(regex)
  end
end
