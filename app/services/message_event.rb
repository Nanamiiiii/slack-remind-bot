class MessageEvent

    def get_event(event)
        channel_id = event['channel']
        case channel_id
        when 'C04RXGB3N'
            # channel '#mis_e927'
            send_to_discord_e927(event)
        end
    end

    def send_to_discord_e927(event)
        user_id = event['user']
        msg = event['text']
        user_profile = slack_client.get_user_profile(user_id)

        user_name = user_profile['profile']['display_name']
        user_icon = user_profile['profile']['image_72']

        snd_data = {
            :username => user_name,
            :avatar_url => user_icon,
            :content => msg
        }

        discord_client.send_data_e927(snd_data)

    end

    def slack_client
        @slack_client ||= Client::SlackClient.new()
    end

    def discord_client
        @discord_client ||= Client::DiscordClient.new
    end
end