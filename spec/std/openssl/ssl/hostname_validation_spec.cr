require "spec"
require "openssl/ssl/hostname_validation"

def openssl_create_cert(subject = nil, san = nil)
  cert = OpenSSL::X509::Certificate.new
  cert.subject = subject if subject
  cert.add_extension(OpenSSL::X509::Extension.new("subjectAltName", san)) if san
  cert.to_unsafe
end

describe OpenSSL::SSL::HostnameValidation do
  describe "validate_hostname" do
    it "matches IP from certificate SAN entries" do
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("192.168.1.1", openssl_create_cert(san: "IP:192.168.1.1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("192.168.1.2", openssl_create_cert(san: "IP:192.168.1.1")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("::1", openssl_create_cert(san: "IP:::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("::1", openssl_create_cert(san: "IP:::2")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("0:0:0:0:0:0:0:1", openssl_create_cert(san: "IP:::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("fe80:0:0:0:0:0:0:1", openssl_create_cert(san: "IP:fe80::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("fe80:0:0:0:0:0:0:2", openssl_create_cert(san: "IP:fe80::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("fe80:0:1", openssl_create_cert(san: "IP:fe80:0::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("fe80::0:1", openssl_create_cert(san: "IP:fe80:0::1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
    end

    it "matches domains from certificate SAN entries" do
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.com", openssl_create_cert(san: "DNS:example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.org", openssl_create_cert(san: "DNS:example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("foo.example.com", openssl_create_cert(san: "DNS:*.example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
    end

    it "verifies all SAN entries" do
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.com", openssl_create_cert(san: "DNS:example.com,DNS:example.org")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("10.0.3.1", openssl_create_cert(san: "IP:192.168.1.1,IP:10.0.3.1")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.com", openssl_create_cert(san: "IP:192.168.1.1,DNS:example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
    end

    it "fallbacks to CN entry (unless SAN entry is defined)" do
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.com", openssl_create_cert(subject: "CN=example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.com", openssl_create_cert(san: "DNS:example.org", subject: "CN=example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchNotFound
      assert OpenSSL::SSL::HostnameValidation.validate_hostname("example.org", openssl_create_cert(san: "DNS:example.org", subject: "CN=example.com")) == OpenSSL::SSL::HostnameValidation::Result::MatchFound
    end
  end

  describe "matches_hostname?" do
    it "skips trailing dot" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("example.com.", "example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("example.com", "example.com.") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.com", "example.com") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("example.com", ".example.com") == false
    end

    it "normalizes case" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("exAMPLE.cOM", "EXample.Com") == true
    end

    it "literal matches" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("example.com", "example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("example.com", "www.example.com") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("www.example.com", "www.example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("foo.bar.example.com", "bar.example.com") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("foo.bar.example.com", "foo.bar.example.com") == true
    end

    it "wildcard matches according to RFC6125, section 6.4.3" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.com", "example.com") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("bar.*.example.com", "bar.foo.example.com") == false

      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.example.com", "foo.example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.example.com", "foo.example.org") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.example.com", "bar.foo.example.com") == false

      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("baz*.example.com", "baz1.example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("baz*.example.com", "baz.example.com") == false

      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*baz.example.com", "foobaz.example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*baz.example.com", "baz.example.com") == false

      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("b*z.example.com", "buzz.example.com") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("b*z.example.com", "bz.example.com") == false

      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("192.168.0.1", "192.168.0.1") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.168.0.1", "192.168.0.1") == false
    end

    it "matches IDNA label" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.example.org", "xn--kcry6tjko.example.org") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("*.xn--kcry6tjko.example.org", "foo.xn--kcry6tjko.example.org") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("xn--*.example.org", "xn--kcry6tjko.example.org") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?("xn--kcry6tjko*.example.org", "xn--kcry6tjkofoo.example.org") == false
    end

    it "matches leading dot" do
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.org", "example.org") == false
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.org", "xn--kcry6tjko.example.org") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.org", "foo.example.org") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.org", "foo.bar.example.org") == true
      assert OpenSSL::SSL::HostnameValidation.matches_hostname?(".example.org", "foo.example.com") == false
    end
  end
end
