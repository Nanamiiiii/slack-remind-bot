require 'date'
require_relative '../models/weekly'
require_relative '../models/message'

class CommandService

    VERIFY_WITH_PORTAL = ENV['VERIFY_WITH_PORTAL']

    def initialize(weekly_model = Weekly, message_model = Message)
        @weekly_model = weekly_model
        @message_model = message_model
    end

    def execute(req)
        # get some param from [key, value] array
        @req = req

        raw_text = @req.assoc('text').last.split(" ")
        user_id = @req.assoc('user_id').last
        user_name = @req.assoc('user_name').last
        channel = @req.assoc('channel_id').last
        trg_id = @req.assoc('trigger_id').last

        # user certification
        if !(user_verification(user_id))
            gen_debug_log("Setting regular reminder: Not certificated user")
            err_ret(0, user_id)
            return
        end

        # give modal view to select command
        block = gen_command_view
        # if valid timestamp exists, update message
        if (message = @message_model.find_by(userid: user_id)).present?
            if !(message.t_stamp.nil?)
                response = slack_client.update_message(channel, message.t_stamp, '', block)
            else
                response = slack_client.send_block(user_id, block)
            end
        else
            response = slack_client.send_block(user_id, block)
        end

        # get and store timestamp
        ts = response["ts"]
        set_last_timestamp(ts, user_id)
    end

    private

    def gen_command_view
        # generate modal view
        blocks = [
            {
                :type => "section",
                :text => {
                    :type => "plain_text",
                    :text => "何をしますか？",
                    :emoji => true
                }
            },
            {
                :type => "actions",
                :elements => [
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "定期通知追加",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "add_weekly"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "臨時通知追加",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "add_temp"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "定期設定確認",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "show_weekly"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "キュー確認",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "check_q"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "投稿窓設定",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "set_ch"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "キャンセル",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "cancel_command",
                        :style => "danger"
                    }
                ]
            }
        ]
        return blocks
    end

    def set_last_timestamp(ts, user_id)
        if (message = @message_model.find_by(userid: user_id)).present?
            message.update(t_stamp: ts)
        else
            @message_model.create(userid: user_id, t_stamp: ts)
        end
    end

    def user_verification(user_id)
        if VERIFY_WITH_PORTAL == 0
            return true
        end
        # user verification
        user_role = portal_client.check_user_role(user_id)
        if user_role == 'admin'
            return true
        else
            return false
        end
    end

    def err_ret(num, channel)
        # send errors
        case num
        when 0
            msg = 'Error: 権限がありません．'
        when 1
            msg = 'Error: 無効な引数です．'
        end
        slack_client.send_msg(channel, msg)
    end

    def slack_client
        @slack_client ||= Client::SlackClient.new()
    end

    def portal_client
        @portal_client ||= Client::PortalClient.new()
    end

    def get_time_s(hour, min)
        # generate time string
        if hour/10 == 0
            hour_s = "0#{hour}"
        else
            hour_s = "#{hour}"
        end
    
        if min/10 == 0
            min_s = "0#{min}"
        else
            min_s = "#{min}"
        end
    
        return "#{hour_s}:#{min_s}"
    end

    def gen_debug_log(str)
        puts "[command service]: #{str}"
    end

end