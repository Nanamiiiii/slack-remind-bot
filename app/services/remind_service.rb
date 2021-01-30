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
    @reminder_model.find_each do |reminder|
      if datetime_equals(reminder)
        exec_reminder(reminder)
      end
    end
  end

  def datetime_equals(reminder)
    year = reminder.remind_day.year
    month = reminder.remind_day.mon
    day = reminder.remind_day.mday
    hour = reminder.remind_day.hour
    min = reminder.remind_day.min

    if year == @today.year && month == @today.mon && day == @today.mday && hour == @today.hour
      if @today.min - min >= 0 && @today.min - min < 10
        return true
      end
    end

    return false
  end

  def exec_reminder(reminder)
    msg = reminder.comment
    channel = @channel_model.find_by('reminder').ch_id

    @slack_client.send_msg(channel, msg)
  end

  def slack_client
    @slack_client ||= Client::SlackClient.new
  end

end
