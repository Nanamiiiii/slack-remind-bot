require 'date'
require_relative '../models/weekly'

class WeeklyService
  def initialize(weekly_model = Weekly)
    @weekly_model = weekly_model
  end

  def reminder(today)
    puts today
    day_of_week = today.wday
    now_hour = today.hour
    now_minute = today.min

    @weekly_model.find_each do |model|
      puts model.remind_time
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

      if day_of_week == remind_day && now_hour == rem_h
        "@channel 今日の活動は`#{sc_h}:#{sc_m}`- `#{place}`です．"
      end
    end
  end

end
