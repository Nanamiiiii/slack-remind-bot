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
            slack_client.send_msg(channel, msg)

        when 'regular'
            # set regular reminder
            # template: /command regular {day} {hour} {min} {offset} {place}

            # user certification
            if !(certificate(user_id))
                puts '# Setting regular reminder: Not certificated user'
                err_ret(0, channel)
                return
            end

            # argument check: number, type
            if raw_text.length != 6 || !(raw_text[1] =~ /^[0-9]+$/) || !(raw_text[2] =~ /^[0-9]+$/) || !(raw_text[3] =~ /^[0-9]+$/) || !(raw_text[4] =~ /^[0-9]+$/)
                puts '# Setting regular reminder: Argument number or type error'
                err_ret(1, channel)
                return
            end

            wday = raw_text[1].to_i
            hour = raw_text[2].to_i
            min = raw_text[3].to_i
            offset = raw_text[4].to_i
            place = raw_text[5]

            # argument check: range
            if wday < 0 || wday > 6 || hour < 0 || hour > 23 || min < 0 || min > 59
                puts '# Setting regular reminder: range error'
                err_ret(1, channel)
                return
            end

            remind_time = get_time_s(hour, min)
            @weekly_model.create(day: wday, remind_time: remind_time, offset: offset, place: place)
            
            wday_s = get_wday_string(wday)
            msg = "定期リマインドを `#{wday_s} - #{remind_time}` の `#{offset}時間前` に設定しました．"
            block = [
                {
                    :type => "section",
                    :text => {
                        :type => "mrkdwn",
                        :text => msg
                    }
                }
            ]
            slack_client.send_block(channel, block)

        when 'temp'
            #TODO: set temporary reminder
        when 'show'
            # show remind schedule (now only regular sc)

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

            # generate block kit object
            block = []
            divider = {
                :type => "divider"
            }

            @weekly_model.find_each do |model|
                id = model.id
                wday_s = get_wday_string(model.day)
                time_h = model.remind_time.hour
                time_m = model.remind_time.min
                offset = model.offset
                place = model.place

                time_s = get_time_s(time_h, time_m)

                section = {

                    :type => "section",
                    :fields => [
                        {
                            :type => "mrkdwn",
                            :text => "*ID:*\n#{id}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*曜日:*\n#{wday_s}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*時刻:*\n#{time_s}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*場所:*\n#{place}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*送信:*\n#{offset}時間前"
                        }
                    ]
                }

                buttons = {
                    :type => "actions",
                    :elements => [
                        {
                            :type => "button",
                            :text => {
                                :type => "plain_text",
                                :text => "削除",
                                :emoji => true
                            },
                            :value => "click_me_123",
                            :action_id => "delete_rec_#{id}"
                        },
                        {
                            :type => "button",
                            :text => {
                                :type => "plain_text",
                                :text => "編集",
                                :emoji => true
                            },
                            :value => "click_me_123",
                            :action_id => "modify_rec_#{id}"
                        }
                    ]
                }
                
                block << section
                block << buttons
                block << divider
            end

            slack_client.send_block(channel, block)

        else
            # invalid argument (give information)
            block = [
                {
                    :type => "section",
                    :text => {
                        :type => "plain_text",
                        :text => "引数のフォーマットは以下のようになっています．",
                        :emoji => true
                    }
                },
                {
                    :type => "section",
                    :text => {
                        :type => "mrkdwn",
                        :text => "*regist* ユーザーの登録\n*regular {day} {hour} {min} {offset} {place}* 定期リマインドの登録\n*show* 現在の設定の表示"
                    }
                }
            ]
            slack_client.send_block(channel,block)
        end

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