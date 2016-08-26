require "spec"
require "xml"

describe XML do
  it "parses HTML" do
    doc = XML.parse_html(%(\
      <!doctype html>
      <html>
      <head>
          <title>Samantha</title>
      </head>
      <body>
          <h1 class="large">Boat</h1>
      </body>
      </html>
    ))

    html = doc.children[1]
    assert html.name == "html"

    head = html.children.find { |node| node.name == "head" }.not_nil!
    assert head.name == "head"

    title = head.children.find { |node| node.name == "title" }.not_nil!
    assert title.text == "Samantha"

    body = html.children.find { |node| node.name == "body" }.not_nil!

    h1 = body.children.find { |node| node.name == "h1" }.not_nil!

    attrs = h1.attributes
    assert attrs.empty? == false
    assert attrs.size == 1

    attr = attrs[0]
    assert attr.name == "class"
    assert attr.content == "large"
    assert attr.text == "large"
    assert attr.inner_text == "large"
  end

  it "parses HTML from IO" do
    io = MemoryIO.new(%(\
      <!doctype html>
      <html>
      <head>
          <title>Samantha</title>
      </head>
      <body>
          <h1 class="large">Boat</h1>
      </body>
      </html>
    ))

    doc = XML.parse_html(io)
    html = doc.children[1]
    assert html.name == "html"
  end

  it "parses html5 (#1404)" do
    html5 = "<html><body><nav>Test</nav></body></html>"
    xml = XML.parse_html(html5)
    assert xml.errors
    assert xml.xpath_node("//html/body/nav")
  end

  it "raises error when parsing empty string (#2752)" do
    expect_raises XML::Error, "Document is empty" do
      XML.parse_html("")
    end
  end
end
