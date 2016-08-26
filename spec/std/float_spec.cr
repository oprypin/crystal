require "spec"

describe "Float" do
  describe "**" do
    it { assert (2.5_f32 ** 2_i32).close?(6.25_f32, 0.0001) }
    it { assert (2.5_f32 ** 2).close?(6.25_f32, 0.0001) }
    it { assert (2.5_f32 ** 2.5_f32).close?(9.882117688026186_f32, 0.0001) }
    it { assert (2.5_f32 ** 2.5).close?(9.882117688026186_f32, 0.0001) }
    it { assert (2.5_f64 ** 2_i32).close?(6.25_f64, 0.0001) }
    it { assert (2.5_f64 ** 2).close?(6.25_f64, 0.0001) }
    it { assert (2.5_f64 ** 2.5_f64).close?(9.882117688026186_f64, 0.0001) }
    it { assert (2.5_f64 ** 2.5).close?(9.882117688026186_f64, 0.001) }
  end

  describe "%" do
    it "uses modulo behavior, not remainder behavior" do
      it { assert ((-11.5) % 4.0) == 0.5 }
    end
  end

  describe "modulo" do
    it "raises when mods by zero" do
      expect_raises(DivisionByZero) { 1.2.modulo 0.0 }
    end

    it { assert (13.0.modulo 4.0) == 1.0 }
    it { assert (13.0.modulo -4.0) == -3.0 }
    it { assert (-13.0.modulo 4.0) == 3.0 }
    it { assert (-13.0.modulo -4.0) == -1.0 }
    it { assert (11.5.modulo 4.0) == 3.5 }
    it { assert (11.5.modulo -4.0) == -0.5 }
    it { assert (-11.5.modulo 4.0) == 0.5 }
    it { assert (-11.5.modulo -4.0) == -3.5 }
  end

  describe "remainder" do
    it "raises when mods by zero" do
      expect_raises(DivisionByZero) { 1.2.remainder 0.0 }
    end

    it { assert (13.0.remainder 4.0) == 1.0 }
    it { assert (13.0.remainder -4.0) == 1.0 }
    it { assert (-13.0.remainder 4.0) == -1.0 }
    it { assert (-13.0.remainder -4.0) == -1.0 }
    it { assert (11.5.remainder 4.0) == 3.5 }
    it { assert (11.5.remainder -4.0) == 3.5 }
    it { assert (-11.5.remainder 4.0) == -3.5 }
    it { assert (-11.5.remainder -4.0) == -3.5 }

    it "preserves type" do
      r = 1.5_f32.remainder(1)
      assert typeof(r) == Float32
    end
  end

  describe "round" do
    it { assert 2.5.round == 3 }
    it { assert 2.4.round == 2 }
  end

  describe "floor" do
    it { assert 2.1.floor == 2 }
    it { assert 2.9.floor == 2 }
  end

  describe "ceil" do
    it { assert 2.0_f32.ceil == 2 }
    it { assert 2.0.ceil == 2 }

    it { assert 2.1_f32.ceil == 3_f32 }
    it { assert 2.1.ceil == 3 }

    it { assert 2.9_f32.ceil == 3 }
    it { assert 2.9.ceil == 3 }
  end

  describe "fdiv" do
    it { assert 1.0.fdiv(1) == 1.0 }
    it { assert 1.0.fdiv(2) == 0.5 }
    it { assert 1.0.fdiv(0.5) == 2.0 }
    it { assert 0.0.fdiv(1) == 0.0 }
    it { assert 1.0.fdiv(0) == 1.0/0.0 }
  end

  describe "to_s" do
    it "does to_s for f64" do
      assert 12.34.to_s == "12.34"
      assert 1.2.to_s == "1.2"
      assert 1.23.to_s == "1.23"
      assert 1.234.to_s == "1.234"
      assert 0.65000000000000002.to_s == "0.65"
      assert 1.234001.to_s == "1.234001"
      assert 1.23499.to_s == "1.23499"
      assert 1.23499999999999.to_s == "1.235"
      assert 1.2345.to_s == "1.2345"
      assert 1.23456.to_s == "1.23456"
      assert 1.234567.to_s == "1.234567"
      assert 1.2345678.to_s == "1.2345678"
      assert 1.23456789.to_s == "1.23456789"
      assert 1.234567891.to_s == "1.234567891"
      assert 1.2345678911.to_s == "1.2345678911"
      assert 1.2345678912.to_s == "1.2345678912"
      assert 1.23456789123.to_s == "1.23456789123"
      assert 9525365.25.to_s == "9525365.25"
      assert 12.9999.to_s == "12.9999"
      assert 12.999999999999.to_s == "13.0"
      assert 1.0.to_s == "1.0"
      assert 2e20.to_s == "2.0e+20"
      assert 1e-10.to_s == "1.0e-10"
      assert 1464132168.65.to_s == "1464132168.65"
      assert 146413216.865.to_s == "146413216.865"
      assert 14641321.6865.to_s == "14641321.6865"
      assert 1464132.16865.to_s == "1464132.16865"
      assert 654329382.1.to_s == "654329382.1"
      assert 6543293824.1.to_s == "6543293824.1"
      assert 65432938242.1.to_s == "65432938242.1"
      assert 654329382423.1.to_s == "654329382423.1"
      assert 6543293824234.1.to_s == "6543293824234.1"
      assert 65432938242345.1.to_s == "65432938242345.1"
      assert 65432.123e20.to_s == "6.5432123e+24"
      assert 65432.123e200.to_s == "6.5432123e+204"
      assert -65432.123e200.to_s == "-6.5432123e+204"
      assert 65432.123456e20.to_s == "6.5432123456e+24"
      assert 65432.1234567e20.to_s == "6.54321234567e+24"
      assert 65432.12345678e20.to_s == "6.543212345678e+24"
      assert 65432.1234567891e20.to_s == "6.54321234567891e+24"
      assert (1.0/0.0).to_s == "Infinity"
      assert (-1.0/0.0).to_s == "-Infinity"
    end

    it "does to_s for f32" do
      assert 12.34_f32.to_s == "12.34"
      assert 1.2_f32.to_s == "1.2"
      assert 1.23_f32.to_s == "1.23"
      assert 1.234_f32.to_s == "1.234"
      assert 0.65000000000000002_f32.to_s == "0.65"
      # 1.234001_f32.to_s.should eq("1.234001")
      assert 1.23499_f32.to_s == "1.23499"
      assert 1.23499999999999_f32.to_s == "1.235"
      assert 1.2345_f32.to_s == "1.2345"
      assert 1.23456_f32.to_s == "1.23456"
      # 9525365.25_f32.to_s.should eq("9525365.25")
      assert (1.0_f32/0.0_f32).to_s == "Infinity"
      assert (-1.0_f32/0.0_f32).to_s == "-Infinity"
    end
  end

  describe "hash" do
    it "does for Float32" do
      assert 1.2_f32.hash != 0
    end

    it "does for Float64" do
      assert 1.2.hash != 0
    end
  end

  it "casts" do
    assert Float32.new(1_f64).is_a?(Float32)
    assert Float32.new(1_f64) == 1

    assert Float64.new(1_f32).is_a?(Float64)
    assert Float64.new(1_f32) == 1
  end

  it "does nan?" do
    assert 1.5.nan? == false
    assert (0.0 / 0.0).nan? == true
  end

  it "does infinite?" do
    assert (0.0).infinite?.nil?
    assert (-1.0/0.0).infinite? == -1
    assert (1.0/0.0).infinite? == 1

    assert (0.0_f32).infinite?.nil?
    assert (-1.0_f32/0.0_f32).infinite? == -1
    assert (1.0_f32/0.0_f32).infinite? == 1
  end

  it "does finite?" do
    assert 0.0.finite? == true
    assert 1.5.finite? == true
    assert (1.0/0.0).finite? == false
    assert (-1.0/0.0).finite? == false
    assert (-0.0/0.0).finite? == false
  end

  it "does unary -" do
    f = -(1.5)
    assert f == -1.5
    assert f.is_a?(Float64)

    f = -(1.5_f32)
    assert f == -1.5_f32
    assert f.is_a?(Float32)
  end

  it "clones" do
    assert 1.0.clone == 1.0
    assert 1.0_f32.clone == 1.0_f32
  end
end
