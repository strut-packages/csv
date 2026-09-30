include <csv>;

function main() -> int : CsvError {
    string[][] rows := csv_parse("name,role\r\nAda,engineer\r\nLin,designer");
    for (row : rows) {
        print(row[0]);
        print(row[1]);
    }
    return 0;
}
