require 'date'
require_relative '../models/weekly'
require_relative '../models/channel'
require_relative '../models/message'
require_relative '../models/reminder'

class InteractService

    def initialize(weekly_model = Weekly, channel_model = Channel, message_model = Message, reminder_model = Reminder)
        @weekly_model = weekly_model
        @channel_model = channel_model
        @message_model = message_model
        @reminder_model = reminder_model
    end

    def block_execute(req)
        ### ===============================================================
        ### action_id reference
        ### ===============================================================
        ### add_weekly              :    call adding weekly remind view
        ### show_weekly             :    list up weekly reminder
        ### add_temp                :    call adding temporary reminder
        ### check_q                 :    list up reminder queue
        ### set_ch                  :    setup channel name to remind
        ###
        ### delete_rec_regular_{ID} :    delete weekly reminder by id
        ### delete_rec_q_{ID}       :    delete reminder from queue by id
        ### edit_rec_q_{ID}         :    edit reminder from queue by id
        ### ===============================================================

        # get params
        act = req[:actions].first
        act_id = act[:action_id]
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        trg_id = req[:trigger_id]

        case act_id
        when /\Adelete_rec_/
            act_id.slice!('delete_rec_')
            case act_id
            when /\Aregular_/
                delete_weekly(act_id, user_id, channel_id)
            when /\Aq_/
                delete_queue(act_id, user_id, channel_id)
            end
        when /\Aedit_rec_/
            act_id.slice!('edit_rec_')
            case act_id
            when /\Aq_/
                edit_queue(act_id, user_id, channel_id, trg_id)
            end
        when 'add_weekly'
            call_weekly_add_modal(req)
        when 'show_weekly'
            show_weekly_reminders(req)
        when 'add_temp'
            call_reminder_add_modal(req)
        when 'check_q'
            show_reminder_db(req)
        when 'add_comment'
            # TODO: implement comment adding method
        when 'set_ch'
            call_channel_set_modal(req)
        when 'cancel_command'
            delete_recent_message(req)
        end
    end

    def modal_execute(req)
        # get callback_id and check
        callback_id = req[:view][:callback_id]
        case callback_id
        when 'add_weekly'
            add_weekly(req)
        when 'add_rem'
            add_reminder(req)
        when /\Aedit_rem_/
            update_reminder(req)
        when 'ch_select'
            set_channel(req)
        end
    end

    private

    def call_weekly_add_modal(req)
        # delete command message
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        ts = @message_model.find_by(userid: user_id).t_stamp
        slack_client.delete_message(channel_id, ts)
        @message_model.find_by(userid: user_id).delete

        # generate modal
        trg_id = req[:trigger_id]
        views = gen_add_view
        slack_client.send_view(trg_id, views)
    end

    def show_weekly_reminders(req)
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        block = gen_weekly_remind_list(@weekly_model.exists?)
        ts = @message_model.find_by(userid: user_id).t_stamp
        response = slack_client.update_message(channel_id, ts, '', block)
        set_last_timestamp(response["ts"], user_id)
    end

    def call_reminder_add_modal(req)
        # delete command message
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        ts = @message_model.find_by(userid: user_id).t_stamp
        slack_client.delete_message(channel_id, ts)
        @message_model.find_by(userid: user_id).delete

        # generate modal
        trg_id = req[:trigger_id]
        views = gen_temporary_add_view
        slack_client.send_view(trg_id, views)
    end

    def show_reminder_db(req)
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        block = gen_reminder_db_list(@reminder_model.exists?)
        ts = @message_model.find_by(userid: user_id).t_stamp
        response = slack_client.update_message(channel_id, ts, '', block)
        set_last_timestamp(response["ts"], user_id)
    end

    def call_channel_set_modal(req)
        # delete command message
        user_id = req[:user][:id]
        channel_id = req[:container][:channel_id]
        ts = @message_model.find_by(userid: user_id).t_stamp
        slack_client.delete_message(channel_id, ts)
        @message_model.find_by(userid: user_id).delete

        # generate modal
        trg_id = req[:trigger_id]
        views = gen_ch_select
        slack_client.send_view(trg_id, views)
    end

    def add_weekly(req)
        # get values
        user_id = req[:user][:id]
        # channel_id = req[:container][:channel_id]
        val = req[:view][:state][:values]
        wday = val[:wday_sel][:week_day_select][:selected_option][:value].to_i
        hour = val[:hour_sel][:hour_select][:selected_option][:value].to_i
        min = val[:min_sel][:minute_select][:selected_option][:value].to_i
        place = val[:place_in][:place_input][:value]
        offset = val[:offset_sel][:offset_select][:selected_option][:value].to_i

        # add record to weekly
        @weekly_model.create(day: wday, remind_time: get_time_s(hour, min), offset: offset, place: place)
        gen_debug_log("Record Creation Succeeded.")

        # send message to user
        wday_s = get_wday_string(wday)
        time_s = get_time_s(hour, min)
        msg = "定期リマインドを `#{wday_s} - #{time_s}` の `#{offset}時間前` に設定しました．"
        response = slack_client.send_msg(user_id, msg)
        set_last_timestamp(response["ts"], user_id)

        # set reminder cannot be set automatically
        today = DateTime.now
        r_hour = hour - offset
        if r_hour < 0
            r_hour += 24
            wday -= 1
            if wday < 0
                wday += 7
            end
        end

        if wday > today.wday
            tmp_day = today + (wday - today.wday)
            set_date = DateTime.new(tmp_day.year, tmp_day.month, tmp_day.day, r_hour, min, 0)
            time_s = get_time_s(hour, min)
            comment = "<!channel> 今日の活動は `#{time_s}` から `#{place}` だよっ！"
            @reminder_model.create(remind_day: set_date.to_s(:db), comment: comment)
        end
    end

    def add_reminder(req)
        # get values
        user_id = req[:user][:id]
        # channel_id = req[:container][:channel_id]
        val = req[:view][:state][:values]
        pick_date = val[:rem_date][:datepicker_action][:selected_date]
        pick_time = val[:rem_time][:timepicker_action][:selected_time]
        comment = val[:comment][:comment_action][:value]
        rem_datetime = DateTime.parse("#{pick_date} #{pick_time}")
        @reminder_model.create(remind_day: rem_datetime.to_s(:db), comment: comment)
        gen_debug_log("Record Creation Succeeded.")

        # send message to user
        date_s = rem_datetime.strftime("%Y-%m-%d %H:%M")
        msg = "リマインダーを `#{date_s}` に設定しました．"
        response = slack_client.send_msg(user_id, msg)
        set_last_timestamp(response["ts"], user_id)
    end

    def update_reminder(req)
        # get values
        record_id = req[:view][:callback_id].slice!("edit_rem_").to_i
        user_id = req[:user][:id]
        # channel_id = req[:container][:channel_id]
        val = req[:view][:state][:values]
        pick_date = val[:rem_date][:datepicker_action][:selected_date]
        pick_time = val[:rem_time][:timepicker_action][:selected_time]
        comment = val[:comment][:comment_action][:value]
        rem_datetime = DateTime.parse("#{pick_date} #{pick_time}")
        @reminder_model.find_by(id: record_id).update(:remind_day rem_datetime.to_s(:db), :comment comment)
        gen_debug_log("Record Update Succeeded.")
        
        # update list
        block = gen_reminder_db_list(@reminder_model.exists?)
        ts = @message_model.find_by(userid: user_id).t_stamp
        response = slack_client.update_message(channel_id, ts, '', block)
        set_last_timestamp(response["ts"], user_id)
    end

    def set_channel(req)
        user_id = req[:user][:id]
        val = req[:view][:state][:values]
        selected_ch = val[:ch_sel][:ch_select][:selected_channel]
        
        if @channel_model.where(index: 'reminder').exists?
            @channel_model.where(index: 'reminder').update(ch_id: selected_ch)
        else
            @channel_model.create(index: 'reminder', ch_id: selected_ch)
        end

        msg = "`#{selected_ch}` を投稿チャンネルに設定しました．"
        response = slack_client.send_msg(user_id, msg)
        set_last_timestamp(response["ts"], user_id)
    end

    def delete_weekly(act_id, user_id, channel_id)
        # formatting act_id
        act_id.slice!('regular_')
        record_id = act_id.to_i
        # delete record by id
        if check_weekly_by_id(record_id)
            @weekly_model.destroy_by(id: record_id)
            gen_debug_log("Record Deletion: Succeeded! Deleted record id:#{record_id} from Weekly.")
            
            # update list
            block = gen_weekly_remind_list(@weekly_model.exists?)
            ts = @message_model.find_by(userid: user_id).t_stamp
            response = slack_client.update_message(channel_id, ts, '', block)
            set_last_timestamp(response["ts"], user_id)

        else
            gen_debug_log("Record Deletion: Unsuccessful! Record id:#{record_id} does not exist.")
            ts = @message_model.find_by(userid: user_id).t_stamp
            msg = "レコードが存在しません．"
            response = slack_client.update_message_only(channel_id, ts, msg)
            set_last_timestamp(response["ts"], user_id)
        end
    end

    def delete_queue(act_id, user_id, channel_id)
        # formatting act_id
        act_id.slice!('q_')
        record_id = act_id.to_i
        # delete record by id
        if check_queue_by_id(record_id)
            @reminder_model.destroy_by(id: record_id)
            gen_debug_log("Record Deletion: Succeeded! Deleted record id:#{record_id} from queue.")

            # update list
            block = gen_reminder_db_list(@reminder_model.exists?)
            ts = @message_model.find_by(userid: user_id).t_stamp
            response = slack_client.update_message(channel_id, ts, '', block)
            set_last_timestamp(response["ts"], user_id)

        else
            gen_debug_log("Record Deletion: Unsuccessful! Record id:#{record_id} does not exist.")
            ts = @message_model.find_by(userid: user_id).t_stamp
            msg = "レコードが存在しません．"
            response = slack_client.update_message_only(channel_id, ts, msg)
            set_last_timestamp(response["ts"], user_id)
        end
    end

    def edit_queue(act_id, user_id, channel_id, trg_id)
        # formatting act_id
        act_id.slice!('q_')
        record_id = act_id.to_i
        # generate editing dialog
        if check_queue_by_id(record_id)
            model = @reminder_model.find_by(id: record_id)
            view = gen_queue_editing_view(model)
            slack_client.send_view(trg_id, views)
        else
            gen_debug_log("Cannot edit record. Record id:#{record_id} does not exist.")
            ts = @message_model.find_by(userid: user_id).t_stamp
            msg = "レコードが存在しません．"
            response = slack_client.update_message_only(channel_id, ts, msg)
            set_last_timestamp(response["ts"], user_id)
        end
    end

    def delete_recent_message(req)
        user_id = req[:user][:id]
        channel = req[:container][:channel_id]
        ts = @message_model.find_by(userid: user_id).t_stamp
        slack_client.delete_message(channel, ts)
        @message_model.find_by(userid: user_id).delete
    end

    def check_weekly_by_id(record_id)
        return @weekly_model.exists?(id: record_id)
    end

    def check_queue_by_id(record_id)
        return @reminder_model.exists?(id: record_id)
    end

    def set_last_timestamp(ts, user_id)
        if (message = @message_model.find_by(userid: user_id)).present?
            message.update(t_stamp: ts)
        else
            @message_model.create(userid: user_id, t_stamp: ts)
        end
    end

    def slack_client
        @slack_client ||= Client::SlackClient.new
    end

    def gen_debug_log(str)
        puts "[interact_service]: #{str}"
    end

    # =========================================================
    # = FROM HERE = Methods generating block, view and string =
    # =========================================================

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

    def gen_add_view
        # generate modal view
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

    def gen_temporary_add_view
        # generate modal view
        views = {
            :type => "modal",
            :callback_id => "add_rem",
            :title => {
                :type => "plain_text",
                :text => "新規リマインダー",
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

        t = DateTime.now()
        date_str = t.strftime("%Y-%m-%d")

        blocks = []
        block = {
			:type => "input",
			:block_id => "rem_date",
			:element => {
				:type => "datepicker",
				:initial_date => "#{date_str}",
				:placeholder => {
					:type => "plain_text",
					:text => "Select a date",
					:emoji => true
				},
				:action_id => "datepicker_action"
			},
			:label => {
				:type => "plain_text",
				:text => "日付",
				:emoji => true
			}
		}
        blocks << block
        block = {
			:type => "input",
			:block_id => "rem_time",
			:element => {
				:type => "timepicker",
				:initial_time => "00:00",
				:placeholder => {
					:type => "plain_text",
					:text => "Select time",
					:emoji => true
				},
				:action_id => "timepicker_action"
			},
			:label => {
				:type => "plain_text",
				:text => "時刻",
				:emoji => true
			}
		}
        blocks << block
        block = {
			:type => "input",
			:block_id => "comment",
			:element => {
				:type => "plain_text_input",
				:multiline => true,
				:action_id => "comment_action"
			},
			:label => {
				:type => "plain_text",
				:text => "コメント",
				:emoji => true
			}
		}
        blocks << block
        views.store(:blocks, blocks)
        return views
    end

    def gen_queue_editing_view(model)
        # generate modal view
        record_id = model.id
        views = {
            :type => "modal",
            :callback_id => "edit_rem_#{record_id}",
            :title => {
                :type => "plain_text",
                :text => "リマインダー編集",
                :emoji => true
            },
            :submit => {
                :type => "plain_text",
                :text => "Apply",
                :emoji => true
            },
            :close => {
                :type => "plain_text",
                :text => "Cancel",
                :emoji => true
            }
        }

        t = model.remind_day
        date_str = t.strftime("%Y-%m-%d")
        time_str = t.strftime("%H:%M")
        comment = model.comment

        blocks = []
        block = {
			:type => "input",
			:block_id => "rem_date",
			:element => {
				:type => "datepicker",
				:initial_date => "#{date_str}",
				:placeholder => {
					:type => "plain_text",
					:text => "Select a date",
					:emoji => true
				},
				:action_id => "datepicker_action"
			},
			:label => {
				:type => "plain_text",
				:text => "日付",
				:emoji => true
			}
		}
        blocks << block
        block = {
			:type => "input",
			:block_id => "rem_time",
			:element => {
				:type => "timepicker",
				:initial_time => "#{time_str}",
				:placeholder => {
					:type => "plain_text",
					:text => "Select time",
					:emoji => true
				},
				:action_id => "timepicker_action"
			},
			:label => {
				:type => "plain_text",
				:text => "時刻",
				:emoji => true
			}
		}
        blocks << block
        block = {
			:type => "input",
			:block_id => "comment",
			:element => {
				:type => "plain_text_input",
				:multiline => true,
                :initial_value => "#{comment}",
				:action_id => "comment_action"
			},
			:label => {
				:type => "plain_text",
				:text => "コメント",
				:emoji => true
			}
		}
        blocks << block
        views.store(:blocks, blocks)
        return views
    end

    def gen_weekly_remind_list(model_presence)
        # generate block kit object
        if model_presence
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
                            :action_id => "delete_rec_regular_#{id}",
                            :style => "danger"
                        }
                    ]
                }
            
                block << section
                block << buttons
                block << divider
            end
        else
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
        end

        return block
    end

    def gen_reminder_db_list(model_presence)
        # generate block kit object
        if model_presence
            block = []
            divider = {
                :type => "divider"
            }

            @reminder_model.find_each do |model|
                id = model.id
                rem_date = model.remind_day
                rem_date_s = rem_date.strftime("%Y/%m/%d %a %H:%M:%S")
                comment = model.comment

                section = {

                    :type => "section",
                    :fields => [
                        {
                            :type => "mrkdwn",
                            :text => "*ID:*\n#{id}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*日時:*\n#{rem_date_s}"
                        },
                        {
                            :type => "mrkdwn",
                            :text => "*コメント:*\n#{comment}"
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
                                :text => "編集",
                                :emoji => true
                            },
                            :value => "click_me_123",
                            :action_id => "edit_rec_q_#{id}",
                            :style => "primary"
                        },
                        {
                            :type => "button",
                            :text => {
                                :type => "plain_text",
                                :text => "削除",
                                :emoji => true
                            },
                            :value => "click_me_123",
                            :action_id => "delete_rec_q_#{id}",
                            :style => "danger"
                        }
                    ]
                }
            
                block << section
                block << buttons
                block << divider
            end
        else
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
        end

        return block
    end

    def gen_ch_select
        view = {
            :type => "modal",
            :callback_id => "ch_select",
            :title => {
                :type => "plain_text",
                :text => "投稿チャンネル設定",
                :emoji => true
            },
            :submit => {
                :type => "plain_text",
                :text => "Set",
                :emoji => true
            },
            :close => {
                :type => "plain_text",
                :text => "Cancel",
                :emoji => true
            },
            :blocks => [
                {
                    :type => "input",
                    :block_id => "ch_sel",
                    :element => {
                            :type => "channels_select",
                            :placeholder => {
                                :type => "plain_text",
                                :text => "Select a channel",
                                :emoji => true
                            },
                            :action_id => "ch_select"
                    },
                    :label => {
                        :type => "plain_text",
                        :text => "投稿チャンネル",
                        :emoji => true
                    }
                }
            ]
        }
        return view
    end
end