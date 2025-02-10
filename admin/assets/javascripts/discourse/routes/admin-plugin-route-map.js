export default {
    resource: "admin.adminPlugins.show",
  
    path: "/plugins",
  
    map() {
      this.route("auto-send-messages-settings", { path: "auto-send-messages" });
    },
  };
  