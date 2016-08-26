require "spec"

describe "Regex::MatchData" do
  it "does inspect" do
    assert /f(o)(x)/.match("the fox").inspect == %(#<Regex::MatchData "fox" 1:"o" 2:"x">)
    assert /f(o)(x)?/.match("the fort").inspect == %(#<Regex::MatchData "fo" 1:"o" 2:nil>)
    assert /fox/.match("the fox").inspect == %(#<Regex::MatchData "fox">)
  end

  it "does to_s" do
    assert /f(o)(x)/.match("the fox").to_s == %(#<Regex::MatchData "fox" 1:"o" 2:"x">)
    assert /f(?<lettero>o)(?<letterx>x)/.match("the fox").to_s == %(#<Regex::MatchData "fox" lettero:"o" letterx:"x">)
    assert /fox/.match("the fox").to_s == %(#<Regex::MatchData "fox">)
  end

  describe "#[]" do
    it "captures empty group" do
      assert ("foo" =~ /(?<g1>z?)foo/) == 0
      assert $~[1] == ""
      assert $~["g1"] == ""
    end

    it "capture named group" do
      assert ("fooba" =~ /f(?<g1>o+)(?<g2>bar?)/) == 0
      assert $~["g1"] == "oo"
      assert $~["g2"] == "ba"
    end

    it "raises exception on optional empty group" do
      assert ("foo" =~ /(?<g1>z)?foo/) == 0
      expect_raises(Exception) { $~[1] }
      expect_raises(Exception) { $~["g1"] }
    end

    it "raises exception when named group doesn't exist" do
      assert ("foo" =~ /foo/) == 0
      expect_raises(ArgumentError) { $~["group"] }
    end

    it "raises if outside match range with []" do
      "foo" =~ /foo/
      expect_raises(IndexError) { $~[1] }
    end
  end

  describe "#[]?" do
    it "capture empty group" do
      assert ("foo" =~ /(?<g1>z?)foo/) == 0
      assert $~[1]? == ""
      assert $~["g1"]? == ""
    end

    it "capture optional empty group" do
      assert ("foo" =~ /(?<g1>z)?foo/) == 0
      assert $~[1]?.nil?
      assert $~["g1"]?.nil?
    end

    it "capture named group" do
      assert ("fooba" =~ /f(?<g1>o+)(?<g2>bar?)/) == 0
      assert $~["g1"]? == "oo"
      assert $~["g2"]? == "ba"
    end

    it "returns nil exception when named group doesn't exist" do
      assert ("foo" =~ /foo/) == 0
      assert $~["group"]?.nil?
    end

    it "returns nil if outside match range with []" do
      "foo" =~ /foo/
      assert $~[1]?.nil?
    end
  end

  describe "#post_match" do
    it "returns an empty string when there's nothing after" do
      assert "Crystal".match(/ystal/).not_nil!.post_match == ""
    end

    it "returns the part of the string after the match" do
      assert "Crystal".match(/yst/).not_nil!.post_match == "al"
    end

    it "works with unicode" do
      assert "há日本語".match(/本/).not_nil!.post_match == "語"
    end
  end

  describe "#pre_match" do
    it "returns an empty string when there's nothing before" do
      assert "Crystal".match(/Cryst/).not_nil!.pre_match == ""
    end

    it "returns the part of the string before the match" do
      assert "Crystal".match(/yst/).not_nil!.pre_match == "Cr"
    end

    it "works with unicode" do
      assert "há日本語".match(/本/).not_nil!.pre_match == "há日"
    end
  end
end
