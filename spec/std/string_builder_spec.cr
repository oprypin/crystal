require "spec"

describe String::Builder do
  it "builds" do
    str = String::Builder.build do |builder|
      builder << 123
      builder << 456
    end
    assert str == "123456"
    assert str.size == 6
    assert str.bytesize == 6
  end

  it "raises if invokes to_s twice" do
    builder = String::Builder.new
    builder << 123
    assert builder.to_s == "123"

    expect_raises { builder.to_s }
  end
end
