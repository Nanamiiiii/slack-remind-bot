require 'date'
require_relative '../models/user'
require_relative '../models/weekly'

class CommandService

    def initialize(weekly_model = Weekly, user_model = User)
        @weekly_model = weekly_model
        @user_model = user_model
    end

    def execute(req)
        
        # get some param from [key, value] array
        @req = req

        raw_text = @req.assoc('text').last.split(" ")
        user_id = @req.assoc('user_id').last
        user_name = @req.assoc('user_name').last
        channel = @req.assoc('channel_id').last
        trg_id = @req.assoc('trigger_id').last

        case raw_text[0]
        when 'regist'
            # user registration
            # template: /command regist

            if !(certificate_without_v(user_id))
                # user not exist
                @user_model.create(slack_id: user_id, valid_user: false)
                msg = "`#{user_name}`を登録しました．管理者による有効化後に利用できます．"
            else
                # prevent multiple registration
                msg = 'Error: すでに登録ユーザーです．'
            end

            # reply
            slack_client.send_msg(user_id, msg)

        when 'regular'
            # set regular reminder
            # template: /command regular

            # user certification
            if !(certificate(user_id))
                puts '# Setting regular reminder: Not certificated user'
                err_ret(0, channel)
                return
            end
            
            views = gen_add_view
            slack_client.send_view(trg_id, views)

        when 'verify'
            # TODO: list uncertificated user
        when 'show'
            # show remind schedule (now only regular sc)
            # user certification
            if !(certificate(user_id))
                puts '[command_service] Setting regular reminder: Not certificated user'
                err_ret(0, channel)
                return
            end

            # check the number of reminder
            if @weekly_model.all.length == 0
                block = [
                    {
                        :type => "section",
                        :text => {
                            :type => "plain_text",
                            :text => "リマインダーは設定されていません．",
                            :emoji => true
                        }
                    }
                ]
                slack_client.send_block(channel, block)
                return
            end

            block = gen_remind_list
            slack_client.send_block(user_id, block)

        else
            # user certification
            if !(certificate(user_id))
                puts '[command_service] Setting regular reminder: Not certificated user'
                err_ret(0, channel)
                return
            end
            # give modal view to select command
            block = gen_command_view
            slack_client.send_block(user_id, block)
        end

    end

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
                            :text => "定期リマインド",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "add_weekly"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "設定確認",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "show_weekly"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "臨時リマインド",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "add_temp"
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
                            :text => "投稿窓",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "set_ch"
                    }
                ]
            }
        ]
        return blocks
    end

    

    def get_wday_string(wday)
        case wday
        when 0
            wday_s = 'Sun'
        when 1
            wday_s = 'Mon'
        when 2
            wday_s = 'Tue'
        when 3
            wday_s = 'Wed'
        when 4
            wday_s = 'Thu'
        when 5
            wday_s = 'Fri'
        when 6
            wday_s = 'Sat'
        end

        return wday_s
    end

    def get_wday_jp(wday)
        case wday
        when 0
            wday_s = '日曜日'
        when 1
            wday_s = '月曜日'
        when 2
            wday_s = '火曜日'
        when 3
            wday_s = '水曜日'
        when 4
            wday_s = '木曜日'
        when 5
            wday_s = '金曜日'
        when 6
            wday_s = '土曜日'
        end

        return wday_s
    end

    def certificate(user_id)
        # user certification
        @user_model.find_each do |model|
            if user_id == model.slack_id && model.valid_user
                return true
            end
        end

        return false
    end

    def certificate_without_v(user_id)
        # user certification without validation
        @user_model.find_each do |model|
            if user_id == model.slack_id
                return true
            end
        end

        return false
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

end