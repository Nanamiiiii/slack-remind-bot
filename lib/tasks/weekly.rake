task :weekly_task => :environment do
    weekly_service = WeeklyService.new
    weekly_service.reminder
end