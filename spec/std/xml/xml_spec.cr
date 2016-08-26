require "spec"
require "xml"

describe XML do
  it "parses" do
    doc = XML.parse(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <people>
        <person id="1" id2="2">
          <name>John</name>
        </person>
      </people>
      XML
    )
    assert doc.document == doc
    assert doc.name == "document"
    assert doc.attributes.empty? == true
    assert doc.namespace.nil?

    people = doc.root.not_nil!
    assert people.name == "people"
    assert people.type == XML::Type::ELEMENT_NODE

    assert people.attributes.empty? == true

    children = doc.children
    assert children.size == 1
    assert children.empty? == false

    people = children[0]
    assert people.name == "people"

    assert people.document == doc

    children = people.children
    assert children.size == 3

    text = children[0]
    assert text.name == "text"
    assert text.content == "\n  "

    person = children[1]
    assert person.name == "person"

    text = children[2]
    assert text.content == "\n"

    attrs = person.attributes
    assert attrs.empty? == false
    assert attrs.size == 2

    attr = attrs[0]
    assert attr.name == "id"
    assert attr.content == "1"
    assert attr.text == "1"
    assert attr.inner_text == "1"

    attr = attrs[1]
    assert attr.name == "id2"
    assert attr.content == "2"

    assert attrs["id"].content == "1"
    assert attrs["id2"].content == "2"

    assert attrs["id3"]?.nil?
    expect_raises(KeyError) { attrs["id3"] }

    assert person["id"] == "1"
    assert person["id2"] == "2"
    assert person["id3"]?.nil?
    expect_raises(KeyError) { person["id3"] }

    name = person.children.find { |node| node.name == "name" }.not_nil!
    assert name.content == "John"

    assert name.parent == person
  end

  it "parses from io" do
    io = MemoryIO.new(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <people>
        <person id="1" id2="2">
          <name>John</name>
        </person>
      </people>
      XML
    )

    doc = XML.parse(io)
    assert doc.document == doc
    assert doc.name == "document"

    people = doc.children.find { |node| node.name == "people" }.not_nil!
    person = people.children.find { |node| node.name == "person" }.not_nil!
    assert person["id"] == "1"
  end

  it "raises exception on empty string" do
    expect_raises XML::Error, "Document is empty" do
      XML.parse("")
    end
  end

  it "does to_s" do
    string = <<-XML
      <?xml version='1.0' encoding='UTF-8'?>\
      <people>
        <person id="1" id2="2">
          <name>John</name>
        </person>
      </people>
      XML

    doc = XML.parse(string)
    assert doc.to_s.strip == <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <people>
        <person id="1" id2="2">
          <name>John</name>
        </person>
      </people>
      XML
  end

  it "navigates in tree" do
    doc = XML.parse(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <people>
        <person id="1" />
        <person id="2" />
      </people>
      XML
    )

    people = doc.first_element_child.not_nil!
    assert people.name == "people"

    person = people.first_element_child.not_nil!
    assert person.name == "person"
    assert person["id"] == "1"

    text = person.next.not_nil!
    assert text.content == "\n  "

    assert text.previous == person
    assert text.previous_sibling == person

    assert person.next_sibling == text

    person2 = text.next.not_nil!
    assert person2.name == "person"
    assert person2["id"] == "2"

    assert person.next_element == person2
    assert person2.previous_element == person
  end

  it "handles errors" do
    xml = XML.parse(%(<people>))
    assert xml.root.not_nil!.name == "people"
    errors = xml.errors.not_nil!
    assert errors.size == 1
    assert errors[0].message == "Premature end of data in tag people line 1"
    assert errors[0].line_number == 1
    assert errors[0].to_s == "Premature end of data in tag people line 1"
  end

  it "gets root namespaces scopes" do
    doc = XML.parse(<<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      </feed>
      XML
    )
    namespaces = doc.root.not_nil!.namespace_scopes

    assert namespaces.size == 2
    assert namespaces[0].href == "http://www.w3.org/2005/Atom"
    assert namespaces[0].prefix.nil?
    assert namespaces[1].href == "http://a9.com/-/spec/opensearchrss/1.0/"
    assert namespaces[1].prefix == "openSearch"
  end

  it "returns empty array if no namespaces scopes exists" do
    doc = XML.parse(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <name>John</name>
      XML
    )
    namespaces = doc.root.not_nil!.namespace_scopes

    assert namespaces.size == 0
  end

  it "gets root namespaces as hash" do
    doc = XML.parse(<<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      </feed>
      XML
    )
    namespaces = doc.root.not_nil!.namespaces
    assert namespaces == {
      "xmlns"          => "http://www.w3.org/2005/Atom",
      "xmlns:openSearch": "http://a9.com/-/spec/opensearchrss/1.0/",
    }
  end

  it "reads big xml file (#1455)" do
    content = "." * 20_000
    string = %(<?xml version="1.0"?><root>#{content}</root>)
    parsed = XML.parse(MemoryIO.new(string))
    assert parsed.root.not_nil!.children[0].text == content
  end

  it "sets node text/content" do
    doc = XML.parse(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <name>John</name>
      XML
    )
    root = doc.root.not_nil!
    root.text = "Peter"
    assert root.text == "Peter"

    root.content = "Foo"
    assert root.content == "Foo"
  end

  it "sets node name" do
    doc = XML.parse(<<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <name>John</name>
      XML
    )
    root = doc.root.not_nil!
    root.name = "last-name"
    assert root.name == "last-name"
  end

  it "gets encoding" do
    doc = XML.parse(<<-XML
        <?xml version='1.0' encoding='UTF-8'?>
        <people>
        </people>
        XML
    )
    assert doc.encoding == "UTF-8"
  end

  it "gets encoding when nil" do
    doc = XML.parse(<<-XML
        <?xml version='1.0'>
        <people>
        </people>
        XML
    )
    assert doc.encoding.nil?
  end

  it "gets version" do
    doc = XML.parse(<<-XML
        <?xml version='1.0' encoding='UTF-8'?>
        <people>
        </people>
        XML
    )
    assert doc.version == "1.0"
  end

  it "does to_s with correct encoding (#2319)" do
    xml_str = <<-XML
    <?xml version='1.0' encoding='UTF-8'?>
    <person>
      <name>たろう</name>
    </person>
    XML

    doc = XML.parse(xml_str)
    assert doc.root.to_s == "<person>\n  <name>たろう</name>\n</person>"
  end

  describe "escape" do
    it "does not change a safe string" do
      str = XML.escape("safe_string")

      assert str == "safe_string"
    end

    it "escapes dangerous characters from a string" do
      str = XML.escape("< & >")

      assert str == "&lt; &amp; &gt;"
    end
  end
end
