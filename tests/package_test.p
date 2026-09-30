include <csv>;

function main() -> int : (FilesystemError, CsvError) {
    string[][] rows := csv_parse("name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");
    print(rows.length());
    print(rows[1][0]);
    print(rows[1][1]);
    print(rows[1][2] == "");
    print(rows[2][1]);
    print(csv_stringify(rows) == "name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");

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
