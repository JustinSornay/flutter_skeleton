// value_matrix_table_test.dart
//
// Unit tests for ValueMatrixTable
// (lib/widgets/custom/ValueMatrix/controllers/matrix_table.dart): the pivot
// of per-column results, the visible rows, the sort (both directions, missing
// values last, ties in row order, null / unknown column) and the CSV (header,
// captions, missing values, RFC 4180 quoting).

import "package:flutter_skeleton/widgets/custom/ValueMatrix/index.dart";
import "package:flutter_test/flutter_test.dart";

const List<ValueMatrixRow> _rows = <ValueMatrixRow>[
  ValueMatrixRow(id: "a", label: "Alpha"),
  ValueMatrixRow(id: "b", label: "Beta"),
  ValueMatrixRow(id: "c", label: "Gamma"),
  ValueMatrixRow(id: "d", label: "Delta"),
];

const List<ValueMatrixColumn> _columns = <ValueMatrixColumn>[
  ValueMatrixColumn(id: "x", label: "X", caption: "+1"),
  ValueMatrixColumn(id: "y", label: "Y"),
];

/// x: a 0.5, b 0.9, c 0.5 — y: a 0.2, b 0.4 — d has no value, z is unlisted.
ValueMatrixTable _table() {
  return ValueMatrixTable(
    rows: _rows,
    columns: _columns,
    values: ValueMatrixTable.pivot(<String, Map<String, double>>{
      "x": <String, double>{"a": 0.5, "b": 0.9, "c": 0.5, "z": 1},
      "y": <String, double>{"a": 0.2, "b": 0.4},
    }),
  );
}

List<String> _ids(List<ValueMatrixRow> rows) => rows.map((ValueMatrixRow row) => row.id).toList();

String _fixed(double value) => value.toStringAsFixed(2);

void main() {
  group("pivot", () {
    test("turns column results into rowId → columnId → value", () {
      final Map<String, Map<String, double>> byRow = ValueMatrixTable.pivot(<String, Map<String, double>>{
        "x": <String, double>{"a": 1, "b": 2},
        "y": <String, double>{"a": 3},
      });
      expect(byRow, <String, Map<String, double>>{
        "a": <String, double>{"x": 1, "y": 3},
        "b": <String, double>{"x": 2},
      });
    });
  });

  group("valueOf / visibleRows", () {
    test("returns the value or null when missing", () {
      expect(_table().valueOf("a", "y"), 0.2);
      expect(_table().valueOf("c", "y"), isNull);
      expect(_table().valueOf("d", "x"), isNull);
    });

    test("hides rows without any value and ignores unlisted ids", () {
      expect(_ids(_table().visibleRows), <String>["a", "b", "c"]);
    });

    test("hides rows whose only values are in unlisted columns", () {
      final ValueMatrixTable table = ValueMatrixTable(
        rows: _rows,
        columns: const <ValueMatrixColumn>[ValueMatrixColumn(id: "y", label: "Y")],
        values: ValueMatrixTable.pivot(<String, Map<String, double>>{
          "x": <String, double>{"c": 1},
          "y": <String, double>{"a": 1},
        }),
      );
      expect(_ids(table.visibleRows), <String>["a"]);
    });
  });

  group("sortedRows", () {
    test("keeps the rows order without a sort column", () {
      expect(_ids(_table().sortedRows(null, ascending: false)), <String>["a", "b", "c"]);
    });

    test("keeps the rows order for an unknown column", () {
      expect(_ids(_table().sortedRows("nope", ascending: false)), <String>["a", "b", "c"]);
    });

    test("sorts descending with ties in rows order", () {
      expect(_ids(_table().sortedRows("x", ascending: false)), <String>["b", "a", "c"]);
    });

    test("sorts ascending with ties in rows order", () {
      expect(_ids(_table().sortedRows("x", ascending: true)), <String>["a", "c", "b"]);
    });

    test("puts missing values last in both directions", () {
      expect(_ids(_table().sortedRows("y", ascending: false)), <String>["b", "a", "c"]);
      expect(_ids(_table().sortedRows("y", ascending: true)), <String>["a", "b", "c"]);
    });

    test("keeps rows order among several missing values", () {
      final ValueMatrixTable table = ValueMatrixTable(
        rows: _rows,
        columns: _columns,
        values: ValueMatrixTable.pivot(<String, Map<String, double>>{
          "x": <String, double>{"a": 1, "b": 1, "c": 1},
          "y": <String, double>{"c": 0.1},
        }),
      );
      expect(_ids(table.sortedRows("y", ascending: false)), <String>["c", "a", "b"]);
    });
  });

  group("toCsv", () {
    test("writes the header and one line per row in the given order", () {
      final ValueMatrixTable table = _table();
      final String csv = table.toCsv(table.sortedRows("x", ascending: false), rowHeader: "Name", format: _fixed);
      expect(csv, "Name;X +1;Y\nBeta;0.90;0.40\nAlpha;0.50;0.20\nGamma;0.50;\n");
    });

    test("leaves the first header empty and skips empty captions", () {
      final ValueMatrixTable table = ValueMatrixTable(
        rows: _rows,
        columns: const <ValueMatrixColumn>[ValueMatrixColumn(id: "x", label: "X", caption: "")],
        values: ValueMatrixTable.pivot(<String, Map<String, double>>{
          "x": <String, double>{"a": 1},
        }),
      );
      expect(table.toCsv(table.visibleRows, rowHeader: "", format: _fixed), ";X\nAlpha;1.00\n");
    });

    test("quotes fields holding a separator, a quote or a line break", () {
      final ValueMatrixTable table = ValueMatrixTable(
        rows: const <ValueMatrixRow>[ValueMatrixRow(id: "a", label: "Line\nbreak")],
        columns: const <ValueMatrixColumn>[
          ValueMatrixColumn(id: "x", label: "A;B"),
          ValueMatrixColumn(id: "y", label: "Say \"hi\""),
        ],
        values: ValueMatrixTable.pivot(<String, Map<String, double>>{
          "x": <String, double>{"a": 1},
          "y": <String, double>{"a": 2},
        }),
      );
      final String csv = table.toCsv(
        table.visibleRows,
        rowHeader: "Head;er",
        format: (double value) => "v;$value",
      );
      expect(csv, "\"Head;er\";\"A;B\";\"Say \"\"hi\"\"\"\n\"Line\nbreak\";\"v;1.0\";\"v;2.0\"\n");
    });
  });
}
