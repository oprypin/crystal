require "spec"
require "ecr"
require "ecr/processor"

class ECRSpecHelloView
  @msg : String

  def initialize(@msg)
  end

  ECR.def_to_s "#{__DIR__}/../data/test_template.ecr"
end

describe "ECR" do
  it "builds a crystal program from a source" do
    program = ECR.process_string "hello <%= 1 %> wor\nld <% while true %> 2 <% end %>\n<%# skip %> <%% \"string\" %>", "foo.cr"

    pieces = [
      %(__str__ << "hello "),
      %((#<loc:"foo.cr",1,10> 1 ).to_s __str__),
      %(__str__ << " wor\\nld "),
      %(#<loc:"foo.cr",2,6> while true ),
      %(__str__ << " 2 "),
      %(#<loc:"foo.cr",2,25> end ),
      %(__str__ << "\\n"),
      %(#<loc:\"foo.cr\",3,3> # skip ),
      %(__str__ << " "),
      %(__str__ << "<% \\"string\\" %>"),
    ]
    assert program == pieces.join("\n") + "\n"
  end

  it "does ECR.def_to_s" do
    view = ECRSpecHelloView.new("world!")
    assert view.to_s.strip == "Hello world! 012"
  end

  it "does with <%= -%>" do
    io = MemoryIO.new
    ECR.embed "#{__DIR__}/../data/test_template2.ecr", io
    assert io.to_s == "123"
  end

  it "does with <%- %> (1)" do
    io = MemoryIO.new
    ECR.embed "#{__DIR__}/../data/test_template3.ecr", io
    assert io.to_s == "01"
  end

  it "does with <%- %> (2)" do
    io = MemoryIO.new
    ECR.embed "#{__DIR__}/../data/test_template4.ecr", io
    assert io.to_s == "hi\n01"
  end

  it "does with <% -%>" do
    io = MemoryIO.new
    ECR.embed "#{__DIR__}/../data/test_template5.ecr", io
    assert io.to_s == "hi\n      0\n      1\n  "
  end

  it "does with -% inside string" do
    io = MemoryIO.new
    ECR.embed "#{__DIR__}/../data/test_template6.ecr", io
    assert io.to_s == "string with -%"
  end
end
