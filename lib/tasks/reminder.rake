task :reminder_task => :environment do
    remind_service = RemindService.new
    remind_service.check_reminders
end