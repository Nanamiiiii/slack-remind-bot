task :reminder_task => :environment do
    slack_controller = SlackController.new
    slack_controller.reminder
end