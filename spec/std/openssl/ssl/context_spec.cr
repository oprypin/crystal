require "spec"
require "openssl"

describe OpenSSL::SSL::Context do
  it "new for client" do
    context = OpenSSL::SSL::Context::Client.new
    assert context.options == OpenSSL::SSL::Options.flags(
      ALL, NO_SSLV2, NO_SSLV3, NO_SESSION_RESUMPTION_ON_RENEGOTIATION, SINGLE_ECDH_USE, SINGLE_DH_USE
    )
    assert context.modes == OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS)
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::PEER

    OpenSSL::SSL::Context::Client.new(LibSSL.tlsv1_method)
  end

  it "new for server" do
    context = OpenSSL::SSL::Context::Server.new
    assert context.options == OpenSSL::SSL::Options.flags(
      ALL, NO_SSLV2, NO_SSLV3, NO_SESSION_RESUMPTION_ON_RENEGOTIATION, SINGLE_ECDH_USE, SINGLE_DH_USE, CIPHER_SERVER_PREFERENCE
    )
    assert context.modes == OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS)
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::NONE

    OpenSSL::SSL::Context::Server.new(LibSSL.tlsv1_method)
  end

  it "insecure for client" do
    context = OpenSSL::SSL::Context::Client.insecure
    assert context.is_a?(OpenSSL::SSL::Context::Client)
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::NONE
    assert context.options.no_ssl_v3? != true
    assert context.modes == OpenSSL::SSL::Modes::None

    OpenSSL::SSL::Context::Client.insecure(LibSSL.tlsv1_method)
  end

  it "insecure for server" do
    context = OpenSSL::SSL::Context::Server.insecure
    assert context.is_a?(OpenSSL::SSL::Context::Server)
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::NONE
    assert context.options.no_ssl_v3? != true
    assert context.modes == OpenSSL::SSL::Modes::None

    OpenSSL::SSL::Context::Server.insecure(LibSSL.tlsv1_method)
  end

  it "sets certificate chain" do
    context = OpenSSL::SSL::Context::Client.new
    context.certificate_chain = File.join(__DIR__, "openssl.crt")
  end

  it "fails to set certificate chain" do
    context = OpenSSL::SSL::Context::Client.new
    expect_raises(OpenSSL::Error) { context.certificate_chain = File.join(__DIR__, "unknown.crt") }
    expect_raises(OpenSSL::Error) { context.certificate_chain = __FILE__ }
  end

  it "sets private key" do
    context = OpenSSL::SSL::Context::Client.new
    context.private_key = File.join(__DIR__, "openssl.key")
  end

  it "fails to set private key" do
    context = OpenSSL::SSL::Context::Client.new
    expect_raises(OpenSSL::Error) { context.private_key = File.join(__DIR__, "unknown.key") }
    expect_raises(OpenSSL::Error) { context.private_key = __FILE__ }
  end

  it "sets ciphers" do
    ciphers = "EDH+aRSA DES-CBC3-SHA !RC4"
    context = OpenSSL::SSL::Context::Client.new
    assert (context.ciphers = ciphers) == ciphers
  end

  it "adds temporary ecdh curve (P-256)" do
    context = OpenSSL::SSL::Context::Client.new
    context.set_tmp_ecdh_key
  end

  it "adds options" do
    context = OpenSSL::SSL::Context::Client.new
    context.remove_options(context.options) # reset
    default_options = context.options       # options we can't unset
    assert context.add_options(OpenSSL::SSL::Options::ALL) == default_options | OpenSSL::SSL::Options::ALL
    assert context.add_options(OpenSSL::SSL::Options.flags(NO_SSLV2, NO_SSLV3)) == OpenSSL::SSL::Options.flags(ALL, NO_SSLV2, NO_SSLV3)
  end

  it "removes options" do
    context = OpenSSL::SSL::Context::Client.insecure
    default_options = context.options
    context.add_options(OpenSSL::SSL::Options.flags(NO_TLSV1, NO_SSLV2))
    assert context.remove_options(OpenSSL::SSL::Options::NO_TLSV1) == default_options | OpenSSL::SSL::Options::NO_SSLV2
  end

  it "returns options" do
    context = OpenSSL::SSL::Context::Client.insecure
    default_options = context.options
    context.add_options(OpenSSL::SSL::Options.flags(ALL, NO_SSLV2))
    assert context.options == default_options | OpenSSL::SSL::Options.flags(ALL, NO_SSLV2)
  end

  it "adds modes" do
    context = OpenSSL::SSL::Context::Client.insecure
    assert context.add_modes(OpenSSL::SSL::Modes::AUTO_RETRY) == OpenSSL::SSL::Modes::AUTO_RETRY
    assert context.add_modes(OpenSSL::SSL::Modes::RELEASE_BUFFERS) == OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS)
  end

  it "removes modes" do
    context = OpenSSL::SSL::Context::Client.insecure
    context.add_modes(OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS))
    assert context.remove_modes(OpenSSL::SSL::Modes::AUTO_RETRY) == OpenSSL::SSL::Modes::RELEASE_BUFFERS
  end

  it "returns modes" do
    context = OpenSSL::SSL::Context::Client.insecure
    context.add_modes(OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS))
    assert context.modes == OpenSSL::SSL::Modes.flags(AUTO_RETRY, RELEASE_BUFFERS)
  end

  it "sets the verify mode" do
    context = OpenSSL::SSL::Context::Client.new
    context.verify_mode = OpenSSL::SSL::VerifyMode::NONE
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::NONE
    context.verify_mode = OpenSSL::SSL::VerifyMode::PEER
    assert context.verify_mode == OpenSSL::SSL::VerifyMode::PEER
  end

  {% if LibSSL::OPENSSL_102 %}
  it "alpn_protocol=" do
    context = OpenSSL::SSL::Context::Client.insecure
    context.alpn_protocol = "h2"
  end
  {% end %}
end
