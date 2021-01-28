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
            slack_client.send_msg(channel, msg)

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

        when 'temp'
            #TODO: set temporary reminder
        when 'show'
            # show remind schedule (now only regular sc)
            # user certification
            if !(certificate(user_id))
                puts '# Setting regular reminder: Not certificated user'
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

    def gen_add_view
        # generate model view
        views = {
            :type => "modal",
            :callback_id => "add_weekly",
            :title => {
                :type => "plain_text",
                :text => "定期リマインド追加",
                :emoji => true
            },
            :submit => {
                :type => "plain_text",
                :text => "Add",
                :emoji => true
            },
            :close => {
                :type => "plain_text",
                :text => "Cancel",
                :emoji => true
            }
        }

        blocks = []
        # generate wday selection
        block = {
            :type => "input",
            :block_id => "wday_sel",
            :element => {
                :type => "static_select",
                :placeholder => {
                    :type => "plain_text",
                    :text => "Select an item",
                    :emoji => true
                }
            }
        }
        options = []
        7.times do |i|
            options << {
                :text => {
                    :type => "plain_text",
                    :text => get_wday_jp(i),
                    :emoji => true
                },
                :value => "#{i}"
            }
        end
        block[:element].store(:options, options)
        block[:element].store(:action_id, "week_day_select")
        block.store(:label, { :type => "plain_text", :text => "曜日", :emoji => true })
        blocks << block
        
        # generate hour selection
        block = {
			:type => "input",
			:block_id => "hour_sel",
			:element => {
				:type => "static_select",
				:placeholder => {
					:type => "plain_text",
					:text => "Select an item",
					:emoji => true
                }
            }
        }
        options = []
        24.times do |i|
            options << {
                :text => {
                    :type => "plain_text",
                    :text => "#{i}時",
                    :emoji => true
                },
                :value => "#{i}"
            }
        end
        block[:element].store(:options, options)
        block[:element].store(:action_id, "hour_select")
        block.store(:label, { :type => "plain_text", :text => "時", :emoji => true })
        blocks << block

        block = {
            :type => "input",
			:block_id => "min_sel",
			:element => {
				:type => "static_select",
				:placeholder => {
					:type => "plain_text",
					:text => "Select an item",
					:emoji => true
                }
            }      
        }
        options = []
        6.times do |i|
            options << {
                :text => {
                    :type => "plain_text",
                    :text => "#{i*10}分",
                    :emoji => true
                },
                :value => "#{i*10}"
            }
        end
        block[:element].store(:options, options)
        block[:element].store(:action_id, "minute_select")
        block.store(:label, { :type => "plain_text", :text => "分", :emoji => true })
        blocks << block

        block = {
            :type => "input",
			:block_id => "place_in",
			:element => {
				:type => "plain_text_input",
				:action_id => "place_input"
			},
			:label => {
				:type => "plain_text",
				:text => "場所",
				:emoji => true
			}
        }
        blocks << block
        
        block = {
			:type => "input",
			:block_id => "offset_sel",
			:element => {
				:type => "static_select",
				:placeholder => {
					:type => "plain_text",
					:text => "Select an item",
					:emoji => true
                }
            }
        }
        options = []
        6.times do |i|
            options << {
                :text => {
                    :type => "plain_text",
                    :text => "#{i}時間前",
                    :emoji => true
                },
                :value => "#{i}"
            }
        end

        block[:element].store(:options, options)
        block[:element].store(:action_id, "offset_select")
        block.store(:label, { :type => "plain_text", :text => "通知", :emoji => true })
        blocks << block

        views.store(:blocks, blocks)
        return views
    end

    def gen_remind_list
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
                        :action_id => "delete_rec_regular_#{id}"
                    },
                    {
                        :type => "button",
                        :text => {
                            :type => "plain_text",
                            :text => "編集",
                            :emoji => true
                        },
                        :value => "click_me_123",
                        :action_id => "modify_rec_regular_#{id}"
                    }
                ]
            }
            
            block << section
            block << buttons
            block << divider
        end
        return block
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