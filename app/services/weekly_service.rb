require 'date'
require_relative '../models/weekly'

class WeeklyService
  def initialize(weekly_model = Weekly)
    @weekly_model = weekly_model
  end

  def reminder(today)
    gen_debug_log(today)
    day_of_week = today.wday
    now_hour = today.hour
    now_minute = today.min

    ret = []

    @weekly_model.find_each do |model|
      
      remind_day = model.day
      sc_h = model.remind_time.hour
      sc_m = model.remind_time.min
      offset = model.offset
      place = model.place
      
      rem_h = sc_h - offset
      if rem_h < 0
        rem_h += 24
        day_of_week -= 1
      end

      time_s = get_time_s(sc_h, sc_m)

      if day_of_week == remind_day && now_hour == rem_h
        ret << "<!channel> 今日の活動は `#{time_s}` から `#{place}` だよっ！"
      end
    end

    return ret
    
  end

  def get_time_s(hour, min)
    # generate time string
    if hour/10 == 0
      hour_s = "0#{hour}"
    else
      hour_s = "#{hour}"
    end

    if min/10 == 0
      min_s = "0#{min}"
    else
      min_s = "#{min}"
    end

    return "#{hour_s}:#{min_s}"
  end

  def gen_debug_log(str)
    puts "[weekly service]: #{str}"
  end

end
