class SlackController < ApplicationController

  # POST /
  def index
    # something
  end

  # POST /recieve (not in use)
  def create
    @body = JSON.parse(request.body.read)
    case @body['type']
    when 'url_verification'
      render json: @body
    when 'event_callback'
      # something
    end
    # json_hash  = params[:slack]
    # Body::TestService.new(json_hash).execute
  end

  # POST /commands
  def commands
    # slashコマンドの処理
    # @body = JSON.parse(request.body.read)
    # 投げられるのがうまくparseできないっぽいのでURIからデコード
    req = URI.decode_www_form(request.body.read)
    # TODO: リクエスト認証

    command_service.execute(req)

  end

  # POST /interact
  def interact
    # interaction element
    req = URI.decode_www_form(request.body.read)
    req2 = JSON.parse(req.assoc('payload').last)
    logger.info(req2)
  end

  # Rake Task: reminder check
  def reminder
    reminders = get_reminders
    logger.info(reminders)
    
    reminders.each do |reminder|
      slack_client.send_msg('schedule', reminder)
    end
  end

  def get_reminders
    remind_service.check_reminders
  end

  def remind_service
    RemindService.new
  end

  def command_service
    CommandService.new
  end

  def slack_client
    @slack_client ||= Client::SlackClient.new()
  end

end
