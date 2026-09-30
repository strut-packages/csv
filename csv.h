include <filesystem>;

error CsvError {
    string message;
    int code;
}

struct CsvOptions {
    string delimiter;
    bool allow_lf;
    bool strip_utf8_bom;
    bool first_record_is_header;
    bool strict_row_length;
}

struct CsvDocument {
    string[] header;
    string[][] rows;
}

function csv_options() -> CsvOptions {
    return CsvOptions {
        delimiter: ",",
        allow_lf: true,
        strip_utf8_bom: true,
        first_record_is_header: false,
        strict_row_length: false
    };
}

function csv_internal_validate_options(CsvOptions options) -> void : CsvError {
    bytes delimiter := bytes.from_string(options.delimiter);
    if (delimiter.length() != 1 || delimiter[0] == 34 || delimiter[0] == 10 || delimiter[0] == 13) {
        throw CsvError { message: "delimiter must be one byte other than quote, CR, or LF", code: 1 };
    }
    return;
}

function csv_internal_decode_quoted(bytes input, int_64 begin, int_64 end) -> string {
    bytes decoded := bytes(end - begin);
    int_64 used := 0;
    int_64 cursor := begin;
    while (cursor < end) {
        if (input[cursor] == 34 && cursor + 1 < end && input[cursor + 1] == 34) {
            decoded[used] = 34;
            used++;
            cursor = cursor + 2;
        } else {
            decoded[used] = input[cursor];
            used++;
            cursor++;
        }
    }
    return decoded.slice(0, used).to_string();
}

function csv_parse_document(bytes input, CsvOptions options) -> CsvDocument : CsvError {
    csv_internal_validate_options(options);
    bytes delimiter_value := bytes.from_string(options.delimiter);
    uint_8 delimiter := delimiter_value[0];
    string[][] parsed_rows := [];
    int_64 length := input.length();
    int_64 index := 0;
    if (
    options.strip_utf8_bom
    && length >= 3
    && input[0] == 239
    && input[1] == 187
    && input[2] == 191
    ) {
        index = 3;
    }

    while (index < length) {
        string[] row := [];
        bool row_done := false;
        while (!row_done) {
            if (index == length) {
                row.push("");
                parsed_rows.push(row);
                row_done = true;
                continue;
            }

            if (input[index] == 34) {
                int_64 content_start := index + 1;
                index++;
                bool closed := false;
                while (index < length) {
                    if (input[index] == 34) {
                        if (index + 1 < length && input[index + 1] == 34) {
                            index = index + 2;
                            continue;
                        }
                        closed = true;
                        break;
                    }
                    index++;
                }
                if (!closed) {
                    throw CsvError { message: "unterminated quoted field", code: 2 };
                }
                int_64 content_end := index;
                index++;
                row.push(csv_internal_decode_quoted(input, content_start, content_end));

                if (index == length) {
                    parsed_rows.push(row);
                    row_done = true;
                } else if (input[index] == delimiter) {
                    index++;
                } else if (input[index] == 13) {
                    if (index + 1 >= length || input[index + 1] != 10) {
                        throw CsvError { message: "bare CR outside quoted field", code: 2 };
                    }
                    index = index + 2;
                    parsed_rows.push(row);
                    row_done = true;
                } else if (input[index] == 10) {
                    if (!options.allow_lf) {
                        throw CsvError { message: "LF record ending is disabled", code: 2 };
                    }
                    index++;
                    parsed_rows.push(row);
                    row_done = true;
                } else {
                    throw CsvError { message: "unexpected content after quoted field", code: 2 };
                }
                continue;
            }

            int_64 field_start := index;
            while (
            index < length
            && input[index] != delimiter
            && input[index] != 13
            && input[index] != 10
            ) {
                if (input[index] == 34) {
                    throw CsvError { message: "quote in unquoted field", code: 2 };
                }
                index++;
            }
            row.push(input.slice(field_start, index).to_string());

            if (index == length) {
                parsed_rows.push(row);
                row_done = true;
            } else if (input[index] == delimiter) {
                index++;
            } else if (input[index] == 13) {
                if (index + 1 >= length || input[index + 1] != 10) {
                    throw CsvError { message: "bare CR outside quoted field", code: 2 };
                }
                index = index + 2;
                parsed_rows.push(row);
                row_done = true;
            } else {
                if (!options.allow_lf) {
                    throw CsvError { message: "LF record ending is disabled", code: 2 };
                }
                index++;
                parsed_rows.push(row);
                row_done = true;
            }
        }
    }

    string[] header := [];
    string[][] rows := [];
    bool first := true;
    int_64 expected_columns := -1;
    for (row : parsed_rows) {
        if (first && options.first_record_is_header) {
            header = row;
            expected_columns = row.length();
            first = false;
            continue;
        }
        if (expected_columns < 0) {
            expected_columns = row.length();
        }
        if (options.strict_row_length && row.length() != expected_columns) {
            throw CsvError { message: "record length does not match expected column count", code: 3 };
        }
        rows.push(row);
        first = false;
    }

    return CsvDocument { header: header, rows: rows };
}

