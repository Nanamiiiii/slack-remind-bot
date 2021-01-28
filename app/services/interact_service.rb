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
        
    end

    def delete_weekly(record_id)
        # delete record by id
        @weekly_model.destroy_by(id: record_id)
        puts "Record Deletion: Succeeded! Deleted record id:#{record_id} from Weekly."
    end

    def slack_client
        @slack_client ||= Client::SlackClient.new
    end
end