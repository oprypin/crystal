require "spec"
require "openssl/cipher"

describe OpenSSL::Cipher do
  it "encrypts/decrypts" do
    cipher = "aes-128-cbc"
    c1 = OpenSSL::Cipher.new(cipher)
    c2 = OpenSSL::Cipher.new(cipher)
    key = "\0" * 16
    iv = "\0" * 16
    data = "DATA" * 5
    ciphertext = File.read(File.join(__DIR__ + "/cipher_spec.ciphertext"))

    assert c1.name == c2.name

    c1.encrypt
    c2.encrypt
    c1.key = c2.key = key
    c1.iv = c2.iv = iv

    s1 = MemoryIO.new
    s2 = MemoryIO.new
    s1.write(c1.update("DATA"))
    s1.write(c1.update("DATA" * 4))
    s1.write(c1.final)
    s2.write(c2.update(data))
    s2.write(c2.final)

    assert s1.to_slice == ciphertext.to_slice
    assert s1.to_slice == s2.to_slice

    c1.decrypt
    c2.decrypt
    c1.key = c2.key = key
    c1.iv = c2.iv = iv

    s3 = MemoryIO.new
    s4 = MemoryIO.new
    s3.write(c1.update(s1.to_slice))
    s3.write(c1.final)

    s4.write(c2.update(s2.to_slice))
    s4.write(c2.final)
    assert s3.to_s == data
    assert s3.to_slice == s4.to_slice
  end
end
