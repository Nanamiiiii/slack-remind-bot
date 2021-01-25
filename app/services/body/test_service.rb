module  Body
  class TestService
    def initialize(json)
        @json=json
    end
    def execute
      conn = Faraday::Connection.new(:url => 'https://slack.com') do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::Logger
        builder.use Faraday::Adapter::NetHttp
      end

      if @json[:event][:subtype] != "bot_message"
        body = {
          :token => ENV['SLACK_BOT_USER_TOKEN'],
          :channel => @json[:event][:channel],
          :text => "hoge hoge"
        }
        conn.post '/api/chat.postMessage', body.to_json, {"Content-type" => 'application/json', "Authorization" => "Bearer #{ENV['SLACK_BOT_USER_TOKEN']}"}
      end
    end
  end 
end
