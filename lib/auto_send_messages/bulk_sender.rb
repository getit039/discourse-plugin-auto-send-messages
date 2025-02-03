module AutoSendMessages
    class BulkSender
      def run
        # 1. Check if plugin is enabled
        unless SiteSetting.auto_send_messages_enabled
          raise "Plugin is disabled by site setting!"
        end
  
        limit     = SiteSetting.auto_send_messages_messages_limit_per_run
        order_t   = SiteSetting.auto_send_messages_order_type
        order_dir = SiteSetting.auto_send_messages_order
        subject   = SiteSetting.auto_send_messages_message_subject
        body      = SiteSetting.auto_send_messages_message_body
        sender    = SiteSetting.auto_send_messages_sender_username
        marker    = SiteSetting.auto_send_messages_unique_marker_key
  
        # 2. Validate
        if subject.strip.empty?
          raise "Error: MESSAGE_SUBJECT is empty."
        end
  
        if body.strip.empty?
          raise "Error: MESSAGE_BODY is empty."
        end
  
        # 3. Find sender user
        sender_user = User.find_by(username: sender)
        raise "Sender user '#{sender}' not found!" unless sender_user
  
        # 4. Build base user query
        base_users = User.where(active: true).where.not(staged: true)
  
        if order_t == "by_created_at"
          base_users = base_users.order(created_at: order_dir.to_sym)
        else
          base_users = base_users.order(last_seen_at: order_dir.to_sym)
        end
  
        # 5. Send PM logic (same loop as your script)
        total_sent  = 0
        batch_size  = 200
        offset      = 0
  
        while total_sent < limit
          batch = base_users
                    .offset(offset)
                    .limit(batch_size)
                    .to_a
  
          break if batch.empty?
  
          batch.each do |user|
            # skip if already marked
            if user.custom_fields[marker].present?
              next
            end
  
            begin
              PostCreator.create!(
                sender_user,
                title: subject,
                raw: body,
                archetype: Archetype.private_message,
                skip_validations: true
              )
  
              user.custom_fields[marker] = Time.now.utc.to_s
              user.save!
  
              total_sent += 1
  
              # stop if we've hit the limit
              break if total_sent >= limit
            rescue => e
              Rails.logger.error "Failed to send PM to #{user.username}: #{e.message}"
            end
          end
  
          offset += batch_size
        end
  
        Rails.logger.info "Bulk send completed! total_sent=#{total_sent}"
        total_sent
      end
    end
  end
  