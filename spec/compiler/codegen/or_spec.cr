require "../../spec_helper"

describe "Code gen: or" do
  it "codegens or with bool false and false" do
    assert run("false || false").to_b == false
  end

  it "codegens or with bool false and true" do
    assert run("false || true").to_b == true
  end

  it "codegens or with bool true and true" do
    assert run("true || true").to_b == true
  end

  it "codegens or with bool true and false" do
    assert run("true || false").to_b == true
  end

  it "codegens or with bool and int 1" do
    assert run("struct Bool; def to_i; 0; end; end; (false || 2).to_i").to_i == 2
  end

  it "codegens or with bool and int 2" do
    assert run("struct Bool; def to_i; 0; end; end; (true || 2).to_i").to_i == 0
  end

  it "codegens or with primitive type other than bool" do
    assert run("1 || 2").to_i == 1
  end

  it "codegens or with primitive type other than bool with union" do
    assert run("(1 || 1.5).to_f").to_f64 == 1
  end

  it "codegens or with primitive type other than bool" do
    assert run("require \"nil\"; (nil || 2).to_i").to_i == 2
  end

  it "codegens or with nilable as left node 1" do
    assert run("
      require \"nil\"
      class Object; def to_i; -1; end; end
      a = Reference.new
      a = nil
      (a || 2).to_i
    ").to_i == 2
  end

  it "codegens or with nilable as left node 2" do
    assert run("
      class Object; def to_i; -1; end; end
      a = nil
      a = Reference.new
      (a || 2).to_i
    ").to_i == -1
  end

  it "codegens or with non-false union as left node" do
    assert run("
      a = 1.5
      a = 1
      (a || 2).to_i
    ").to_i == 1
  end

  it "codegens or with nil union as left node 1" do
    assert run("
      require \"nil\"
      a = nil
      a = 1
      (a || 2).to_i
    ").to_i == 1
  end

  it "codegens or with nil union as left node 2" do
    assert run("
      require \"nil\"
      a = 1
      a = nil
      (a || 2).to_i
    ").to_i == 2
  end

  it "codegens or with bool union as left node 1" do
    assert run("
      struct Bool; def to_i; 0; end; end
      a = false
      a = 1
      (a || 2).to_i
    ").to_i == 1
  end

  it "codegens or with bool union as left node 2" do
    assert run("
      struct Bool; def to_i; 0; end; end
      a = 1
      a = false
      (a || 2).to_i
    ").to_i == 2
  end

  it "codegens or with bool union as left node 3" do
    assert run("
      struct Bool; def to_i; 0; end; end
      a = 1
      a = true
      (a || 2).to_i
    ").to_i == 0
  end

  it "codegens or with bool union as left node 1" do
    assert run("
      require \"nil\"
      struct Bool; def to_i; 1; end; end
      a = false
      a = nil
      a = 2
      (a || 3).to_i
    ").to_i == 2
  end

  it "codegens or with bool union as left node 2" do
    assert run("
      require \"nil\"
      struct Bool; def to_i; 1; end; end
      a = nil
      a = 2
      a = false
      (a || 3).to_i
    ").to_i == 3
  end

  it "codegens or with bool union as left node 3" do
    assert run("
      require \"nil\"
      struct Bool; def to_i; 1; end; end
      a = nil
      a = 2
      a = true
      (a || 3).to_i
    ").to_i == 1
  end

  it "codegens or with bool union as left node 4" do
    assert run("
      require \"nil\"
      struct Bool; def to_i; 1; end; end
      a = 2
      a = true
      a = nil
      (a || 3).to_i
    ").to_i == 3
  end
end
