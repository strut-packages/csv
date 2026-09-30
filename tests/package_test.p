include <csv>;

function main() -> int : (FilesystemError, CsvError) {
    string[][] rows := csv.parse("name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");
    print(rows.length());
    print(rows[1][0]);
    print(rows[1][1]);
    print(rows[1][2] == "");
    print(rows[2][1]);
    print(csv.stringify(rows) == "name,notes,empty\r\nAda,\"comma, quote \"\"ok\"\"\",\r\nLin,\"line one\nline two\",x");
    string[][] one_empty := [[""]];
    string empty_encoded := csv.stringify(one_empty);
    print(empty_encoded == "\"\"");
    string[][] empty_roundtrip := csv.parse(empty_encoded);
    print(empty_roundtrip.length());
    print(empty_roundtrip[0].length());
    print(empty_roundtrip[0][0] == "");
    print(csv.parse("").length());
    string[][] blank := csv.parse("\r\n");
    print(blank.length());
    print(blank[0].length());
    print(blank[0][0] == "");
    string[][] trailing := csv.parse("a,b,");
    print(trailing[0].length());
    print(trailing[0][2] == "");

    CsvOptions options := csv.options();
    options.delimiter = ";";
    options.first_record_is_header = true;
    options.strict_row_length = true;
    CsvDocument document := csv.parse_document(read_bytes("header.csv"), options);
    print(document.header.length());
    print(document.header[0]);
    print(document.header[1]);
    print(document.rows.length());
    print(document.rows[0][0]);
    print(document.rows[0][1]);

    CsvOptions keep_bom := csv.options();
    keep_bom.delimiter = ";";
    keep_bom.strip_utf8_bom = false;
    CsvDocument bom_document := csv.parse_document(read_bytes("header.csv"), keep_bom);
    print(bytes.from_string(bom_document.rows[0][0]).length());

    csv.write("copy.csv", rows);
    string[][] copied := csv.read("copy.csv");
    print(copied.length());
    print(copied[2][1]);

    try {
        csv.parse("a,\"unterminated");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv.parse("bad\"quote,x");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv.parse("\"ok\"trailing,x");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        csv.parse("a\rb");
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions crlf_only := csv.options();
        crlf_only.allow_lf = false;
        csv.parse_document(bytes.from_string("a\nb"), crlf_only);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions invalid := csv.options();
        invalid.delimiter = "\"";
        csv.parse_document(bytes.from_string("a"), invalid);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }
    try {
        CsvOptions strict := csv.options();
        strict.strict_row_length = true;
        csv.parse_document(bytes.from_string("a,b\nonly-one\n"), strict);
        print("missing error");
    } catch (CsvError err) {
        print(err.code);
    }

    string[][] large := csv.read("large.csv");
    print(large.length());
    print(large[999][1]);
    return 0;
}
