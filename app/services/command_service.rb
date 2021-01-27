require 'date'
require_relative '../models/user'
require_relative '../models/weekly'

class CommandService
    def initialize(weekly_model = Weekly, user_model = User)
        @weekly_model = weekly_model
        @user_model = user_model
    end

    def execute(req)
        
        # get some param from json
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
                msg = "#{user_name}を登録しました．管理者による有効化後に利用できます．"
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
                err_ret(0)
                return
            end

            # argument check: number, type
            if raw_text.length != 5 || !(raw_text[1].instance_of?(Integer)) || !(raw_text[2].instance_of?(Integer)) || !(raw_text[3].instance_of?(Integer)) || !(raw_text[4].instance_of?(Integer)) || !(raw_text[5].instance_of?(String))
                err_ret(1)
                return
            end

            wday = raw_text[1]
            hour = raw_text[2]
            min = raw_text[3]
            offset = raw_text[4]
            place = raw_text[5]

            # argument check: range
            if wday < 0 || wday > 6 || hour < 0 || hour > 23 || min < 0 || min > 59
                err_ret(1)
                return
            end

            remind_time = '#{hour}:#{min}'
            @weekly_model.create(day: wday, remind_time: remind_time, offset: offset, place: place)
            
            wday_s = get_wday_string(wday)
            msg = "定期リマインドを '#{wday_s}' '#{remind_time}' の'#{offset}'時間前に設定しました．"
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

                section = {

                    :type => "section",
                    :fields => [
                        {
                            :type => "mrkdwn",
                            :text => "*No:*\n#{id + 1}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*曜日:*\n#{wday_s}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*時刻:*\n#{time_h}:#{time_m}"
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
                
                block << section
                block << divider
            end

            slack_client.send_block(channel, block)

        when 'delete'
            # TODO: implement delete method (maybe integrate show method)
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

    def err_ret(num)
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

end