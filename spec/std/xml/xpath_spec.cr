require "spec"
require "xml"

private def doc
  XML.parse(%(\
    <?xml version='1.0' encoding='UTF-8'?>
    <people>
      <person id="1">
        <name>John</name>
      </person>
      <person id="2">
        <name>Peter</name>
      </person>
    </people>
    ))
end

module XML
  describe XPathContext do
    it "finds nodes" do
      doc = doc()

      nodes = doc.xpath("//people/person").as(NodeSet)
      assert nodes.size == 2

      assert nodes[0].name == "person"
      assert nodes[0]["id"] == "1"

      assert nodes[1].name == "person"
      assert nodes[1]["id"] == "2"

      nodes = doc.xpath_nodes("//people/person")
      assert nodes.size == 2
    end

    it "finds string" do
      doc = doc()

      id = doc.xpath("string(//people/person[1]/@id)").as(String)
      assert id == "1"

      id = doc.xpath_string("string(//people/person[1]/@id)")
      assert id == "1"
    end

    it "finds number" do
      doc = doc()

      count = doc.xpath("count(//people/person)").as(Float64)
      assert count == 2

      count = doc.xpath_float("count(//people/person)")
      assert count == 2
    end

    it "finds boolean" do
      doc = doc()

      id = doc.xpath("boolean(//people/person[1]/@id)").as(Bool)
      assert id == true

      id = doc.xpath_bool("boolean(//people/person[1]/@id)")
      assert id == true
    end

    it "raises on invalid xpath" do
      expect_raises XML::Error do
        doc = doc()
        doc.xpath("coco()")
      end
    end

    it "returns nil with invalid xpath" do
      doc = doc()
      assert doc.xpath_node("//invalid").nil?
    end

    it "finds with namespace" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
        </feed>
        ))
      nodes = doc.xpath("//atom:feed", namespaces: {"atom" => "http://www.w3.org/2005/Atom"}).as(NodeSet)
      assert nodes.size == 1
      assert nodes[0].name == "feed"
      ns = nodes[0].namespace.not_nil!
      assert ns.href == "http://www.w3.org/2005/Atom"
      assert ns.prefix.nil?
    end

    it "finds with root namespaces" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
        </feed>
        ))
      nodes = doc.xpath("//xmlns:feed", namespaces: doc.root.not_nil!.namespaces).as(NodeSet)
      assert nodes.size == 1
      assert nodes[0].name == "feed"
      ns = nodes[0].namespace.not_nil!
      assert ns.href == "http://www.w3.org/2005/Atom"
      assert ns.prefix.nil?
    end

    it "finds with variable binding" do
      doc = XML.parse(%(\
        <?xml version="1.0" encoding="UTF-8"?>
        <feed>
          <person id="1"/>
          <person id="2"/>
        </feed>
        ))
      nodes = doc.xpath("//feed/person[@id=$value]", variables: {"value" => 2}).as(NodeSet)
      assert nodes.size == 1
      assert nodes[0]["id"] == "2"
    end
  end
end
