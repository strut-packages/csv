# csv

Official buffered RFC 4180-oriented CSV support for Strut.

## API

```strut
CsvOptions csv_options();
string[][] csv_parse(string input) : CsvError;
string[][] csv_parse_bytes(bytes input) : CsvError;
CsvDocument csv_parse_document(bytes input, CsvOptions options) : CsvError;
string csv_stringify(string[][] rows) : CsvError;
string csv_stringify_document(CsvDocument document, CsvOptions options) : CsvError;
string[][] csv_read(string path) : (FilesystemError, CsvError);
CsvDocument csv_read_document(string path, CsvOptions options) : (FilesystemError, CsvError);
void csv_write(string path, string[][] rows) : (FilesystemError, CsvError);
void csv_write_document(string path, CsvDocument document, CsvOptions options) : (FilesystemError, CsvError);
```

## Usage

```strut
include <csv>;

function main() -> int : CsvError {
    string[][] rows := csv_parse("name,role\r\nAda,engineer");
    print(rows[1][0]);
    return 0;
}
```

## v0.1 contract

- Quoted fields, doubled quotes, delimiters, CRLF, LF, embedded newlines, empty fields, and final records without terminators are supported.
- The delimiter is a one-byte string and configurable through `CsvOptions`.
- Stringification emits CRLF between records with no trailing record terminator.
- UTF-8 BOM stripping is enabled by default and configurable.
- Field bytes, including valid or invalid UTF-8, are preserved without normalization.
- Header mode extracts the first record into an ordered array. Empty and duplicate header names are preserved.
- Variable row lengths are accepted by default. `strict_row_length` rejects mismatches using the first record or header width.
- Malformed quoting, invalid record endings, invalid delimiters, and strict row-length mismatches raise `CsvError` with stable numeric categories.

Parsing and writing are buffered. Streaming, Unicode delimiters, schema inference, automatic type conversion, and map-shaped header records are deliberately deferred.

## Test

```sh
python3 tests/run.py --strut /path/to/strut
```
