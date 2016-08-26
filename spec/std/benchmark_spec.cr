require "spec"
require "benchmark"

# Make sure this compiles (#2578)
typeof(begin
  Benchmark.bm do |b|
    b.report("Here") { puts "Yes" }
  end
end)

describe Benchmark::IPS::Job do
  it "works in general / integration test" do
    # test several things to avoid running a benchmark over and over again in
    # the specs
    j = Benchmark::IPS::Job.new(0.001, 0.001, interactive: false)
    a = j.report("a") { sleep 0.001 }
    b = j.report("b") { sleep 0.002 }

    j.execute

    # the mean should be calculated
    assert a.mean > 10

    # one of the reports should be normalized to the fastest but do to the
    # timer precisison sleep 0.001 may not always be faster than 0.002 so we
    # don't care which
    first, second = [a.slower, b.slower].sort
    assert first == 1
    assert second > 1
  end
end

private def create_entry
  Benchmark::IPS::Entry.new("label", ->{ 1 + 1 })
end

describe Benchmark::IPS::Entry, "#set_cycles" do
  it "sets the number of cycles needed to make 100ms" do
    e = create_entry
    e.set_cycles(2.seconds, 100)
    assert e.cycles == 5

    e.set_cycles(100.milliseconds, 1)
    assert e.cycles == 1
  end

  it "sets the cycles to 1 no matter what" do
    e = create_entry
    e.set_cycles(2.seconds, 1)
    assert e.cycles == 1
  end
end

describe Benchmark::IPS::Entry, "#calculate_stats" do
  it "correctly caculates basic stats" do
    e = create_entry
    e.calculate_stats([2, 4, 4, 4, 5, 5, 7, 9])

    assert e.size == 8
    assert e.mean == 5.0
    assert e.variance == 4.0
    assert e.stddev == 2.0
  end
end

private def h_mean(mean)
  create_entry.tap { |e| e.mean = mean }.human_mean
end

describe Benchmark::IPS::Entry, "#human_mean" do
  it { assert h_mean(0.12345678901234) == "  0.12 " }

  it { assert h_mean(1.23456789012345) == "  1.23 " }
  it { assert h_mean(12.3456789012345) == " 12.35 " }
  it { assert h_mean(123.456789012345) == "123.46 " }

  it { assert h_mean(1234.56789012345) == "  1.23k" }
  it { assert h_mean(12345.6789012345) == " 12.35k" }
  it { assert h_mean(123456.789012345) == "123.46k" }

  it { assert h_mean(1234567.89012345) == "  1.23M" }
  it { assert h_mean(12345678.9012345) == " 12.35M" }
  it { assert h_mean(123456789.012345) == "123.46M" }

  it { assert h_mean(1234567890.12345) == "  1.23G" }
  it { assert h_mean(12345678901.2345) == " 12.35G" }
  it { assert h_mean(123456789012.345) == "123.46G" }
end
