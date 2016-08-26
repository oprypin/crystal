require "spec"

private def expect_overflow
  expect_raises ArgumentError, "Time::Span too big or too small" do
    yield
  end
end

describe Time::Span do
  it "initializes" do
    t1 = Time::Span.new 1234567890
    assert t1.to_s == "00:02:03.4567890"

    t1 = Time::Span.new 1, 2, 3
    assert t1.to_s == "01:02:03"

    t1 = Time::Span.new 1, 2, 3, 4
    assert t1.to_s == "1.02:03:04"

    t1 = Time::Span.new 1, 2, 3, 4, 5
    assert t1.to_s == "1.02:03:04.0050000"

    t1 = Time::Span.new -1, 2, -3, 4, -5
    assert t1.to_s == "-22:02:56.0050000"

    t1 = Time::Span.new 0, 25, 0, 0, 0
    assert t1.to_s == "1.01:00:00"
  end

  it "days overflows" do
    expect_overflow do
      days = (Int64::MAX / Time::Span::TicksPerDay).to_i32 + 1
      Time::Span.new days, 0, 0, 0, 0
    end
  end

  it "max days" do
    expect_overflow do
      Int32::MAX.days
    end
  end

  it "min days" do
    expect_overflow do
      Int32::MIN.days
    end
  end

  it "max seconds" do
    ts = Int32::MAX.seconds
    assert ts.days == 24855
    assert ts.hours == 3
    assert ts.minutes == 14
    assert ts.seconds == 7
    assert ts.milliseconds == 0
    assert ts.ticks == 21474836470000000
  end

  it "min seconds" do
    ts = Int32::MIN.seconds
    assert ts.days == -24855
    assert ts.hours == -3
    assert ts.minutes == -14
    assert ts.seconds == -8
    assert ts.milliseconds == 0
    assert ts.ticks == -21474836480000000
  end

  it "max milliseconds" do
    ts = Int32::MAX.milliseconds
    assert ts.days == 24
    assert ts.hours == 20
    assert ts.minutes == 31
    assert ts.seconds == 23
    assert ts.milliseconds == 647
    assert ts.ticks == 21474836470000
  end

  it "min milliseconds" do
    ts = Int32::MIN.milliseconds
    assert ts.days == -24
    assert ts.hours == -20
    assert ts.minutes == -31
    assert ts.seconds == -23
    assert ts.milliseconds == -648
    assert ts.ticks == -21474836480000
  end

  it "negative timespan" do
    ts = Time::Span.new -23, -59, -59
    assert ts.days == 0
    assert ts.hours == -23
    assert ts.minutes == -59
    assert ts.seconds == -59
    assert ts.milliseconds == 0
    assert ts.ticks == -863990000000
  end

  it "test properties" do
    t1 = Time::Span.new 1, 2, 3, 4, 5
    t2 = -t1

    assert t1.days == 1
    assert t1.hours == 2
    assert t1.minutes == 3
    assert t1.seconds == 4
    assert t1.milliseconds == 5

    assert t2.days == -1
    assert t2.hours == -2
    assert t2.minutes == -3
    assert t2.seconds == -4
    assert t2.milliseconds == -5
  end

  it "test add" do
    t1 = Time::Span.new 2, 3, 4, 5, 6
    t2 = Time::Span.new 1, 2, 3, 4, 5
    t3 = t1 + t2

    assert t3.days == 3
    assert t3.hours == 5
    assert t3.minutes == 7
    assert t3.seconds == 9
    assert t3.milliseconds == 11
    assert t3.to_s == "3.05:07:09.0110000"

    # TODO check overflow
  end

  it "test compare" do
    t1 = Time::Span.new -1
    t2 = Time::Span.new 1

    assert (t1 <=> t2) == -1
    assert (t2 <=> t1) == 1
    assert (t2 <=> t2) == 0
    assert (Time::Span::MinValue <=> Time::Span::MaxValue) == -1

    assert (t1 == t2) == false
    assert (t1 > t2) == false
    assert (t1 >= t2) == false
    assert (t1 != t2) == true
    assert (t1 < t2) == true
    assert (t1 <= t2) == true
  end

  it "test equals" do
    t1 = Time::Span.new 1
    t2 = Time::Span.new 2

    assert (t1 == t1) == true
    assert (t1 == t2) == false
    assert (t1 == "hello") == false
  end

  it "test float extension methods" do
    assert 12.345.days.to_s == "12.08:16:48"
    assert 12.345.hours.to_s == "12:20:42"
    assert 12.345.minutes.to_s == "00:12:20.7000000"
    assert 12.345.seconds.to_s == "00:00:12.3450000"
    assert 12.345.milliseconds.to_s == "00:00:00.0120000"
    assert -0.5.milliseconds.to_s == "-00:00:00.0010000"
    assert 0.5.milliseconds.to_s == "00:00:00.0010000"
    assert -2.5.milliseconds.to_s == "-00:00:00.0030000"
    assert 2.5.milliseconds.to_s == "00:00:00.0030000"
    assert 0.0005.seconds.to_s == "00:00:00.0010000"
  end

  it "test negate and duration" do
    assert (-Time::Span.new(12345)).to_s == "-00:00:00.0012345"
    assert Time::Span.new(-12345).duration.to_s == "00:00:00.0012345"
    assert Time::Span.new(-12345).abs.to_s == "00:00:00.0012345"
    assert (-Time::Span.new(77)).to_s == "-00:00:00.0000077"
    assert (+Time::Span.new(77)).to_s == "00:00:00.0000077"
  end

  it "test hash code" do
    assert Time::Span.new(77).hash == 77
  end

  it "test subtract" do
    t1 = Time::Span.new 2, 3, 4, 5, 6
    t2 = Time::Span.new 1, 2, 3, 4, 5
    t3 = t1 - t2

    assert t3.to_s == "1.01:01:01.0010000"

    # TODO check overflow
  end

  it "test multiply" do
    t1 = Time::Span.new 5, 4, 3, 2, 1
    t2 = t1 * 61

    assert t2 == Time::Span.new 315, 7, 5, 2, 61

    # TODO check overflow
  end

  it "test divide" do
    t1 = Time::Span.new 3, 3, 3, 3, 3
    t2 = t1 / 2

    assert t2 == Time::Span.new(1, 13, 31, 31, 501) + Time::Span.new(5000)

    # TODO check overflow
  end

  it "test to_s" do
    t1 = Time::Span.new 1, 2, 3, 4, 5
    t2 = -t1

    assert t1.to_s == "1.02:03:04.0050000"
    assert t2.to_s == "-1.02:03:04.0050000"
    assert Time::Span::MaxValue.to_s == "10675199.02:48:05.4775807"
    assert Time::Span::MinValue.to_s == "-10675199.02:48:05.4775808"
    assert Time::Span::Zero.to_s == "00:00:00"
  end

  it "test totals" do
    t1 = Time::Span.new 1, 2, 3, 4, 5
    assert t1.total_days.close?(1.08546, 1e-05)
    assert t1.total_hours.close?(26.0511, 1e-04)
    assert t1.total_minutes.close?(1563.07, 1e-02)
    assert t1.total_seconds.close?(93784, 1e-01)
    assert t1.total_milliseconds.close?(9.3784e+07, 1e+01)
    assert t1.to_f.close?(93784, 1e-01)
    assert t1.to_i == 93784
  end
end
