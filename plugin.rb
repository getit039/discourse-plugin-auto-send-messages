# #!/usr/bin/env ruby
# # frozen_string_literal: true

# # Usage Example (inside Docker container):
# #   MESSAGES_LIMIT_PER_RUN=5 \
# #   ORDER_TYPE=by_created_at \
# #   ORDER=desc \
# #   MESSAGE_SUBJECT="Hello folks!" \
# #   MESSAGE_BODY="This is a test." \
# #   SENDER_USERNAME="jacob-thepros" \
# #   UNIQUE_MARKER_KEY="my_campaign_2025" \
# #   bundle exec rails runner "xtests/bulk_send_pm.rb"

# # ------------------------------------------------------------------------------

# require File.expand_path("/var/www/discourse/config/environment", __FILE__)

# # ------------------------------------------------------------------------------
# # 1. ENV OR DEFAULTS
# # ------------------------------------------------------------------------------
# MESSAGES_LIMIT_PER_RUN = (ENV["MESSAGES_LIMIT_PER_RUN"] || "1000").to_i
# ORDER_TYPE = ENV["ORDER_TYPE"] || "by_last_seen" #   'by_last_seen' or 'by_created_at'
# ORDER = ENV["ORDER"] || "asc"                    #   'asc' or 'desc'
# MESSAGE_SUBJECT = ENV["MESSAGE_SUBJECT"]
# MESSAGE_BODY    = ENV["MESSAGE_BODY"]

# # Sender username (the Discourse user who sends the PM)
# # You can also default this if you want:
# SENDER_USERNAME = ENV["SENDER_USERNAME"] || "jacob-thepros"

# # NEW ENV VARIABLE for unique custom field marker
# UNIQUE_MARKER_KEY = ENV["UNIQUE_MARKER_KEY"]

# # ------------------------------------------------------------------------------
# # 2. VALIDATION
# # ------------------------------------------------------------------------------
# if MESSAGE_SUBJECT.nil? || MESSAGE_SUBJECT.strip.empty?
#   raise "Error: MESSAGE_SUBJECT is empty. Please set MESSAGE_SUBJECT."
# end

# if MESSAGE_BODY.nil? || MESSAGE_BODY.strip.empty?
#   raise "Error: MESSAGE_BODY is empty. Please set MESSAGE_BODY."
# end

# # Validate order_type
# valid_order_types = %w[by_last_seen by_created_at]
# unless valid_order_types.include?(ORDER_TYPE)
#   raise "Error: ORDER_TYPE '#{ORDER_TYPE}' is invalid. Must be: #{valid_order_types.join(', ')}."
# end

# # Validate order direction
# valid_orders = %w[asc desc]
# unless valid_orders.include?(ORDER)
#   raise "Error: ORDER '#{ORDER}' is invalid. Must be: #{valid_orders.join(', ')}."
# end

# # Validate UNIQUE_MARKER_KEY
# if UNIQUE_MARKER_KEY.nil? || UNIQUE_MARKER_KEY.strip.empty?
#   raise "Error: UNIQUE_MARKER_KEY is empty. Please set UNIQUE_MARKER_KEY."
# end

# # ------------------------------------------------------------------------------
# # 3. FIND SENDER
# # ------------------------------------------------------------------------------
# sender_user = User.find_by(username: SENDER_USERNAME)
# raise "Sender user '#{SENDER_USERNAME}' not found!" unless sender_user

# # ------------------------------------------------------------------------------
# # 4. FETCH RECIPIENT USERS (EXAMPLE)
# # ------------------------------------------------------------------------------
# # This is just an example filter. You can adapt it as needed:
# #   - Only active, non-staged users
# #   - Apply MESSAGES_LIMIT_PER_RUN
# #   - Order by last_seen_at or created_at, ascending or descending

# base_users = User
#   .where(active: true)
#   .where.not(staged: true)

# # Apply ordering
# case ORDER_TYPE
# when "by_last_seen"
#   base_users = base_users.order(last_seen_at: ORDER.to_sym)
# when "by_created_at"
#   base_users = base_users.order(created_at: ORDER.to_sym)
# end

# # This is commented out for now, to force the script to try to send exactly
# # MESSAGES_LIMIT_PER_RUN messages, even if some users are skipped.

# # Apply limit
# # base_users = base_users.limit(MESSAGES_LIMIT_PER_RUN)

# # ------------------------------------------------------------------------------
# # 5. SEND PRIVATE MESSAGE TO EACH USER
# # ------------------------------------------------------------------------------
# Rails.logger.info "Attempting to send up to #{MESSAGES_LIMIT_PER_RUN} messages using '#{SENDER_USERNAME}'..."


# # NEW LOGIC to ensure we always try to send exactly MESSAGES_LIMIT_PER_RUN
# #   if possible, skipping users with a custom field marker, and fetching
# #   additional users in batches if needed.

# total_sent = 0
# batch_size = 200
# offset     = 0

# while total_sent < MESSAGES_LIMIT_PER_RUN
#   # Fetch a batch of users from the base_users query, offset by 'offset'
#   # We do NOT set another .limit here to let the base query's .limit() apply 
#   # or fetch more if you want. Tweak if you need an absolute cap on total records.
#   batch = base_users
#     .offset(offset)
#     .limit(batch_size)
#     .to_a

#   # If no users left, break
#   break if batch.empty?

#   batch.each do |user|
#     # Skip if user already has our marker set
#     if user.custom_fields[UNIQUE_MARKER_KEY].present?
#       next
#     end

#     begin
#       # Send PM
#       PostCreator.create!(
#         sender_user,
#         title: MESSAGE_SUBJECT,
#         raw: MESSAGE_BODY,
#         archetype: Archetype.private_message,
#         # target_usernames: user.username,
#         skip_validations: true
#       )

#       # Mark user to avoid duplicates
#       user.custom_fields[UNIQUE_MARKER_KEY] = Time.now.utc.to_s
#       user.save!

#       total_sent += 1
#       Rails.logger.info "PM sent to: #{user.username}"

#       # Stop if we've hit the limit
#       break if total_sent >= MESSAGES_LIMIT_PER_RUN

#     rescue => e
#       Rails.logger.error "Failed to send PM to #{user.username}: #{e.message}"
#     end
#   end

#   offset += batch_size
# end

# Rails.logger.info "Bulk message script completed! Total messages sent: #{total_sent}."


# name: auto-send-messages
# about: A simple plugin to send private messages to users based on the last_seen or created_at date
# version: 0.0.1
# authors: Xavier Garzon
# url: https://github.com/getit039/discourse-plugin-auto-send-messages

enabled_site_setting :auto_send_messages_enabled

PLUGIN_NAME = "auto_send_messages"

after_initialize do
  module ::AutoSendMessages
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace AutoSendMessages
    end
  end

  AutoSendMessages::Engine.routes.draw do
    post "/trigger" => "trigger#execute"
  end

  Discourse::Application.routes.append do
    mount ::AutoSendMessages::Engine, at: "/auto_send_messages"
  end
end
