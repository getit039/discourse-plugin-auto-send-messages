export default {
  resource: "admin.adminPlugins",
  path: "/admin/plugins",
  map() {
    this.route("autoSendMessages");
  },
};
