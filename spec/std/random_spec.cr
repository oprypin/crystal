require "spec"

describe "Random" do
  it "limited number" do
    assert rand(1) == 0

    x = rand(2)
    assert x >= 0
    assert x < 2
  end

  it "float number" do
    x = rand
    assert x > 0
    assert x < 1
  end

  it "limited float number" do
    x = rand(3.5)
    assert x >= 0
    assert x < 3.5
  end

  it "raises on invalid number" do
    expect_raises ArgumentError, "incorrect rand value: 0" do
      rand(0)
    end
  end

  it "does with inclusive range" do
    assert rand(1..1) == 1
    x = rand(1..3)
    assert x >= 1
    assert x <= 3
  end

  it "does with exclusive range" do
    assert rand(1...2) == 1
    x = rand(1...4)
    assert x >= 1
    assert x < 4
  end

  it "does with inclusive range of floats" do
    assert rand(1.0..1.0) == 1.0
    x = rand(1.8..3.2)
    assert x >= 1.8
    assert x <= 3.2
  end

  it "does with exclusive range of floats" do
    x = rand(1.8...3.3)
    assert x >= 1.8
    assert x < 3.3
  end

  it "raises on invalid range" do
    expect_raises ArgumentError, "incorrect rand value: 1...1" do
      rand(1...1)
    end
  end

  it "allows creating a new default random" do
    rand = Random.new
    value = rand.rand
    assert (0 <= value < 1) == true
  end

  it "allows creating a new default random with a seed" do
    rand = Random.new(1234)
    value1 = rand.rand

    rand = Random.new(1234)
    value2 = rand.rand

    assert value1 == value2
  end

  it "gets a random bool" do
    assert Random::DEFAULT.next_bool.is_a?(Bool)
  end
end
