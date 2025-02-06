# name: discourse-plugin-auto-send-messages
# about: A simple plugin to send private messages to users based on the last_seen or created_at date
# version: 0.0.1
# authors: Xavier Garzon
# url: https://github.com/getit039/discourse-plugin-auto-send-messages

enabled_site_setting :auto_send_messages_enabled

after_initialize do
  module ::AutoSendMessages
    PLUGIN_NAME = "auto_send_messages"
  end

  # Register Admin UI Route
  add_admin_route "Auto Send Messages", "auto_send_messages"

  # Register plugin settings
  settings = %w[
    messages_limit_per_run
    order_type
    order
    message_subject
    message_body
    sender_username
    unique_marker_key
  ]

  settings.each do |setting|
    SiteSetting.set("auto_send_messages_#{setting}", SiteSetting.defaults["auto_send_messages_#{setting}"] || nil)
  end  
  

  # Register API Route to Trigger Sending Messages
  Discourse::Application.routes.append do
    post "/admin/plugins/auto_send_messages/trigger" => "auto_send_messages/trigger#execute"
  end
end
