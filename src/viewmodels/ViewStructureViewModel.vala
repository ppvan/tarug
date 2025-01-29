namespace Tarug {
    public class ViewStructureViewModel : Object {

        public View selected_view { get; set; }
        public ListModel columns { get; set; }

        public ViewStructureViewModel(SQLService sql_service){
            base();

            EventBus.instance().selected_view_changed.connect((view) => {
                selected_view = view;
                var obs_list = new ObservableList<Column> ();
                obs_list.append_all(view.columns.as_list());

                columns = obs_list;
            });
        }
    }
}
