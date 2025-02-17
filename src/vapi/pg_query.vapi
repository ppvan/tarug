/*
 * Copyright (c) 2023 Phạm Văn Phúc <phuclaplace@gmail.com>
 */

[CCode (cprefix = "pg_query", cheader_filename = "pg_query.h")]
namespace PgQuery {
    [CCode (cname = "PgQueryError", destroy_function = "")]
    public struct Error {
        public string message;
        public string funcname;
        public string filename;
        public int lineno;
        public int cursorpos;
        public string context;
    }

    [CCode (cname = "PgQueryProtobuf", destroy_function = "")]
    public struct Protobuf {
        public size_t len;
        public string data;
    }

    [CCode (cname = "PgQueryScanResult", destroy_function = "pg_query_free_scan_result")]
    public struct ScanResult {
        public Protobuf pbuf;
        public string stderr_buffer;
        public Error* error;
    }

    [SimpleType]
    [CCode (cname = "PgQueryParseResult", destroy_function = "pg_query_free_parse_result", has_type_id = false)]
    public struct ParseResult {
        public string parse_tree;
        public string stderr_buffer;
        public Error* error;
    }

    [CCode (cname = "PgQueryProtobufParseResult", destroy_function = "pg_query_free_protobuf_parse_result")]
    public struct ProtobufParseResult {
        public Protobuf parse_tree;
        public string stderr_buffer;
        public Error* error;
    }

    [CCode (cname = "PgQuerySplitStmt", destroy_function = "")]
    public struct SplitStmt {
        public int stmt_location;
        public int stmt_len;
    }

    [SimpleType]
    [CCode (cname = "PgQuerySplitResult", destroy_function = "pg_query_free_split_result", has_type_id = false)]
    public struct SplitResult {
        public SplitStmt** stmts;
        public int n_stmts;
        public string stderr_buffer;
        public Error* error;
    }

    [CCode (cname = "PgQueryDeparseResult", destroy_function = "pg_query_free_deparse_result")]
    public struct DeparseResult {
        public string query;
        public Error* error;
    }

    [CCode (cname = "PgQueryPlpgsqlParseResult", destroy_function = "pg_query_free_plpgsql_parse_result")]
    public struct PlpgsqlParseResult {
        public string plpgsql_funcs;
        public Error* error;
    }

    [CCode (cname = "PgQueryFingerprintResult", destroy_function = "pg_query_free_fingerprint_result")]
    public struct FingerprintResult {
        public uint64 fingerprint;
        public string fingerprint_str;
        public string stderr_buffer;
        public Error* error;
    }

    [CCode (cname = "PgQueryNormalizeResult", destroy_function = "pg_query_free_normalize_result")]
    public struct NormalizeResult {
        public string normalized_query;
        public Error* error;
    }

    [CCode (cname = "PgQueryParseMode", cprefix = "PG_QUERY_PARSE_")]
    public enum ParseMode {
        DEFAULT,
        TYPE_NAME,
        PLPGSQL_EXPR,
        PLPGSQL_ASSIGN1,
        PLPGSQL_ASSIGN2,
        PLPGSQL_ASSIGN3
    }

    // Constants
    public const int PARSE_MODE_BITS;
    public const int PARSE_MODE_BITMASK;
    public const int DISABLE_BACKSLASH_QUOTE;
    public const int DISABLE_STANDARD_CONFORMING_STRINGS;
    public const int DISABLE_ESCAPE_STRING_WARNING;

    // Function bindings
    [CCode (cname = "pg_query_normalize")]
    public static NormalizeResult normalize(string input);

    [CCode (cname = "pg_query_normalize_utility")]
    public static NormalizeResult normalize_utility(string input);

    [CCode (cname = "pg_query_scan")]
    public static ScanResult scan(string input);

    [CCode (cname = "pg_query_parse")]
    public static ParseResult parse(string input);

    [CCode (cname = "pg_query_parse_opts")]
    public static ParseResult parse_opts(string input, int parser_options);

    [CCode (cname = "pg_query_parse_protobuf")]
    public static ProtobufParseResult parse_protobuf(string input);

    [CCode (cname = "pg_query_parse_protobuf_opts")]
    public static ProtobufParseResult parse_protobuf_opts(string input, int parser_options);

    [CCode (cname = "pg_query_parse_plpgsql")]
    public static PlpgsqlParseResult parse_plpgsql(string input);

    [CCode (cname = "pg_query_fingerprint")]
    public static FingerprintResult fingerprint(string input);

    [CCode (cname = "pg_query_fingerprint_opts")]
    public static FingerprintResult fingerprint_opts(string input, int parser_options);

    [CCode (cname = "pg_query_split_with_scanner")]
    public static SplitResult split_with_scanner(string input);

    [CCode (cname = "pg_query_split_with_parser")]
    public static SplitResult split_with_parser(string input);

    [CCode (cname = "pg_query_deparse_protobuf")]
    public static DeparseResult deparse_protobuf(Protobuf parse_tree);

    [CCode (cname = "pg_query_exit")]
    public static void exit();

    [CCode (cname = "PG_MAJORVERSION")]
    public const string MAJORVERSION;
    [CCode (cname = "PG_VERSION")]
    public const string VERSION;
    [CCode (cname = "PG_VERSION_NUM")]
    public const int VERSION_NUM;
}