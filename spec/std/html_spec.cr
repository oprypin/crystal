require "spec"
require "html"

describe "HTML" do
  describe ".escape" do
    it "does not change a safe string" do
      str = HTML.escape("safe_string")

      assert str == "safe_string"
    end

    it "escapes dangerous characters from a string" do
      str = HTML.escape("< & >")

      assert str == "&lt; &amp; &gt;"
    end

    it "escapes javascript example from a string" do
      str = HTML.escape("<script>alert('You are being hacked')</script>")

      assert str == "&lt;script&gt;alert&#40;&#39;You are being hacked&#39;&#41;&lt;/script&gt;"
    end

    it "escapes nonbreakable space but not normal space" do
      str = HTML.escape("nbsp space ")

      assert str == "nbsp&nbsp;space "
    end
  end
end