function csv_parse_bytes(bytes input) -> string[][] : CsvError {
    CsvDocument document := csv_parse_document(input, csv_options());
    return document.rows;
}

function csv_parse(string input) -> string[][] : CsvError {
    return csv_parse_bytes(bytes.from_string(input));
}

function csv_internal_encode_field(string field, uint_8 delimiter) -> string {
    bytes input := bytes.from_string(field);
    int_64 length := input.length();
    bool quote := false;
    int_64 quote_count := 0;
    for (int_64 index := 0; index < length; index++) {
        if (input[index] == 34) {
            quote = true;
            quote_count++;
        } else if (input[index] == delimiter || input[index] == 13 || input[index] == 10) {
            quote = true;
        }
    }
    if (!quote) {
        return field;
    }

    bytes output := bytes(length + quote_count + 2);
    int_64 used := 0;
    output[used] = 34;
    used++;
    for (int_64 index := 0; index < length; index++) {
        if (input[index] == 34) {
            output[used] = 34;
            used++;
        }
        output[used] = input[index];
        used++;
    }
    output[used] = 34;
    used++;
    return output.slice(0, used).to_string();
}

function csv_internal_stringify_row(string[] row, uint_8 delimiter) -> string {
    bytes delimiter_bytes := bytes(1);
    delimiter_bytes[0] = delimiter;
    string separator := delimiter_bytes.to_string();
    result := "";
    bool first := true;
    for (field : row) {
        if (!first) {
            result = result + separator;
        }
        if (row.length() == 1 && field == "") {
            result = result + "\"\"";
        } else {
            result = result + csv_internal_encode_field(field, delimiter);
        }
        first = false;
    }
    return result;
}

function csv_stringify_document(CsvDocument document, CsvOptions options) -> string : CsvError {
    csv_internal_validate_options(options);
    bytes delimiter_value := bytes.from_string(options.delimiter);
    uint_8 delimiter := delimiter_value[0];
    result := "";
    bool first_record := true;
    if (options.first_record_is_header && !document.header.empty()) {
        result = csv_internal_stringify_row(document.header, delimiter);
        first_record = false;
    }
    int_64 expected_columns := -1;
    if (!document.header.empty()) {
        expected_columns = document.header.length();
    }
    for (row : document.rows) {
        if (expected_columns < 0) {
            expected_columns = row.length();
        }
        if (options.strict_row_length && row.length() != expected_columns) {
            throw CsvError { message: "record length does not match expected column count", code: 3 };
        }
        if (!first_record) {
            result = result + "\r\n";
        }
        result = result + csv_internal_stringify_row(row, delimiter);
        first_record = false;
    }
    return result;
}

function csv_stringify(string[][] rows) -> string : CsvError {
    CsvDocument document := CsvDocument { header: [], rows: rows };
    return csv_stringify_document(document, csv_options());
}

function csv_read_document(string path, CsvOptions options) -> CsvDocument : (FilesystemError, CsvError) {
    return csv_parse_document(read_bytes(path), options);
}

function csv_read(string path) -> string[][] : (FilesystemError, CsvError) {
    return csv_parse_bytes(read_bytes(path));
}

function csv_write_document(
string path,
CsvDocument document,
CsvOptions options
) -> void : (FilesystemError, CsvError) {
    write_file(path, csv_stringify_document(document, options));
    return;
}

function csv_write(string path, string[][] rows) -> void : (FilesystemError, CsvError) {
    write_file(path, csv_stringify(rows));
    return;
}
