require "spec"
require "big_float"

describe "BigFloat" do
  describe "-@" do
    bf = "0.12345".to_big_f
    it { assert (-bf).to_s == "-0.12345" }

    bf = "61397953.0005354".to_big_f
    it { assert (-bf).to_s == "-61397953.0005354" }

    bf = "395.009631567315769036".to_big_f
    it { assert (-bf).to_s == "-395.009631567315769036" }
  end

  describe "+" do
    it { assert ("1.0".to_big_f + "2.0".to_big_f).to_s == "3" }
    it { assert ("0.04".to_big_f + "89.0001".to_big_f).to_s == "89.0401" }
    it { assert ("-5.5".to_big_f + "5.5".to_big_f).to_s == "0" }
    it { assert ("5.5".to_big_f + "-5.5".to_big_f).to_s == "0" }
  end

  describe "-" do
    it { assert ("1.0".to_big_f - "2.0".to_big_f).to_s == "-1" }
    it { assert ("0.04".to_big_f - "89.0001".to_big_f).to_s == "-88.9601" }
    it { assert ("-5.5".to_big_f - "5.5".to_big_f).to_s == "-11" }
    it { assert ("5.5".to_big_f - "-5.5".to_big_f).to_s == "11" }
  end

  describe "*" do
    it { assert ("1.0".to_big_f * "2.0".to_big_f).to_s == "2" }
    it { assert ("0.04".to_big_f * "89.0001".to_big_f).to_s == "3.560004" }
    it { assert ("-5.5".to_big_f * "5.5".to_big_f).to_s == "-30.25" }
    it { assert ("5.5".to_big_f * "-5.5".to_big_f).to_s == "-30.25" }
  end

  describe "/" do
    it { assert ("1.0".to_big_f / "2.0".to_big_f).to_s == "0.5" }
    it { assert ("0.04".to_big_f / "89.0001".to_big_f).to_s == "0.000449437697261014313467" }
    it { assert ("-5.5".to_big_f / "5.5".to_big_f).to_s == "-1" }
    it { assert ("5.5".to_big_f / "-5.5".to_big_f).to_s == "-1" }
    expect_raises(DivisionByZero) { 0.1.to_big_f / 0 }
  end

  describe "**" do
    # TODO: investigate why in travis this gives ""1.79559999999999999991"
    # assert { ("1.34".to_big_f ** 2).to_s.should eq("1.79559999999999999994") }
    it { assert ("-0.05".to_big_f ** 10).to_s == "0.00000000000009765625" }
    it { assert (0.1234567890.to_big_f ** 3).to_s == "0.00188167637178915473909" }
  end

  describe "abs" do
    it { assert -5.to_big_f.abs == 5 }
    it { assert 5.to_big_f.abs == 5 }
    it { assert "-0.00001".to_big_f.abs.to_s == "0.00001" }
    it { assert "0.00000000001".to_big_f.abs.to_s == "0.00000000001" }
  end

  describe "ceil" do
    it { assert 2.0.to_big_f.ceil == 2 }
    it { assert 2.1.to_big_f.ceil == 3 }
    it { assert 2.9.to_big_f.ceil == 3 }
  end

  describe "floor" do
    it { assert 2.1.to_big_f.floor == 2 }
    it { assert 2.9.to_big_f.floor == 2 }
  end

  describe "to_f" do
    it { assert 1.34.to_big_f.to_f == 1.34 }
    it { assert 0.0001304.to_big_f.to_f == 0.0001304 }
    it { assert 1.234567.to_big_f.to_f32 == 1.234567_f32 }
  end

  describe "to_i" do
    it { assert 1.34.to_big_f.to_i == 1 }
    it { assert 123.to_big_f.to_i == 123 }
    it { assert -4321.to_big_f.to_i == -4321 }
  end

  describe "to_u" do
    it { assert 1.34.to_big_f.to_u == 1 }
    it { assert 123.to_big_f.to_u == 123 }
    it { assert 4321.to_big_f.to_u == 4321 }
  end

  describe "to_s" do
    it { assert "0".to_big_f.to_s == "0" }
    it { assert "0.000001".to_big_f.to_s == "0.000001" }
    it { assert "48600000".to_big_f.to_s == "48600000" }
    it { assert "12345678.87654321".to_big_f.to_s == "12345678.87654321" }
    it { assert "9.000000000000987".to_big_f.to_s == "9.000000000000987" }
    it { assert "12345678901234567".to_big_f.to_s == "12345678901234567" }
  end

  it "#hash" do
    b = 123.to_big_f
    assert b.hash == b.to_f64.hash
  end

  it "clones" do
    x = 1.to_big_f
    assert x.clone == x
  end
end
