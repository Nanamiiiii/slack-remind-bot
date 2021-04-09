module Client
    class DiscordClient
        DISCORD_WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL']
        DISCORD_WEBHOOK_E927 = ENV['DISCORD_WEBHOOK_E927']
        
        def initialize()
            @cli = Faraday::Connection.new(:url => 'https://discordapp.com') do |builder|
                builder.use Faraday::Request::UrlEncoded
                builder.use Faraday::Response::Logger
                builder.adapter Faraday::Adapter::NetHttp
            end
        end

        def send_msg(msg)
            snd_data = {
                :content => msg
            }
            response = @cli.post DISCORD_WEBHOOK_URL, snd_data.to_json, {"Content-type" => 'application/json'}
            puts response.body
            return response.body
        end

        def send_data_e927(snd_data)
            response = @cli.post DISCORD_WEBHOOK_E927, snd_data.to_json, {"Content-type" => 'application/json'}
            puts response.body
            return response.body
        end
    end
end