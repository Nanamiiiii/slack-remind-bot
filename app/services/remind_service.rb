require 'date'

class RemindService
  def initialize(today = DateTime.now, weekly_service = WeeklyService.new)
    @today = today
    @weekly_service = weekly_service
  end

  def check_reminders
    reminders = []

    weekly_reminder = check_weekly_reminder

    weekly_reminder.each do |reminder|
      reminders << reminder
    end

    return reminders
  end

  def check_weekly_reminder
    return @weekly_service.reminder(@today)
  end

end
