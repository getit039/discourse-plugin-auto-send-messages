module AutoSendMessages
    class TriggerController < ::ApplicationController
      before_action :ensure_admin
  
      def execute
        total_sent = AutoSendMessages::BulkSender.new.run
        render_json_dump({ success: true, total_sent: total_sent })
      rescue => e
        render_json_error e.message
      end
    end
  end
