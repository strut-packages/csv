include <csv>;

function main() -> int : (FilesystemError, CsvError) {
    string[][] rows := csv_parse("name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");
    print(rows.length());
    print(rows[1][0]);
    print(rows[1][1]);
    print(rows[1][2] == "");
    print(rows[2][1]);
    print(csv_stringify(rows) == "name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");
    string[][] one_empty := [[""]];
    string empty_encoded := csv_stringify(one_empty);
    print(empty_encoded == "\"\"");
    string[][] empty_roundtrip := csv_parse(empty_encoded);
    print(empty_roundtrip.length());
    print(empty_roundtrip[0].length());
    print(empty_roundtrip[0][0] == "");
    print(csv_parse("").length());
    string[][] blank := csv_parse("\r\n");
    print(blank.length());
    print(blank[0].length());
    print(blank[0][0] == "");
    string[][] trailing := csv_parse("a,b,");
    print(trailing[0].length());
    print(trailing[0][2] == "");

    CsvOptions options := csv_options();
    options.delimiter = ";";
    options.first_record_is_header = true;
    options.strict_row_length = true;
    CsvDocument document := csv_parse_document(read_bytes("header.csv"), options);
    print(document.header.length());
    print(document.header[0]);
    print(document.header[1]);
    print(document.rows.length());
    print(document.rows[0][0]);
    print(document.rows[0][1]);

    CsvOptions keep_bom := csv_options();
    keep_bom.delimiter = ";";
    keep_bom.strip_utf8_bom = false;
    CsvDocument bom_document := csv_parse_document(read_bytes("header.csv"), keep_bom);
    print(bytes.from_string(bom_document.rows[0][0]).length());

    csv_write("copy.csv", rows);
    string[][] copied := csv_read("copy.csv");
    print(copied.length());
    print(copied[2][1]);

    try {
        csv_parse("a,\"unterminated");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv_parse("bad\"quote,x");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv_parse("\"ok\"trailing,x");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv_parse("a\rb");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions crlf_only := csv_options();
        crlf_only.allow_lf = false;
        csv_parse_document(bytes.from_string("a\nb"), crlf_only);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions invalid := csv_options();
        invalid.delimiter = "\"";
        csv_parse_document(bytes.from_string("a"), invalid);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions strict := csv_options();
        strict.strict_row_length = true;
        csv_parse_document(bytes.from_string("a,b\nonly-one\n"), strict);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }

    string[][] large := csv_read("large.csv");
    print(large.length());
    print(large[999][1]);
    return 0;
}
