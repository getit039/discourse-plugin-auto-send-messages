# Auto Send Messages Plugin

A simple Discourse plugin that automatically sends private messages to users based on criteria such as their last seen date, creation date, and other parameters. You can configure all the settings in the Discourse Admin panel and then trigger the bulk message send.

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Directory Structure](#directory-structure)
  - [plugin.rb](#pluginrb)
  - [config/settings.yml](#configsettingsyml)
  - [lib/auto_send_messages/bulk_sender.rb](#libauto_send_messagesbulk_senderrb)
  - [app/controllers/auto_send_messages/trigger_controller.rb](#appcontrollersauto_send_messagestrigger_controllerrb)
- [How to Configure Plugin Settings](#how-to-configure-plugin-settings)
- [How to Trigger the Code](#how-to-trigger-the-code)
  - [Via cURL (Admin API)](#via-curl-admin-api)
  - [Via Admin Interface Button (Optional)](#via-admin-interface-button-optional)
- [FAQ](#faq)

## Overview

The Auto Send Messages plugin allows a Discourse admin to automatically send private messages to certain users, based on criteria like:

- Number of messages to send (`MESSAGES_LIMIT_PER_RUN`)
- Order type (`by_last_seen` or `by_created_at`)
- Order direction (`asc` or `desc`)
- Message subject and body
- Sender username (the Discourse account that sends the PM)
- A unique marker to ensure the same user is not messaged repeatedly.

All these parameters can be configured in the **Discourse Admin > Settings** panel.

## Installation

1. SSH into your Discourse server.
2. Edit your container’s `app.yml` (found in `/var/discourse/containers`) and add the plugin to the `after_code` section. For example:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://<YOUR_TOKEN>@github.com/getit039/discourse-plugin-auto-send-messages.git
          # add other plugins if needed
```

3. Rebuild your container:

```bash
cd /var/discourse
./launcher rebuild app
```

4. Once the rebuild completes, the plugin is installed. Go to `/admin/plugins` in your Discourse UI to verify.

## Directory Structure

```bash
auto-send-messages
├── plugin.rb
├── config
│   └── settings.yml
├── lib
│   └── auto_send_messages
│       └── bulk_sender.rb
└── app
    └── controllers
        └── auto_send_messages
            └── trigger_controller.rb
```

### plugin.rb

**Purpose:** The entry point for the plugin. It includes:

- Basic metadata (name, about, version, authors, url).
- Site setting references (`enabled_site_setting :auto_send_messages_enabled`).
- Initialization hooks that define plugin routes and load your code.

```ruby
# name: auto-send-messages
# about: A simple plugin to send private messages to users based on the last_seen or created_at date
# version: 0.0.1
# authors: Your Name
# url: https://github.com/getit039/discourse-plugin-auto-send-messages

enabled_site_setting :auto_send_messages_enabled

after_initialize do
  module ::AutoSendMessages
    PLUGIN_NAME = "auto_send_messages"

    class Engine < ::Rails::Engine
      engine_name AutoSendMessages::PLUGIN_NAME
      isolate_namespace AutoSendMessages
    end
  end

  # Define plugin routes
  AutoSendMessages::Engine.routes.draw do
    post "/trigger" => "trigger#execute"
  end

  Discourse::Application.routes.append do
    mount ::AutoSendMessages::Engine, at: "/auto_send_messages"
  end
end
```

### config/settings.yml

**Purpose:** Defines plugin-level site settings that can be configured in **Admin > Settings**.

```yaml
plugins:
  auto_send_messages_enabled:
    default: true
    type: bool

  auto_send_messages_messages_limit_per_run:
    default: 1000
    type: integer

  auto_send_messages_order_type:
    default: "by_last_seen"
    type: enum
    choices:
      - by_last_seen
      - by_created_at

  auto_send_messages_order:
    default: "asc"
    type: enum
    choices:
      - asc
      - desc

  auto_send_messages_message_subject:
    default: "Hello from Discourse!"
    type: string

  auto_send_messages_message_body:
    default: "This is a test private message sent via PostCreator!"
    type: text

  auto_send_messages_sender_username:
    default: "jacob-thepros"
    type: string

  auto_send_messages_unique_marker_key:
    default: "my_campaign_2025"
    type: string
```

## How to Configure Plugin Settings

1. Log in to Discourse as an admin.
2. Go to **Admin > Settings**, and search for `auto_send_messages`.
3. Update these values to your desired configuration.
4. Click **Save** to persist these settings.

## How to Trigger the Code

### Via cURL (Admin API)

Use an admin API key to trigger the plugin’s endpoint:

```bash
curl -X POST \
  -H "Api-Key: YOUR_ADMIN_API_KEY" \
  -H "Api-Username: YOUR_ADMIN_USERNAME" \
  https://yourdiscourse.example.com/auto_send_messages/trigger
```

If successful, you’ll see a JSON response like:

```json
{ "success": true, "total_sent": 34 }
```

### Via Admin Interface Button (Optional)

If you want a UI button in your Discourse admin panel:

1. Create an Ember route or component that sends a `POST` request to `/auto_send_messages/trigger`.
2. Restrict it to admin usage.
3. Once clicked, it calls the endpoint, and you can show the result in the Admin UI.

This step requires basic **Discourse front-end (Ember.js)** knowledge. It’s not strictly necessary if you’re comfortable using **cURL** or a small script to hit the endpoint.
