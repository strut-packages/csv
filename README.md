# csv

Official buffered RFC 4180-oriented CSV support for Strut.

## API

```strut
function csv_options() -> CsvOptions;
function csv_parse(string input) -> string[][] : CsvError;
function csv_parse_bytes(bytes input) -> string[][] : CsvError;
function csv_parse_document(bytes input, CsvOptions options) -> CsvDocument : CsvError;
function csv_stringify(string[][] rows) -> string : CsvError;
function csv_stringify_document(CsvDocument document, CsvOptions options) -> string : CsvError;
function csv_read(string path) -> string[][] : (FilesystemError, CsvError);
function csv_read_document(string path, CsvOptions options) -> CsvDocument : (FilesystemError, CsvError);
function csv_write(string path, string[][] rows) -> void : (FilesystemError, CsvError);
function csv_write_document(string path, CsvDocument document, CsvOptions options) -> void : (FilesystemError, CsvError);
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
