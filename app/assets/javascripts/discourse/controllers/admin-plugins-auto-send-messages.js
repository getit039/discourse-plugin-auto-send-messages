import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default class AdminPluginsAutoSendMessagesController extends Controller {
  @service notifications;

  @tracked messagesLimit = 10;
  @tracked orderType = "by_last_seen";
  @tracked order = "asc";

  @action
  async triggerMessages(event) {
    event.preventDefault();

    try {
      await ajax("/admin/plugins/auto_send_messages/trigger", {
        method: "POST",
        data: {
          messages_limit: this.messagesLimit,
          order_type: this.orderType,
          order: this.order,
        },
      });

      this.notifications.showSuccess("Messages triggered successfully");
    } catch (error) {
      this.notifications.showError("Failed to trigger messages");
    }
  }
}
