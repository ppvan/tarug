namespace Tarug {
    public class NavigationService : Object {
        public const string CONNECTION_VIEW = "connection-view";
        public const string QUERY_VIEW = "query-view";
        public const string[] VIEW_NAMES = { CONNECTION_VIEW, QUERY_VIEW };

        public string current_view { get; set; default = CONNECTION_VIEW; }

        public NavigationService(){
            EventBus.instance().connection_disabled.connect_after(() => {
                this.navigate(CONNECTION_VIEW);
            });

            EventBus.instance().connection_active.connect_after((_conn) => {
                this.navigate(QUERY_VIEW);
            });
        }

        public void navigate (string view_name){
            if (view_name == current_view) {
                return;
            }

            for (int i = 0; i < VIEW_NAMES.length; i++) {
                if (VIEW_NAMES[i] == view_name) {
                    debug("Navigating to " + view_name);
                    current_view = view_name;
                    return;
                }
            }
        }
    }
}
