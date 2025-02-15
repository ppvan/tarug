namespace Tarug {
    public class ExportService : Object {
        public const string DELIMETER = ",";
        public const string NEWLINE = "\n";

        public ExportService(){}

        public async void export_csv (File dest, Relation relation) throws TarugError {
            string[] rows = new string[relation.rows + 1];
            string[] cols = new string[relation.cols];

            // headers
            for (int j = 0; j < relation.cols; j++) {
                cols[j] = quote(relation.get_header(j));
            }
            rows[0] = string.joinv(DELIMETER, cols);

            for (int i = 0; i < relation.rows; i++) {
                cols = new string[relation.cols];
                var row = relation[i];
                for (int j = 0; j < relation.cols; j++) {
                    cols[j] = quote(row[j]);
                }

                rows[i + 1] = string.joinv(DELIMETER, cols);
            }

            var bytes = new Bytes.take(string.joinv(NEWLINE, rows).data);

            try {
                yield dest.replace_contents_bytes_async (bytes, null, false, FileCreateFlags.PRIVATE, null, null);
            } catch (GLib.Error err) {
                throw new TarugError.EXPORT_ERROR(err.message);
            }
        }

        private string quote (string str){
            return(Csv.quote(str));
        }
    }
}
