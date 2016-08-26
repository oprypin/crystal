require "spec"
require "openssl"

describe "OpenSSL::X509::Name" do
  it "parse" do
    name = OpenSSL::X509::Name.parse("CN=nobody/DC=example")
    assert name.to_a == [{"CN", "nobody"}, {"DC", "example"}]

    expect_raises(OpenSSL::Error) do
      OpenSSL::X509::Name.parse("CN=nobody/Unknown=Value")
    end
  end

  it "add_entry" do
    name = OpenSSL::X509::Name.new
    assert name.to_a.size == 0

    name.add_entry "CN", "Nobody"
    assert name.to_a == [{"CN", "Nobody"}]

    name.add_entry "DC", "Example"
    assert name.to_a == [{"CN", "Nobody"}, {"DC", "Example"}]

    expect_raises(OpenSSL::Error) { name.add_entry "UNKNOWN", "Value" }
  end
end
