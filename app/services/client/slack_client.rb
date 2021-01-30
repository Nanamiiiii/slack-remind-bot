module Client
  class SlackClient
    SLACK_BOT_USER_TOKEN = ENV['SLACK_BOT_USER_TOKEN']

    def initialize()
      @cli = Faraday::Connection.new(:url => 'https://slack.com') do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::Logger
        builder.response :json, :content_type => /\bjson$/
        builder.adapter Faraday::Adapter::NetHttp
      end
    end
    
    def send_msg(channel, msg)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :text => msg
      }
      response = @cli.post '/api/chat.postMessage', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
      return response
    end

    def send_block(channel, block)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :blocks => block
      }
      response = @cli.post '/api/chat.postMessage', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
      return response
    end

    def send_view(trg_id, view)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :trigger_id => trg_id,
        :view => view
      }
      @cli.post '/api/views.open', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
    end

    def update_message(channel, ts, msg, block)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :ts => ts,
        :text => msg,
        :blocks => block
      }
      response = @cli.post 'api/chat.update', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
      return response
    end

    def delete_message(channel, ts)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :ts => ts
      }
      @cli.post 'api/chat.delete', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
    end
  end
end
