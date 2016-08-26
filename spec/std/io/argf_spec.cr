require "spec"

describe IO::ARGF do
  it "reads from STDIN if ARGV isn't specified" do
    argv = [] of String
    stdin = MemoryIO.new("hello")

    argf = IO::ARGF.new argv, stdin
    assert argf.path == "-"
    assert argf.gets_to_end == "hello"
    assert argf.read_byte.nil?
  end

  it "reads from ARGV if specified" do
    path1 = "#{__DIR__}/../data/argf_test_file_1.txt"
    path2 = "#{__DIR__}/../data/argf_test_file_2.txt"
    stdin = MemoryIO.new("")
    argv = [path1, path2]

    argf = IO::ARGF.new argv, stdin
    assert argf.path == path1
    assert argv == [path1, path2]

    str = argf.gets(5)
    assert str == "12345"

    assert argv == [path2]

    str = argf.gets_to_end
    assert str == "\n67890\n"

    assert argv.empty? == true

    assert argf.read_byte.nil?

    argv << path1
    str = argf.gets(5)
    assert str == "12345"
  end
end
