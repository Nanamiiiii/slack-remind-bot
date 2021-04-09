class SlackController < ApplicationController

    SLACK_SIGNING_SECRET = ENV['SLACK_SIGNING_SECRET']

    # POST /
    def index
        # Nothing to do
    end

    # POST /commands
    def commands
        # slash command
        # verify message
        request_body = request.body.read
        timestamp = request.headers['X-Slack-Request-Timestamp']
        signature = request.headers['X-Slack-Signature']
        sig_base = "v0:#{timestamp}:#{request_body}"
        this_sig = OpenSSL::HMAC.hexdigest('sha256', SLACK_SIGNING_SECRET, sig_base)
        if !(signature.eql?("v0=#{this_sig}"))
            # verification error
            render :status => 404
            return
        end

        # decode to [key, value] array
        req = URI.decode_www_form(request_body)
        logger.info(req)
        # execute command service
        command_service.execute(req)
    end

    # POST /interact
    def interact
        # action from interactive element
        # verify
        request_body = request.body.read
        timestamp = request.headers['X-Slack-Request-Timestamp']
        signature = request.headers['X-Slack-Signature']
        sig_base = "v0:#{timestamp}:#{request_body}"
        this_sig = OpenSSL::HMAC.hexdigest('sha256', SLACK_SIGNING_SECRET, sig_base)
        if !(signature.eql?("v0=#{this_sig}"))
            # verification error
            render :status => 404
            return
        end

        # decode to [key, value] array
        dec_json = URI.decode_www_form(request_body)

        # parse key:"payload" value
        parsed_json = JSON.parse(dec_json.assoc('payload').last, symbolize_names: true)
        logger.info(parsed_json)

        # execute interact process
        case parsed_json[:type]
        # action from elements in block such as button
        when 'block_actions'
            interact_service.block_execute(parsed_json)

        # action from modal form
        when 'view_submission'
            interact_service.modal_execute(parsed_json)
        end
    
    end

    # POST /event
    def event
        body = JSON.parse(request.body.read)

        case body['type']
        when 'url_verification'
            render json: body
        when 'event_callback'
            
        end
    end

    def remind_service
        RemindService.new
    end

    def command_service
        CommandService.new
    end

    def interact_service
        InteractService.new
    end

    def slack_client
        @slack_client ||= Client::SlackClient.new()
    end

end
