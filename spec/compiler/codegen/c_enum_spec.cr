require "../../spec_helper"

CodeGenCEnumString = "lib LibFoo; enum Bar; X, Y, Z = 10, W; end end"

describe "Code gen: c enum" do
  it "codegens enum value" do
    assert run("#{CodeGenCEnumString}; LibFoo::Bar::X").to_i == 0
  end

  it "codegens enum value 2" do
    assert run("#{CodeGenCEnumString}; LibFoo::Bar::Y").to_i == 1
  end

  it "codegens enum value 3" do
    assert run("#{CodeGenCEnumString}; LibFoo::Bar::Z").to_i == 10
  end

  it "codegens enum value 4" do
    assert run("#{CodeGenCEnumString}; LibFoo::Bar::W").to_i == 11
  end

  [
    {"1 + 2", 3},
    {"3 - 2", 1},
    {"3 * 2", 6},
    {"10 / 2", 5},
    {"1 << 3", 8},
    {"100 >> 3", 12},
    {"10 & 3", 2},
    {"10 | 3", 11},
    {"(1 + 2) * 3", 9},
    {"10 % 3", 1},
  ].each do |(code, expected)|
    it "codegens enum with #{code} " do
      assert run("
        lib LibFoo
          enum Bar
            X = #{code}
          end
        end

        LibFoo::Bar::X
        ").to_i == expected
    end
  end

  it "codegens enum that refers to another enum constant" do
    assert run("
      lib LibFoo
        enum Bar
          A = 1
          B = A + 1
          C = B + 1
        end
      end

      LibFoo::Bar::C
      ").to_i == 3
  end

  it "codegens enum that refers to another constant" do
    assert run("
      lib LibFoo
        X = 10
        enum Bar
          A = X
          B = A + 1
          C = B + 1
        end
      end

      LibFoo::Bar::C
      ").to_i == 12
  end
end
