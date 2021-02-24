require 'date'
require_relative '../models/weekly'
require_relative '../models/reminder'

class WeeklyService

    def initialize(weekly_model = Weekly, reminder_model = Reminder)
        @reminder_model = reminder_model
        @weekly_model = weekly_model
    end

    def reminder
        today = DateTime.now
        gen_debug_log(today)

        day_of_week = today.wday
        year = today.year
        month = today.mon
        mday = today.mday

        # execute only on Sunday
        if day_of_week != 0
            return
        end

        @weekly_model.find_each do |model|
            remind_day = model.day
            sc_h = model.remind_time.hour
            sc_m = model.remind_time.min
            offset = model.offset
            place = model.place
            
            rem_h = sc_h - offset
            if rem_h < 0
                rem_h += 24
                remind_day -= 1
                if remind_day < 0
                    remind_day += 7
                end
            end
      
            tmp_date = today + remind_day
            set_date = DateTime.new(tmp_date.year, tmp_date.month, tmp_date.day, rem_h, sc_m, 0) 
            time_s = get_time_s(sc_h, sc_m)
            comment = "<!channel> 今日の活動は `#{time_s}` から `#{place}` だよっ！"

            gen_debug_log(set_date.to_s)
            gen_debug_log(comment)

            set_reminder_record(set_date.to_s(:db), comment)
        end    
    end

    private
  
    def set_reminder_record(remind_day, comment)
        @reminder_model.create(remind_day: remind_day, comment: comment) 
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
