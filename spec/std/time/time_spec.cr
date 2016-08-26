require "spec"

TimeSpecTicks = [
  631501920000000000_i64, # 25 Feb 2002 - 00:00:00
  631502475130080000_i64, # 25 Feb 2002 - 15:25:13,8
  631502115130080000_i64, # 25 Feb 2002 - 05:25:13,8
]

def Time.expect_invalid
  expect_raises ArgumentError, "invalid time" do
    yield
  end
end

describe Time do
  it "initialize" do
    t1 = Time.new 2002, 2, 25
    assert t1.ticks == TimeSpecTicks[0]

    t2 = Time.new 2002, 2, 25, 15, 25, 13, 8
    assert t2.ticks == TimeSpecTicks[1]

    assert t2.date.ticks == TimeSpecTicks[0]
    assert t2.year == 2002
    assert t2.month == 2
    assert t2.day == 25
    assert t2.hour == 15
    assert t2.minute == 25
    assert t2.second == 13
    assert t2.millisecond == 8

    t3 = Time.new 2002, 2, 25, 5, 25, 13, 8
    assert t3.ticks == TimeSpecTicks[2]
  end

  it "initialize max" do
    assert Time.new(9999, 12, 31, 23, 59, 59, 999).ticks == 3155378975999990000
  end

  it "initialize millisecond negative" do
    Time.expect_invalid do
      Time.new(9999, 12, 31, 23, 59, 59, -1)
    end
  end

  it "initialize millisecond 1000" do
    Time.expect_invalid do
      Time.new(9999, 12, 31, 23, 59, 59, 1000)
    end
  end

  it "initialize with .epoch" do
    seconds = 1439404155
    time = Time.epoch(seconds)
    assert time == Time.new(2015, 8, 12, 18, 29, 15, kind: Time::Kind::Utc)
    assert time.epoch == seconds
  end

  it "initialize with .epoch_ms" do
    milliseconds = 1439404155000
    time = Time.epoch_ms(milliseconds)
    assert time == Time.new(2015, 8, 12, 18, 29, 15, kind: Time::Kind::Utc)
    assert time.epoch_ms == milliseconds
  end

  it "fields" do
    assert Time::MaxValue.ticks == 3155378975999999999
    assert Time::MinValue.ticks == 0
  end

  it "add" do
    t1 = Time.new TimeSpecTicks[1]
    span = Time::Span.new 3, 54, 1
    t2 = t1 + span

    assert t2.day == 25
    assert t2.hour == 19
    assert t2.minute == 19
    assert t2.second == 14

    assert t1.day == 25
    assert t1.hour == 15
    assert t1.minute == 25
    assert t1.second == 13
  end

  it "add out of range 1" do
    t1 = Time.new TimeSpecTicks[1]

    expect_raises ArgumentError do
      t1 + Time::Span::MaxValue
    end
  end

  it "add out of range 2" do
    t1 = Time.new TimeSpecTicks[1]

    expect_raises ArgumentError do
      t1 + Time::Span::MinValue
    end
  end

  it "add days" do
    t1 = Time.new TimeSpecTicks[1]
    t1 = t1 + 3.days

    assert t1.day == 28
    assert t1.hour == 15
    assert t1.minute == 25
    assert t1.second == 13

    t1 = t1 + 1.9.days
    assert t1.day == 2
    assert t1.hour == 13
    assert t1.minute == 1
    assert t1.second == 13

    t1 = t1 + 0.2.days
    assert t1.day == 2
    assert t1.hour == 17
    assert t1.minute == 49
    assert t1.second == 13
  end

  it "add days out of range 1" do
    t1 = Time.new TimeSpecTicks[1]
    expect_raises ArgumentError do
      t1 + 10000000.days
    end
  end

  it "add days out of range 2" do
    t1 = Time.new TimeSpecTicks[1]
    expect_raises ArgumentError do
      t1 - 10000000.days
    end
  end

  it "add months" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    t2 = t + 1.month
    assert t2.to_s == "2014-11-30 21:18:13"

    t2 = t + 1.months
    assert t2.to_s == "2014-11-30 21:18:13"

    t = Time.new 2014, 10, 31, 21, 18, 13
    t2 = t + 1.month
    assert t2.to_s == "2014-11-30 21:18:13"

    t = Time.new 2014, 10, 31, 21, 18, 13
    t2 = t - 1.month
    assert t2.to_s == "2014-09-30 21:18:13"
  end

  it "add years" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    t2 = t + 1.year
    assert t2.to_s == "2015-10-30 21:18:13"

    t = Time.new 2014, 10, 30, 21, 18, 13
    t2 = t - 2.years
    assert t2.to_s == "2012-10-30 21:18:13"
  end

  it "add hours" do
    t1 = Time.new TimeSpecTicks[1]
    t1 = t1 + 10.hours

    assert t1.day == 26
    assert t1.hour == 1
    assert t1.minute == 25
    assert t1.second == 13

    t1 = t1 - 3.7.hours
    assert t1.day == 25
    assert t1.hour == 21
    assert t1.minute == 43
    assert t1.second == 13

    t1 = t1 + 3.732.hours
    assert t1.day == 26
    assert t1.hour == 1
    assert t1.minute == 27
    assert t1.second == 8
  end

  it "add milliseconds" do
    t1 = Time.new TimeSpecTicks[1]
    t1 = t1 + 1e10.milliseconds

    assert t1.day == 21
    assert t1.hour == 9
    assert t1.minute == 11
    assert t1.second == 53

    t1 = t1 - 19e10.milliseconds
    assert t1.day == 13
    assert t1.hour == 7
    assert t1.minute == 25
    assert t1.second == 13

    t1 = t1 + 15.623.milliseconds
    assert t1.day == 13
    assert t1.hour == 7
    assert t1.minute == 25
    assert t1.second == 13
  end

  it "gets time of day" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    assert t.time_of_day == Time::Span.new(21, 18, 13)
  end

  it "gets day of week" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    assert t.day_of_week == Time::DayOfWeek::Thursday
  end

  it "gets day of year" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    assert t.day_of_year == 303
  end

  it "compares" do
    t1 = Time.new 2014, 10, 30, 21, 18, 13
    t2 = Time.new 2014, 10, 30, 21, 18, 14

    assert (t1 <=> t2) == -1
    assert (t1 == t2) == false
    assert (t1 < t2) == true
  end

  it "gets unix epoch seconds" do
    t1 = Time.new 2014, 10, 30, 21, 18, 13, 0, Time::Kind::Utc
    assert t1.epoch == 1414703893
    assert t1.epoch_f.close?(1414703893, 1e-01)
  end

  it "gets unix epoch seconds at GMT" do
    t1 = Time.now
    assert t1.epoch == t1.to_utc.epoch
    assert t1.epoch_f.close?(t1.to_utc.epoch_f, 1e-01)
  end

  it "to_s" do
    t = Time.new 2014, 10, 30, 21, 18, 13
    assert t.to_s == "2014-10-30 21:18:13"

    t = Time.new 2014, 1, 30, 21, 18, 13
    assert t.to_s == "2014-01-30 21:18:13"

    t = Time.new 2014, 10, 1, 21, 18, 13
    assert t.to_s == "2014-10-01 21:18:13"

    t = Time.new 2014, 10, 30, 1, 18, 13
    assert t.to_s == "2014-10-30 01:18:13"

    t = Time.new 2014, 10, 30, 21, 1, 13
    assert t.to_s == "2014-10-30 21:01:13"

    t = Time.new 2014, 10, 30, 21, 18, 1
    assert t.to_s == "2014-10-30 21:18:01"
  end

  it "formats" do
    t = Time.new 2014, 1, 2, 3, 4, 5, 6
    t2 = Time.new 2014, 1, 2, 15, 4, 5, 6

    assert t.to_s("%Y") == "2014"
    assert Time.new(1, 1, 2, 3, 4, 5, 6).to_s("%Y") == "0001"

    assert t.to_s("%C") == "20"
    assert t.to_s("%y") == "14"
    assert t.to_s("%m") == "01"
    assert t.to_s("%_m") == " 1"
    assert t.to_s("%_%_m2") == "%_ 12"
    assert t.to_s("%-m") == "1"
    assert t.to_s("%-%-m2") == "%-12"
    assert t.to_s("%B") == "January"
    assert t.to_s("%^B") == "JANUARY"
    assert t.to_s("%^%^B2") == "%^JANUARY2"
    assert t.to_s("%b") == "Jan"
    assert t.to_s("%^b") == "JAN"
    assert t.to_s("%h") == "Jan"
    assert t.to_s("%^h") == "JAN"
    assert t.to_s("%d") == "02"
    assert t.to_s("%-d") == "2"
    assert t.to_s("%e") == " 2"
    assert t.to_s("%j") == "002"
    assert t.to_s("%H") == "03"

    assert t.to_s("%k") == " 3"
    assert t2.to_s("%k") == "15"

    assert t.to_s("%I") == "03"
    assert t2.to_s("%I") == "03"

    assert t.to_s("%l") == " 3"
    assert t2.to_s("%l") == " 3"

    # Note: we purposely match %p to am/pm and %P to AM/PM (makes more sense)
    assert t.to_s("%p") == "am"
    assert t2.to_s("%p") == "pm"

    assert t.to_s("%P") == "AM"
    assert t2.to_s("%P") == "PM"

    assert t.to_s("%M").to_s == "04"
    assert t.to_s("%S").to_s == "05"
    assert t.to_s("%L").to_s == "006"

    assert Time.utc_now.to_s("%z") == "+0000"
    assert Time.utc_now.to_s("%:z") == "+00:00"
    assert Time.utc_now.to_s("%::z") == "+00:00:00"

    # TODO %N
    # TODO %Z

    assert t.to_s("%A").to_s == "Thursday"
    assert t.to_s("%^A").to_s == "THURSDAY"
    assert t.to_s("%a").to_s == "Thu"
    assert t.to_s("%^a").to_s == "THU"
    assert t.to_s("%u").to_s == "4"
    assert t.to_s("%w").to_s == "4"

    t3 = Time.new 2014, 1, 5 # A Sunday
    assert t3.to_s("%u").to_s == "7"
    assert t3.to_s("%w").to_s == "0"

    # TODO %G
    # TODO %g
    # TODO %V
    # TODO %U
    # TODO %W
    # TODO %s
    # TODO %n
    # TODO %t
    # TODO %%

    assert t.to_s("%%") == "%"
    assert t.to_s("%c") == t.to_s("%a %b %e %T %Y")
    assert t.to_s("%D") == t.to_s("%m/%d/%y")
    assert t.to_s("%F") == t.to_s("%Y-%m-%d")
    # TODO %v
    assert t.to_s("%x") == t.to_s("%D")
    assert t.to_s("%X") == t.to_s("%T")
    assert t.to_s("%r") == t.to_s("%I:%M:%S %P")
    assert t.to_s("%R") == t.to_s("%H:%M")
    assert t.to_s("%T") == t.to_s("%H:%M:%S")

    assert t.to_s("%Y-%m-hello") == "2014-01-hello"

    t = Time.new 2014, 1, 2, 3, 4, 5, 6, kind: Time::Kind::Utc
    assert t.to_s("%s") == "1388631845"
  end

  it "parses empty" do
    t = Time.parse("", "")
    assert t.year == 1
    assert t.month == 1
    assert t.day == 1
    assert t.hour == 0
    assert t.minute == 0
    assert t.second == 0
    assert t.millisecond == 0
  end

  it { assert Time.parse("2014", "%Y").year == 2014 }
  it { assert Time.parse("19", "%C").year == 1900 }
  it { assert Time.parse("14", "%y").year == 2014 }
  it { assert Time.parse("09", "%m").month == 9 }
  it { assert Time.parse(" 9", "%_m").month == 9 }
  it { assert Time.parse("9", "%-m").month == 9 }
  it { assert Time.parse("February", "%B").month == 2 }
  it { assert Time.parse("March", "%B").month == 3 }
  it { assert Time.parse("MaRcH", "%B").month == 3 }
  it { assert Time.parse("MaR", "%B").month == 3 }
  it { assert Time.parse("MARCH", "%^B").month == 3 }
  it { assert Time.parse("Mar", "%b").month == 3 }
  it { assert Time.parse("Mar", "%^b").month == 3 }
  it { assert Time.parse("MAR", "%^b").month == 3 }
  it { assert Time.parse("MAR", "%h").month == 3 }
  it { assert Time.parse("MAR", "%^h").month == 3 }
  it { assert Time.parse("2", "%d").day == 2 }
  it { assert Time.parse("02", "%d").day == 2 }
  it { assert Time.parse("02", "%-d").day == 2 }
  it { assert Time.parse(" 2", "%e").day == 2 }
  it { assert Time.parse("9", "%H").hour == 9 }
  it { assert Time.parse(" 9", "%k").hour == 9 }
  it { assert Time.parse("09", "%I").hour == 9 }
  it { assert Time.parse(" 9", "%l").hour == 9 }
  it { assert Time.parse("9pm", "%l%p").hour == 21 }
  it { assert Time.parse("9PM", "%l%P").hour == 21 }
  it { assert Time.parse("09", "%M").minute == 9 }
  it { assert Time.parse("09", "%S").second == 9 }
  it { assert Time.parse("123", "%L").millisecond == 123 }
  it { assert Time.parse("Fri Oct 31 23:00:24 2014", "%c").to_s == "2014-10-31 23:00:24" }
  it { assert Time.parse("10/31/14", "%D").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("10/31/69", "%D").to_s == "1969-10-31 00:00:00" }
  it { assert Time.parse("2014-10-31", "%F").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("2014-10-31", "%F").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("10/31/14", "%x").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("10:11:12", "%X").to_s == "0001-01-01 10:11:12" }
  it { assert Time.parse("11:14:01 PM", "%r").to_s == "0001-01-01 23:14:01" }
  it { assert Time.parse("11:14", "%R").to_s == "0001-01-01 11:14:00" }
  it { assert Time.parse("11:12:13", "%T").to_s == "0001-01-01 11:12:13" }
  it { assert Time.parse("This was done on Friday, October 31, 2014", "This was done on %A, %B %d, %Y").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("今は Friday, October 31, 2014", "今は %A, %B %d, %Y").to_s == "2014-10-31 00:00:00" }
  it { assert Time.parse("epoch: 1459864667", "epoch: %s").epoch == 1459864667 }
  it { assert Time.parse("epoch: -1459864667", "epoch: %s").epoch == -1459864667 }

  # TODO %N
  # TODO %Z
  # TODO %G
  # TODO %g
  # TODO %V
  # TODO %U
  # TODO %W
  # TODO %s
  # TODO %n
  # TODO %t
  # TODO %%
  # TODO %v

  it do
    time = Time.parse("2014-10-31 10:11:12 Z hi", "%F %T %z hi")
    assert time.utc? == true
    assert time.to_utc.to_s == "2014-10-31 10:11:12 UTC"
  end

  it do
    time = Time.parse("2014-10-31 10:11:12 UTC hi", "%F %T %z hi")
    assert time.utc? == true
    assert time.to_utc.to_s == "2014-10-31 10:11:12 UTC"
  end

  it do
    time = Time.parse("2014-10-31 10:11:12 -06:00 hi", "%F %T %z hi")
    assert time.local? == true
    assert time.to_utc.to_s == "2014-10-31 16:11:12 UTC"
  end

  it do
    time = Time.parse("2014-10-31 10:11:12 +05:00 hi", "%F %T %z hi")
    assert time.local? == true
    assert time.to_utc.to_s == "2014-10-31 05:11:12 UTC"
  end

  it do
    time = Time.parse("2014-10-31 10:11:12 -06:00:00 hi", "%F %T %z hi")
    assert time.local? == true
    assert time.to_utc.to_s == "2014-10-31 16:11:12 UTC"
  end

  it do
    time = Time.parse("2014-10-31 10:11:12 -060000 hi", "%F %T %z hi")
    assert time.local? == true
    assert time.to_utc.to_s == "2014-10-31 16:11:12 UTC"
  end

  it "parses the correct amount of digits (#853)" do
    time = Time.parse("20150624", "%Y%m%d")
    assert time.year == 2015
    assert time.month == 6
    assert time.day == 24
  end

  it "parses month blank padded" do
    time = Time.parse("2015 624", "%Y%_m%d")
    assert time.year == 2015
    assert time.month == 6
    assert time.day == 24
  end

  it "parses day of month blank padded" do
    time = Time.parse("201506 4", "%Y%m%e")
    assert time.year == 2015
    assert time.month == 6
    assert time.day == 4
  end

  it "parses hour 24 blank padded" do
    time = Time.parse(" 31112", "%k%M%S")
    assert time.hour == 3
    assert time.minute == 11
    assert time.second == 12
  end

  it "parses hour 12 blank padded" do
    time = Time.parse(" 31112", "%l%M%S")
    assert time.hour == 3
    assert time.minute == 11
    assert time.second == 12
  end

  it "can parse in UTC" do
    time = Time.parse("2014-10-31 11:12:13", "%F %T", Time::Kind::Utc)
    assert time.kind == Time::Kind::Utc
  end

  it "at" do
    t1 = Time.new 2014, 11, 25, 10, 11, 12, 13
    t2 = Time.new 2014, 6, 25, 10, 11, 12, 13

    assert t1.at_beginning_of_year.to_s == "2014-01-01 00:00:00"

    1.upto(3) do |i|
      assert Time.new(2014, i, 10).at_beginning_of_quarter.to_s == "2014-01-01 00:00:00"
      assert Time.new(2014, i, 10).at_end_of_quarter.to_s == "2014-03-31 23:59:59"
    end
    4.upto(6) do |i|
      assert Time.new(2014, i, 10).at_beginning_of_quarter.to_s == "2014-04-01 00:00:00"
      assert Time.new(2014, i, 10).at_end_of_quarter.to_s == "2014-06-30 23:59:59"
    end
    7.upto(9) do |i|
      assert Time.new(2014, i, 10).at_beginning_of_quarter.to_s == "2014-07-01 00:00:00"
      assert Time.new(2014, i, 10).at_end_of_quarter.to_s == "2014-09-30 23:59:59"
    end
    10.upto(12) do |i|
      assert Time.new(2014, i, 10).at_beginning_of_quarter.to_s == "2014-10-01 00:00:00"
      assert Time.new(2014, i, 10).at_end_of_quarter.to_s == "2014-12-31 23:59:59"
    end

    assert t1.at_beginning_of_quarter.to_s == "2014-10-01 00:00:00"
    assert t1.at_beginning_of_month.to_s == "2014-11-01 00:00:00"

    3.upto(9) do |i|
      assert Time.new(2014, 11, i).at_beginning_of_week.to_s == "2014-11-03 00:00:00"
    end

    assert t1.at_beginning_of_day.to_s == "2014-11-25 00:00:00"
    assert t1.at_beginning_of_hour.to_s == "2014-11-25 10:00:00"
    assert t1.at_beginning_of_minute.to_s == "2014-11-25 10:11:00"

    assert t1.at_end_of_year.to_s == "2014-12-31 23:59:59"

    assert t1.at_end_of_quarter.to_s == "2014-12-31 23:59:59"
    assert t2.at_end_of_quarter.to_s == "2014-06-30 23:59:59"

    assert t1.at_end_of_month.to_s == "2014-11-30 23:59:59"
    assert t1.at_end_of_week.to_s == "2014-11-30 23:59:59"

    assert Time.new(2014, 11, 2).at_end_of_week.to_s == "2014-11-02 23:59:59"
    3.upto(9) do |i|
      assert Time.new(2014, 11, i).at_end_of_week.to_s == "2014-11-09 23:59:59"
    end

    assert t1.at_end_of_day.to_s == "2014-11-25 23:59:59"
    assert t1.at_end_of_hour.to_s == "2014-11-25 10:59:59"
    assert t1.at_end_of_minute.to_s == "2014-11-25 10:11:59"

    assert t1.at_midday.to_s == "2014-11-25 12:00:00"

    assert t1.at_beginning_of_semester.to_s == "2014-07-01 00:00:00"
    assert t2.at_beginning_of_semester.to_s == "2014-01-01 00:00:00"

    assert t1.at_end_of_semester.to_s == "2014-12-31 23:59:59"
    assert t2.at_end_of_semester.to_s == "2014-06-30 23:59:59"
  end

  it "does time span units" do
    assert 1.millisecond.ticks == Time::Span::TicksPerMillisecond
    assert 1.milliseconds.ticks == Time::Span::TicksPerMillisecond
    assert 1.second.ticks == Time::Span::TicksPerSecond
    assert 1.seconds.ticks == Time::Span::TicksPerSecond
    assert 1.minute.ticks == Time::Span::TicksPerMinute
    assert 1.minutes.ticks == Time::Span::TicksPerMinute
    assert 1.hour.ticks == Time::Span::TicksPerHour
    assert 1.hours.ticks == Time::Span::TicksPerHour
    assert 1.week == 7.days
    assert 2.weeks == 14.days
  end

  it "preserves kind when adding" do
    time = Time.utc_now
    assert time.kind == Time::Kind::Utc

    assert (time + 5.minutes).kind == Time::Kind::Utc
  end

  it "asks for day name" do
    7.times do |i|
      time = Time.new(2015, 2, 15 + i)
      assert time.sunday? == (i == 0)
      assert time.monday? == (i == 1)
      assert time.tuesday? == (i == 2)
      assert time.wednesday? == (i == 3)
      assert time.thursday? == (i == 4)
      assert time.friday? == (i == 5)
      assert time.saturday? == (i == 6)
    end
  end

  it "compares different kinds" do
    time = Time.now
    assert (time.to_utc <=> time) == 0
  end

  it %(changes timezone with ENV["TZ"]) do
    old_tz = ENV["TZ"]?

    begin
      ENV["TZ"] = "America/New_York"
      offset1 = Time.local_offset_in_minutes

      ENV["TZ"] = "Europe/Berlin"
      offset2 = Time.local_offset_in_minutes

      assert offset1 != offset2
    ensure
      ENV["TZ"] = old_tz
    end
  end

  typeof(Time.now.year)
  typeof(1.minute.from_now.year)
  typeof(1.minute.ago.year)
  typeof(1.month.from_now.year)
  typeof(1.month.ago.year)
  typeof(Time.now.to_utc)
  typeof(Time.now.to_local)
end
