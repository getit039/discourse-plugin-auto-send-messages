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

      valid_order_types = %w[created_at last_seen_at last_emailed_at]
      unless valid_order_types.include?(order_t)
        raise "Error: ORDER_TYPE '#{order_t}' is invalid."
      end

      valid_orders = %w[asc desc]
      unless valid_orders.include?(order_dir)
        raise "Error: ORDER '#{order_dir}' is invalid."
      end

      # 3. Find sender user
      sender_user = User.find_by(username: sender)
      raise "Sender user '#{sender}' not found!" unless sender_user

      body.gsub!("@SENDER_USERNAME", "@#{sender}")

      # 4. Fetch recipient users
      users = User.where(active: true).where.not(staged: true)
                .order(Arel.sql("#{order_t} #{order_dir.upcase} NULLS LAST"))
                .limit(limit)

      # 5. Send private messages
      users.each do |user|
        next if user.custom_fields[marker].present?

        PostCreator.create!(
          sender_user,
          title: subject,
          raw: body,
          archetype: Archetype.private_message,
          target_usernames: user.username,
          skip_validations: true
        )

        user.custom_fields[marker] = Time.now.utc.to_s
        user.save!

        sleep(SiteSetting.auto_send_messages_sleep_timer)
      end
    end
  end
end
