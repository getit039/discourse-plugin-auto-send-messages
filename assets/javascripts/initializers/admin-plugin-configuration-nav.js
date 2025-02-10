import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "auto-send-messages-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser || !currentUser.admin) {
      return;
    }

    withPluginApi("1.1.0", (api) => {
      api.addAdminPluginConfigurationNav("auto-send-messages", [
        {
          label: "auto_send_messages.settings",
          route: "adminPlugins.show.auto-send-messages-settings",
        },
      ]);
    });
  },
};
