require 'date'
require_relative '../models/user'
require_relative '../models/weekly'

class InteractService

    def initialize(user_model = User, weekly_model = Weekly)
        @user_model = user_model
        @weekly_model = weekly_model
    end

    def block_execute(req)
        # get params
        act = req[:actions].first
        act_id = act[:action_id]
        channel = req[:channel][:id]

        if act_id =~ /\Adelete_rec_/
            # delete record
            act_id.slice!('delete_rec_')
            # detect record
            if act_id =~ /\Aregular_/
                # get record id from action_id
                act_id.slice!('regular_')
                record_id = act_id.to_i
                
                delete_weekly(record_id)

                msg = "リマインド設定を削除しました．"
                slack_client.send_msg(channel, msg)
            end
        end
    end

    def modal_execute(req)
        # get callback_id and check
        callback_id = req[:view][:callback_id]
        case callback_id
        when 'add_weekly'
            # get values
            channel = req[:user][:id]
            val = req[:view][:state][:values]
            wday = val[:wday_sel][:week_day_select][:selected_option][:value].to_i
            hour = val[:hour_sel][:hour_select][:selected_option][:value].to_i
            min = val[:min_sel][:minute_select][:selected_option][:value].to_i
            place = val[:place_in][:place_input][:value]
            offset = val[:offset_sel][:offset_select][:selected_option][:value].to_i

            add_weekly(wday, hour, min, place, offset)

            wday_s = get_wday_string(wday)
            time_s = get_time_s(hour, min)
            msg = "定期リマインドを `#{wday_s} - #{time_s}` の `#{offset}時間前` に設定しました．"
            slack_client.send_msg(channel, msg)
        end
    end

    def add_weekly(wday, hour, min, place, offset)
        # add record to weekly
        @weekly_model.create(day: wday, remind_time: get_time_s(hour, min), offset: offset, place: place)
        puts "[interact_service] Record Creation Succeeded!"
    end

    def delete_weekly(record_id)
        # delete record by id
        @weekly_model.destroy_by(id: record_id)
        puts "[interact_service] Record Deletion: Succeeded! Deleted record id:#{record_id} from Weekly."
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

    def slack_client
        @slack_client ||= Client::SlackClient.new
    end
end