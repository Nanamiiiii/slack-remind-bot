module Client
  class SlackClient
    SLACK_BOT_USER_TOKEN = ENV['SLACK_BOT_USER_TOKEN']

    def initialize()
      @cli = Faraday::Connection.new(:url => 'https://slack.com') do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::Logger
        builder.adapter Faraday::Adapter::NetHttp
      end
    end
    
    def send_msg(channel, msg)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :text => msg
      }
      @cli.post '/api/chat.postMessage', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
    end

    def send_block(channel, block)
      snd_data = {
        :token => SLACK_BOT_USER_TOKEN,
        :channel => channel,
        :blocks => block
      }
      @cli.post '/api/chat.postMessage', snd_data.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{SLACK_BOT_USER_TOKEN}"}
    end
    
  end
end
