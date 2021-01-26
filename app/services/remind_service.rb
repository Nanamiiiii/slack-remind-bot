require 'date'
class RemindService
  def initialize(today = DateTime.now, weekly_service = WeeklyService.new)
    @today = today
    @weekly_service = weekly_service
  end

  def check_reminders
    reminders = []

    weekly_reminder = check_weekly_reminder

    reminders << weekly_reminder if weekly_reminder.present?

    reminders
  end

  def check_weekly_reminder
    @weekly_service.reminder(@today)
  end

end
