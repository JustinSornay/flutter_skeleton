// utf8_lines_test.dart
//
// Unit tests for frameUtf8Lines, the shared front end of the stream
// transformers: lines reach the framer, errors of the byte stream are
// forwarded, and invalid UTF-8 ends the stream (FormatException, then done)
// without closing the framer and cancels the byte stream.

import "dart:async";
import "dart:convert";

import "package:flutter_skeleton/api/http/transformers/utf8_lines.dart";
import "package:flutter_test/flutter_test.dart";

/// Emits each line as `{"line": line}`, and `{"closed": true}` when closed.
final class _RecordingFramer implements Sink<String> {
  final EventSink<Map<String, dynamic>> _out;

  _RecordingFramer(this._out);

  @override
  void add(String line) {
    _out.add(<String, dynamic>{"line": line});
  }

  @override
  void close() {
    _out
      ..add(<String, dynamic>{"closed": true})
      ..close();
  }
}

void main() {
  group("well-formed body", _wellFormed);
  group("invalid UTF-8", _invalidUtf8);
}

void _wellFormed() {
  test("feeds every line to the framer, then closes it", () async {
    final Stream<Map<String, dynamic>> lines = frameUtf8Lines(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode("a\r\nb"), utf8.encode("c\rd")]),
      _RecordingFramer.new,
    );

    expect(await lines.toList(), <Map<String, dynamic>>[
      <String, dynamic>{"line": "a"},
      <String, dynamic>{"line": "bc"},
      <String, dynamic>{"line": "d"},
      <String, dynamic>{"closed": true},
    ]);
  });

  test("forwards errors of the byte stream and keeps going", () async {
    final StreamController<List<int>> body = StreamController<List<int>>();
    final Future<void> expectation = expectLater(
      frameUtf8Lines(body.stream, _RecordingFramer.new),
      emitsInOrder(<Object>[
        <String, dynamic>{"line": "a"},
        emitsError(isStateError),
        <String, dynamic>{"line": "b"},
        <String, dynamic>{"closed": true},
        emitsDone,
      ]),
    );

    body
      ..add(utf8.encode("a\n"))
      ..addError(StateError("connection reset"))
      ..add(utf8.encode("b\n"));
    await body.close();
    await expectation;
  });
}

void _invalidUtf8() {
  test("emits a FormatException, ends the stream and cancels the body", () async {
    bool cancelled = false;
    final StreamController<List<int>> body = StreamController<List<int>>(onCancel: () => cancelled = true);
    final Future<void> expectation = expectLater(
      frameUtf8Lines(body.stream, _RecordingFramer.new),
      emitsInOrder(<Object>[
        <String, dynamic>{"line": "a"},
        emitsError(isFormatException),
        emitsDone,
      ]),
    );

    // The chunk "b\xFF\n" is dropped whole, and "c" is never emitted.
    body
      ..add(utf8.encode("a\n"))
      ..add(<int>[0x62, 0xFF, 0x0A])
      ..add(utf8.encode("c\n"));
    await expectation;
    expect(cancelled, isTrue);
    await body.close();
  });

  test("on a body that stops inside a character, does not close the framer", () async {
    // A closed framer would emit "caf" and then {"closed": true}.
    await expectLater(
      frameUtf8Lines(
        Stream<List<int>>.fromIterable(<List<int>>[<int>[...utf8.encode("a\ncaf"), 0xC3]]),
        _RecordingFramer.new,
      ),
      emitsInOrder(<Object>[<String, dynamic>{"line": "a"}, emitsError(isFormatException), emitsDone]),
    );
  });
}
