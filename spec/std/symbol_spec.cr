require "spec"

describe Symbol do
  it "inspects" do
    assert :foo.inspect == %(:foo)
    assert :"{".inspect == %(:"{")
    assert :"hi there".inspect == %(:"hi there")
    # assert :かたな.inspect == %(:かたな)
  end
  it "can be compared with another symbol" do
    assert (:foo > :bar) == true
    assert (:foo < :bar) == false

    a = %i(q w e r t y u i o p a s d f g h j k l z x c v b n m)
    b = %i(a b c d e f g h i j k l m n o p q r s t u v w x y z)
    assert a.sort == b
  end

  it "displays symbols that don't need quotes without quotes" do
    a = %i(+ - * / == < <= > >= ! != =~ !~ & | ^ ~ ** >> << % [] <=> === []? []=)
    b = "[:+, :-, :*, :/, :==, :<, :<=, :>, :>=, :!, :!=, :=~, :!~, :&, :|, :^, :~, :**, :>>, :<<, :%, :[], :<=>, :===, :[]?, :[]=]"
    assert a.inspect == b
  end

  describe "clone" do
    it { assert :foo.clone == :foo }
  end
end
