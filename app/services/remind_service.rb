require 'date'
require_relative '../models/reminder'
require_relative '../models/channel'

class RemindService
    
    def initialize(today = DateTime.now, reminder_model = Reminder, channel_model = Channel)
        @today = today
        @reminder_model = reminder_model
        @channel_model = channel_model
    end

    def check_reminders
        gen_debug_log("Checking reminder")
        gen_debug_log(@today.to_s)
        @reminder_model.find_each do |reminder|
            if datetime_equals(reminder)
                exec_reminder(reminder)
                reminder.destroy
            end
        end
    end

    private

    def datetime_equals(reminder)
        year = reminder.remind_day.year
        month = reminder.remind_day.mon
        day = reminder.remind_day.mday
        hour = reminder.remind_day.hour
        min = reminder.remind_day.min
    
        if year == @today.year && month == @today.month && day == @today.day && hour == @today.hour
            if @today.min - min >= 0 && @today.min - min < 10 # 10分未満の誤差は許容(Heroku Schedulerの不安定性を考慮)
                return true
            end
        end
        return false
    end

    def exec_reminder(reminder)
        rem_day = reminder.remind_day.to_s
        msg = reminder.comment
        gen_debug_log("Execute #{rem_day} Comment: #{msg}")
        channel = @channel_model.find_by(index: 'reminder').ch_id
        slack_client.send_msg(channel, msg)
    end

    def slack_client
        @slack_client ||= Client::SlackClient.new
    end

    def gen_debug_log(str)
        puts "[remind service]: #{str}"
    end

end
