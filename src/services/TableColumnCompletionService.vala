namespace Tarug {
    public class TableColumnCompletionService : Object, GtkSource.CompletionProvider {
        private CompleterService completer;
        private Gtk.FilterListModel model;
        private Gtk.StringFilter filter;
        private TableViewModel table_viewmodel;

        private SchemaViewModel schema_viewmodel;
        public TableColumnCompletionService(){
            base();
            this.table_viewmodel = autowire<TableViewModel>();
            this.schema_viewmodel = autowire<SchemaViewModel> ();
            this.completer = autowire<CompleterService> ();

            var expression = new Gtk.PropertyExpression(typeof (Candidate), null, "value");
            filter = new Gtk.StringFilter(expression);
            filter.match_mode = Gtk.StringFilterMatchMode.PREFIX;
            filter.ignore_case = true;

            model = new Gtk.FilterListModel(null, filter);
        }

        public int get_priority (GtkSource.CompletionContext context){
            return(2000);
        }

        public void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal){
            var model = (Candidate) proposal;
            var buf = context.get_buffer();

            buf.begin_user_action();
            Gtk.TextIter start, end;
            context.get_bounds(out start, out end);

            if (start.compare(end) != 0) {
                buf.delete_range(start, end);
            }
            buf.insert_at_cursor(model.value, model.value.length);
            buf.end_user_action();
        }

        public void display (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell){
            var candidate = (Candidate) proposal;
            switch (cell.column) {
                // name
                case GtkSource.CompletionColumn.TYPED_TEXT:
                    cell.text = candidate.value;
                    break;

                // group
                case GtkSource.CompletionColumn.AFTER:
                    cell.text = candidate.group;
                    break;

                // case GtkSource.CompletionColumn.DETAILS:
                // cell.text = "DETAILS";
                // break;

                // case GtkSource.CompletionColumn.COMMENT:
                // cell.text = "COMMENT";
                // break;

                // case GtkSource.CompletionColumn.ICON:
                // cell.text = "ICON";
                // break;

                // case GtkSource.CompletionColumn.BEFORE:
                // cell.text = candidate.value;
                // break;

                default: break;
            }
        }

        public bool is_trigger (Gtk.TextIter iter, unichar ch){
            var buf = (GtkSource.Buffer) iter.get_buffer();

            if (buf.iter_has_context_class(iter, "comment") || buf.iter_has_context_class(iter, "string")) {
                return(false);
            }

            return(ch.to_string() == ".");
        }

        public async GLib.ListModel populate_async (GtkSource.CompletionContext context, GLib.Cancellable ? cancellable){
            var candidates = new ObservableList<Candidate> ();
            var buffer = context.get_buffer();
            var token = context.get_word();
            Gtk.TextIter begin, end;
            context.get_bounds(out begin, out end);


            if (token.length >= 1 && !token[0].isalpha()) {
                return(new ObservableList<Candidate> ());
            }

            var table = table_viewmodel.selected_table;
            var fields = get_columns(table).as_list();
            candidates.append_all(fields);

            for (int i = 0; i < PGListerals.WHEREKEYWORDS.length; i++) {
                candidates.append(new Candidate(PGListerals.WHEREKEYWORDS[i], "keywords"));
            }

            if (context.get_activation() == GtkSource.CompletionActivation.INTERACTIVE) {
                var ctx_class = buffer.get_context_classes_at_iter(begin);
                if ("string" in ctx_class || "comment" in ctx_class) {
                    return(new ObservableList<Candidate> ());
                }
            }



            model.model = candidates;

            return(model);
        }

        public void refilter (GtkSource.CompletionContext context, GLib.ListModel _model){
            var word = context.get_word();
            var strfilter = (Gtk.StringFilter) this.model.filter;
            strfilter.search = word;
        }

        private Vec<Candidate> get_columns (Table table){
            // foreach (var item in tabl)
            return(table.columns.map<Candidate> ((col) => {
                return new Candidate(col.name, "columns");
            }));
        }
    }
}
