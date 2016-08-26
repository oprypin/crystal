require "spec"
require "openssl"

describe OpenSSL::X509::Certificate do
  it "subject" do
    cert = OpenSSL::X509::Certificate.new
    cert.subject = "CN=Nobody/DC=example"
    assert cert.subject.to_a == [{"CN", "Nobody"}, {"DC", "example"}]
  end

  it "extension" do
    cert = OpenSSL::X509::Certificate.new

    cert.add_extension OpenSSL::X509::Extension.new("subjectAltName", "IP:127.0.0.1")
    assert cert.extensions.map(&.oid) == ["subjectAltName"]
    assert cert.extensions.map(&.value) == ["IP Address:127.0.0.1"]

    cert.add_extension OpenSSL::X509::Extension.new("subjectAltName", "DNS:localhost.localdomain")
    assert cert.extensions.map(&.oid) == ["subjectAltName", "subjectAltName"]
    assert cert.extensions.map(&.value) == ["IP Address:127.0.0.1", "DNS:localhost.localdomain"]
  end
end
