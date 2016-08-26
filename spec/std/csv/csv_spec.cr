require "spec"
require "csv"

private def new_csv(headers = false, strip = false)
  CSV.new %(one, two\n1, 2\n3, 4\n5), headers: headers, strip: strip
end

describe CSV do
  it "gets headers" do
    csv = new_csv headers: true
    assert csv.headers == %w(one two)
  end

  it "works without headers" do
    csv = CSV.new("", headers: true)
    assert csv.headers.empty? == true
  end

  it "raises if trying to access before first row" do
    csv = new_csv headers: true
    expect_raises(CSV::Error, "before first row") do
      csv["one"]
    end
  end

  it "gets row values with string" do
    csv = new_csv headers: true
    assert csv.next == true
    assert csv["one"] == "1"
    assert csv["two"] == " 2"

    expect_raises(KeyError) { csv["three"] }

    assert csv["one"]? == "1"
    assert csv["three"]?.nil?

    assert csv.next == true
    assert csv["one"] == "3"

    assert csv.next == true
    assert csv["one"] == "5"
    assert csv["two"] == ""

    assert csv.next == false

    expect_raises(CSV::Error, "after last row") do
      csv["one"]
    end
  end

  it "gets row values with integer" do
    csv = new_csv headers: true
    assert csv.next == true
    assert csv[0] == "1"
    assert csv[1] == " 2"

    expect_raises(IndexError) do
      csv[2]
    end

    assert csv[-1] == " 2"
    assert csv[-2] == "1"

    csv.next
    csv.next

    assert csv[0] == "5"
    assert csv[1] == ""
    assert csv[-2] == "5"
    assert csv[-1] == ""
  end

  it "gets row values with regex" do
    csv = new_csv headers: true
    assert csv.next == true

    assert csv[/on/] == "1"
    assert csv[/tw/] == " 2"

    expect_raises(KeyError) do
      csv[/foo/]
    end
  end

  it "gets current row" do
    csv = new_csv headers: true
    assert csv.next == true

    row = csv.row
    assert row["one"] == "1"
    assert row[1] == " 2"
    assert row[/on/] == "1"
    assert row.size == 2

    assert row.to_a == ["1", " 2"]
    assert row.to_h == {"one" => "1", "two" => " 2"}
  end

  it "strips" do
    csv = new_csv headers: true, strip: true
    assert csv.next == true

    assert csv["one"] == "1"
    assert csv["two"] == "2"

    assert csv.row.to_a == %w(1 2)
    assert csv.row.to_h == {"one" => "1", "two" => "2"}
  end

  it "works without headers" do
    csv = new_csv headers: false
    assert csv.next == true
    assert csv[0] == "one"
  end

  it "can do each" do
    csv = new_csv headers: true
    csv.each do
      assert csv["one"] == "1"
      break
    end
  end

  it "can do new with block" do
    CSV.new(%(one, two\n1, 2\n3, 4\n5), headers: true, strip: true) do |csv|
      assert csv["one"] == "1"
      assert csv["two"] == "2"
      break
    end
  end
end
