require "spec"
require "levenshtein"

describe "levenshtein" do
  it { assert Levenshtein.distance("algorithm", "altruistic") == 6 }
  it { assert Levenshtein.distance("1638452297", "444488444") == 9 }
  it { assert Levenshtein.distance("", "") == 0 }
  it { assert Levenshtein.distance("", "a") == 1 }
  it { assert Levenshtein.distance("aaapppp", "") == 7 }
  it { assert Levenshtein.distance("frog", "fog") == 1 }
  it { assert Levenshtein.distance("fly", "ant") == 3 }
  it { assert Levenshtein.distance("elephant", "hippo") == 7 }
  it { assert Levenshtein.distance("hippo", "elephant") == 7 }
  it { assert Levenshtein.distance("hippo", "zzzzzzzz") == 8 }
  it { assert Levenshtein.distance("hello", "hallo") == 1 }
  it { assert Levenshtein.distance("こんにちは", "こんちは") == 1 }

  it "finds with finder" do
    finder = Levenshtein::Finder.new "hallo"
    finder.test "hay"
    finder.test "hall"
    finder.test "hallo world"
    assert finder.best_match == "hall"
  end

  it "finds with finder and other values" do
    finder = Levenshtein::Finder.new "hallo"
    finder.test "hay", "HAY"
    finder.test "hall", "HALL"
    finder.test "hallo world", "HALLO WORLD"
    assert finder.best_match == "HALL"
  end
end
