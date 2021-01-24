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
end
