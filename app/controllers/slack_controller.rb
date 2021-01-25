class SlackController < ApplicationController
  def index
  end

  def create
    @body = JSON.parse(request.body.read)
    case @body['type']
    when 'url_verification'
      render json: @body
    when 'event_callback'
      # something
    end
    json_hash  = params[:slack]
    Body::TestService.new(json_hash).execute
  end

  def commands
    # slashコマンドの処理
  end

  def reminder
    reminders = get_reminders
    logger.info(reminders)
    
    Client::SlackClient.new()
    reminders.each do |reminder|
      Client::SlackClient.snd_msg('schedule', reminder)
    end
  end

  def get_reminders
    remind_service.check_reminder
  end

  def remind_service
    RemindService.new
  end

end
