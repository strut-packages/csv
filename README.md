# csv

Official buffered RFC 4180-oriented CSV support for Strut.

## API

```strut
options := csv.options();
rows := csv.parse(input);
rows := csv.parse_bytes(input_bytes);
document := csv.parse_document(input_bytes, options);
text := csv.stringify(rows);
text := csv.stringify_document(document, options);
rows := csv.read(path);
document := csv.read_document(path, options);
csv.write(path, rows);
csv.write_document(path, document, options);
```

## Usage

```strut
include <csv>;

function main() -> int : CsvError {
    string[][] rows := csv.parse("name,role\r\nAda,engineer");
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
