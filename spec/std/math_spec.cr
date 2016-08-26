require "spec"

describe "Math" do
  describe "Mathematical constants" do
    it "E" do
      assert Math::E.close?(2.718281828459045, 1e-7)
    end

    it "LOG2" do
      assert Math::LOG2.close?(0.6931471805599453, 1e-7)
    end

    it "LOG10" do
      assert Math::LOG10.close?(2.302585092994046, 1e-7)
    end
  end

  describe "Functions manipulating signs" do
    it "copysign" do
      assert Math.copysign(6.9, -0.2) == -6.9
    end
  end

  describe "Order-related functions" do
    assert Math.min(2.1, 2.11) == 2.1
    assert Math.max(3.2, 3.11) == 3.2
  end

  pending "Functions for computing quotient and remainder" do
  end

  describe "Roots" do
    it "cbrt" do
      assert Math.cbrt(6.5_f32).close?(1.866255578408624, 1e-7)
      assert Math.cbrt(6.5).close?(1.866255578408624, 1e-7)
    end

    it "sqrt" do
      assert Math.sqrt(5.2_f32).close?(2.280350850198276, 1e-7)
      assert Math.sqrt(5.2).close?(2.280350850198276, 1e-7)
      assert Math.sqrt(4_f32) == 2
      assert Math.sqrt(4) == 2
    end
  end

  describe "Exponents" do
    it "exp" do
      assert Math.exp(0.211_f32).close?(1.2349123550613943, 1e-7)
      assert Math.exp(0.211).close?(1.2349123550613943, 1e-7)
    end

    it "exp2" do
      assert Math.exp2(0.41_f32).close?(1.3286858140965117, 1e-7)
      assert Math.exp2(0.41).close?(1.3286858140965117, 1e-7)
    end

    it "expm1" do
      assert Math.expm1(0.99_f32).close?(1.6912344723492623, 1e-7)
      assert Math.expm1(0.99).close?(1.6912344723492623, 1e-7)
    end

    it "ilogb" do
      assert Math.ilogb(0.5_f32) == -1
      assert Math.ilogb(0.5) == -1
    end

    it "ldexp" do
      assert Math.ldexp(0.27_f32, 2).close?(1.08, 1e-7)
      assert Math.ldexp(0.27, 2).close?(1.08, 1e-7)
    end

    it "logb" do
      assert Math.logb(10_f32).close?(3.0, 1e-7)
      assert Math.logb(10.0).close?(3.0, 1e-7)
    end

    it "scalbn" do
      assert Math.scalbn(0.2_f32, 3).close?(1.6, 1e-7)
      assert Math.scalbn(0.2, 3).close?(1.6, 1e-7)
    end

    it "scalbln" do
      assert Math.scalbln(0.11_f32, 2).close?(0.44, 1e-7)
      assert Math.scalbln(0.11, 2).close?(0.44, 1e-7)
    end
  end

  describe "Logarithms" do
    it "log" do
      assert Math.log(3.24_f32).close?(1.1755733298042381, 1e-7)
      assert Math.log(3.24).close?(1.1755733298042381, 1e-7)
      assert Math.log(0.3_f32, 3).close?(-1.0959032742893848, 1e-7)
      assert Math.log(0.3, 3).close?(-1.0959032742893848, 1e-7)
    end

    it "log2" do
      assert Math.log2(1.2_f32).close?(0.2630344058337938, 1e-7)
      assert Math.log2(1.2).close?(0.2630344058337938, 1e-7)
    end

    it "log10" do
      assert Math.log10(0.5_f32).close?(-0.3010299956639812, 1e-7)
      assert Math.log10(0.5).close?(-0.3010299956639812, 1e-7)
    end

    it "log1p" do
      assert Math.log1p(0.67_f32).close?(0.5128236264286637, 1e-7)
      assert Math.log1p(0.67).close?(0.5128236264286637, 1e-7)
    end
  end

  describe "Trigonometric functions" do
    it "cos" do
      assert Math.cos(2.23_f32).close?(-0.6124875656583851, 1e-7)
      assert Math.cos(2.23).close?(-0.6124875656583851, 1e-7)
    end

    it "sin" do
      assert Math.sin(3.3_f32).close?(-0.1577456941432482, 1e-7)
      assert Math.sin(3.3).close?(-0.1577456941432482, 1e-7)
    end

    it "tan" do
      assert Math.tan(0.91_f32).close?(1.2863693807208076, 1e-7)
      assert Math.tan(0.91).close?(1.2863693807208076, 1e-7)
    end

    it "hypot" do
      assert Math.hypot(2.1_f32, 1.5_f32).close?(2.5806975801127883, 1e-7)
      assert Math.hypot(2.1, 1.5).close?(2.5806975801127883, 1e-7)
    end
  end

  describe "Inverse trigonometric functions" do
    it "acos" do
      assert Math.acos(0.125_f32).close?(1.445468495626831, 1e-7)
      assert Math.acos(0.125).close?(1.445468495626831, 1e-7)
    end

    it "asin" do
      assert Math.asin(-0.4_f32).close?(-0.41151684606748806, 1e-7)
      assert Math.asin(-0.4).close?(-0.41151684606748806, 1e-7)
    end

    it "atan" do
      assert Math.atan(4.3_f32).close?(1.3422996875030344, 1e-7)
      assert Math.atan(4.3).close?(1.3422996875030344, 1e-7)
    end

    it "atan2" do
      assert Math.atan2(3.5_f32, 2.1_f32).close?(1.0303768265243125, 1e-7)
      assert Math.atan2(3.5, 2.1).close?(1.0303768265243125, 1e-7)
      assert Math.atan2(1, 0) == Math.atan2(1.0, 0.0)
    end
  end

  describe "Hyperbolic functions" do
    it "cosh" do
      assert Math.cosh(0.79_f32).close?(1.3286206107691463, 1e-7)
      assert Math.cosh(0.79).close?(1.3286206107691463, 1e-7)
    end

    it "sinh" do
      assert Math.sinh(0.12_f32).close?(0.12028820743110909, 1e-7)
      assert Math.sinh(0.12).close?(0.12028820743110909, 1e-7)
    end

    it "tanh" do
      assert Math.tanh(4.1_f32).close?(0.9994508436877974, 1e-7)
      assert Math.tanh(4.1).close?(0.9994508436877974, 1e-7)
    end
  end

  describe "Inverse hyperbolic functions" do
    it "acosh" do
      assert Math.acosh(1.1_f32).close?(0.4435682543851154, 1e-7)
      assert Math.acosh(1.1).close?(0.4435682543851154, 1e-7)
    end

    it "asinh" do
      assert Math.asinh(-2.3_f32).close?(-1.570278543484978, 1e-7)
      assert Math.asinh(-2.3).close?(-1.570278543484978, 1e-7)
    end

    it "atanh" do
      assert Math.atanh(0.13_f32).close?(0.13073985002887845, 1e-7)
      assert Math.atanh(0.13).close?(0.13073985002887845, 1e-7)
    end
  end

  describe "Gamma functions" do
    it "gamma" do
      assert Math.gamma(3.2_f32).close?(2.4239654799353683, 1e-6)
      assert Math.gamma(3.2).close?(2.4239654799353683, 1e-7)
    end

    it "lgamma" do
      assert Math.lgamma(2.96_f32).close?(0.6565534110944214, 1e-7)
      assert Math.lgamma(2.96).close?(0.6565534110944214, 1e-7)
    end
  end

  describe "Bessel functions" do
    it "besselj0" do
      assert Math.besselj0(9.1_f32).close?(-0.11423923268319867, 1e-7)
      assert Math.besselj0(9.1).close?(-0.11423923268319867, 1e-7)
    end

    it "besselj1" do
      assert Math.besselj1(-2.1_f32).close?(-0.5682921357570385, 1e-7)
      assert Math.besselj1(-2.1).close?(-0.5682921357570385, 1e-7)
    end

    it "besselj" do
      assert Math.besselj(4, -6.4_f32).close?(0.2945338623574655, 1e-7)
      assert Math.besselj(4, -6.4).close?(0.2945338623574655, 1e-7)
    end

    it "bessely0" do
      assert Math.bessely0(2.14_f32).close?(0.5199289108068015, 1e-7)
      assert Math.bessely0(2.14).close?(0.5199289108068015, 1e-7)
    end

    it "bessely1" do
      assert Math.bessely1(7.7_f32).close?(-0.2243184743430081, 1e-7)
      assert Math.bessely1(7.7).close?(-0.2243184743430081, 1e-7)
    end

    it "bessely" do
      assert Math.bessely(3, 2.7_f32).close?(-0.6600575162477298, 1e-7)
      assert Math.bessely(3, 2.7).close?(-0.6600575162477298, 1e-7)
    end
  end

  describe "Gauss error functions" do
    it "erf" do
      assert Math.erf(0.72_f32).close?(0.6914331231387512, 1e-7)
      assert Math.erf(0.72).close?(0.6914331231387512, 1e-7)
    end

    it "erfc" do
      assert Math.erfc(-0.66_f32).close?(1.6493766879629543, 1e-7)
      assert Math.erfc(-0.66).close?(1.6493766879629543, 1e-7)
    end
  end

  # div rem

  # pw2ceil

  describe "Rounding up to powers of 2" do
    it "pw2ceil" do
      assert Math.pw2ceil(33) == 64
      assert Math.pw2ceil(128) == 128
    end
  end

  # ** (float and int)
end
