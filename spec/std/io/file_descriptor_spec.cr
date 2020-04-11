require "../../spec_helper"

describe IO::FileDescriptor do
  it "reopen STDIN with the right mode" do
    code = %q(puts "#{STDIN.blocking} #{STDIN.info.type}")
    build(code) do |binpath|
      `#{Process.shell_quote(binpath)} < #{Process.shell_quote(binpath)}`.chomp.should eq("true File")
      `echo "" | #{Process.shell_quote(binpath)}`.chomp.should eq("false Pipe")
    end
  end
end
