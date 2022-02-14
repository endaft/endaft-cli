import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:tint/tint.dart';
import 'package:collection/collection.dart';

import 'log_pipe.dart';

/// The function shape for [Logger] change notification.
typedef LogChangeNotifier = void Function();

/// A callback for external process finalization
typedef ProcessFinalizer = void Function(int code);

/// The function shape `fixed` printed results.
typedef SuccessClosure = bool Function(bool success, [String? reason]);

/// The function shape for log entry closures.
/// The call must indicate the [success] which will translate to a log icon,
/// the optional [reason] will be printed with the icon, if provided.
/// Additionally, an explicit [icon] can be provided, as can additional [outputs]
/// and [errors] which will be printed to their respective streams.
typedef LogEntryClosure = bool Function(
  bool success, {
  String? reason,
  LogIcon? icon,
  int? exitCode,
  ProcessFinalizer? finalizer,
  Iterable<String> outputs,
  Iterable<String> errors,
});

/// The supported types of [LogEntry].
enum LogEntryType { stdout, stderr }

/// Supported logging icons
enum LogIcon { success, warn, fail, info, cached, skipped, complete }

/// A map of [LogIcon] to emoji characters
const _loggingIcons = <LogIcon, String>{
  LogIcon.cached: '🪣',
  LogIcon.complete: '🏁',
  LogIcon.fail: '🔴',
  LogIcon.info: '🔵',
  LogIcon.skipped: '🔪',
  LogIcon.success: '🟢',
  LogIcon.warn: '🟡',
};

/// The base definition of a [_LogController] supporting an indent level.
abstract class _LogController {
  _LogController([this.indentSize = 0, this.childIndentSize = 3]) {
    _indent = ''.padLeft(indentSize);
  }

  /// Localized storage for loggers.
  final List<Logger> _loggers = [];

  /// The size of the indent;
  final int indentSize;

  /// The indent size for [slice]d loggers.
  final int childIndentSize;

  /// The entry indent for this instance.
  late final String _indent;

  /// Handles [Logger] change notifications.
  void onLoggerChanged();

  /// Creates a new monitored [Logger].
  Logger slice([int? indentOverride]) {
    final logger = Logger(
      onLoggerChanged,
      indentOverride ?? (indentSize + childIndentSize),
    );
    _loggers.add(logger);
    return logger;
  }

  /// Creates a new monitored [Logger].
  Logger rootSlice() {
    return slice(0);
  }
}

/// Controls multiple [Logger] instances against a common output.
class LogController extends _LogController {
  LogController() : super();

  final Coordinate? initCoords = _getCursorPosition();

  /// Handles [Logger] change notifications.
  @override
  Future<void> onLoggerChanged() async {
    await _updateConsole();
  }

  /// Returns the current cursor position as a coordinate.
  ///
  /// Warning: Linux and macOS terminals report their cursor position by
  /// posting an escape sequence to stdin in response to a request. However,
  /// if there is lots of other keyboard input at the same time, some
  /// terminals may interleave that input in the response. There is no
  /// easy way around this; the recommendation is therefore to use this call
  /// before reading keyboard input, to get an original offset, and then
  /// track the local cursor independently based on keyboard input.
  ///
  ///
  static Coordinate? _getCursorPosition() {
    final echoMode = stdin.echoMode;
    final lineMode = stdin.lineMode;
    stdin.echoMode = stdin.lineMode = false;
    const ansiDeviceStatusReportCursorPosition = '\x1b[6n\n';
    stdout.write(ansiDeviceStatusReportCursorPosition);

    // returns a Cursor Position Report result in the form <ESC>[24;80R
    // which we have to parse apart, unfortunately
    var result = '';
    var i = 0;

    // avoid infinite loop if we're getting a bad result
    while (i < 16) {
      final readByte = stdin.readByteSync();

      if (readByte == -1) break; // headless console may not report back

      // ignore: use_string_buffers
      result += String.fromCharCode(readByte);
      if (result.endsWith('R')) break;
      i++;
    }
    stdin.echoMode = echoMode;
    stdin.lineMode = lineMode;

    if (result[0] != '\x1b') {
      print(' result: $result  result.length: ${result.length}');
      return null;
    }

    result = result.substring(2, result.length - 1);
    final coords = result.split(';');

    if (coords.length != 2) {
      print(' coords.length: ${coords.length}');
      return null;
    }
    if ((int.tryParse(coords[0]) != null) &&
        (int.tryParse(coords[1]) != null)) {
      return Coordinate(int.parse(coords[0]) - 1, int.parse(coords[1]) - 1);
    } else {
      print(' coords[0]: ${coords[0]}   coords[1]: ${coords[1]}');
      return null;
    }
  }

  bool _updating = false;

  /// Updates the active console with the available entries.
  Future<void> _updateConsole() async {
    while (_updating) {
      await Future.delayed(Duration(milliseconds: 50));
    }

    _updating = true;
    final ansiClearToEnd = '\x1b[0K';
    final ansiHome = '\x1B[${initCoords?.row};0H';
    stdout.write('$ansiHome\x1b[0J');

    try {
      for (final logger in _loggers) {
        for (final entry in logger.render()) {
          stdout.writeln(entry.trimRight() + ansiClearToEnd);
        }
      }
    } finally {
      _updating = false;
    }
  }

  /// Writes a [message] to [stdout] without additional formatting or line ending.
  void printOut(String message) {
    stdout.write(message);
  }

  /// Writes a [message] to [stderr] without additional formatting or line ending.
  void printErr(String message) {
    stderr.write(message);
  }
}

/// A logger holding buffers of entries to be written.
class Logger extends _LogController {
  Logger(this._onChange, int indent, {this.encoding = utf8}) : super(indent);

  /// A handle to an party interested in changes to this log.
  final LogChangeNotifier _onChange;

  /// The encoding used to store the [value].
  final Encoding encoding;

  /// Localized storage for the underlying [LogEntry] instances.
  final List<LogEntry> _entries = [];

  /// Access to the [stdout] buffer.
  List<LogEntry> get stdout => UnmodifiableListView(
        _entries.where((e) => e.type == LogEntryType.stdout),
      );

  /// Access to the [stderr] buffer.
  List<LogEntry> get stderr => UnmodifiableListView(
        _entries.where((e) => e.type == LogEntryType.stderr),
      );

  /// The padding value used for [fixed] messages.
  final _padding = "....................................................";

  /// Gets the appropriate padding for a [fixed] message based on it's ANSI stripped length.
  _getPad(int length) {
    return length > _padding.length ? '' : _padding.substring(length);
  }

  /// Underlying closed state storage.
  bool _isClosed = false;

  /// Access to the closed state.
  bool get isClosed => _isClosed;

  @override
  void onLoggerChanged() {
    _onChange();
  }

  /// Closes the [Logger] preventing any further writes. After calling this
  /// the underlying [LogEntry] instances will be summarized; collapsible entries
  /// will be omitted from subsequent rendering. For convenience, a [value] can
  /// be passed int to be returned.
  T? close<T>([T? value]) {
    _isClosed = true;
    _entries.removeWhere((e) => e.collapse);
    for (final logger in _loggers) {
      logger.close();
    }
    return value;
  }

  /// Adjust a [LogEntry] by [index]. Throws a [RangeError] if the index does not exist.
  void _adjust(int index, {String? message, bool? collapse}) {
    if (index < 0 || index > _entries.length) {
      throw RangeError('Cannot adjust a non-existent entry.');
    }

    final oldEntry = _entries[index];
    final collapsible = collapse ?? oldEntry.collapse;
    final value = message != null ? encoding.encode(message) : oldEntry.value;
    final newEntry = LogEntry(
      value,
      oldEntry.type,
      oldEntry.indent,
      time: oldEntry.time,
      collapse: collapsible,
    );
    _entries[index] = newEntry;
    _onChange();
  }

  List<LogEntry> _getAllEntries() {
    return List<LogEntry>.from(
      [..._entries, ..._loggers.map((l) => l._getAllEntries()).flattened],
    );
  }

  /// Streams each underlying entry as a decoded [String], followed by the
  /// entries from each sliced logger, if any exist.
  List<String> render() {
    final entries = _getAllEntries();
    return entries
        .map((e) => e.render(encoding: encoding))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Prints a fixed length [message], padded with trailing dots (...).
  SuccessClosure fixed(String message, {bool collapse = false}) {
    final visLen = message.strip().length;
    final fixedMessage = "$message${_getPad(visLen + _indent.length)}";
    final index = _addEntry(LogEntry(
      encoding.encode(fixedMessage),
      LogEntryType.stdout,
      _indent.length,
      collapse: collapse,
    ));
    return (bool success, [String? reason]) {
      final icon = getIcon(success ? LogIcon.success : LogIcon.fail);
      _adjust(
        index,
        message: '$fixedMessage$icon ${reason ?? ''}'.trimRight(),
      );
      return success;
    };
  }

  /// Prints a collapsible skipped message.
  void cached([String? message = '']) {
    final icon = getIcon(LogIcon.cached);
    printLine("$icon $message".trimRight(), true);
  }

  /// Prints a collapsible skipped message.
  void skip([String? message = '']) {
    final icon = getIcon(LogIcon.skipped);
    printLine("$icon $message".trimRight(), true);
  }

  /// Prints a collapsible info message.
  void success([String? message = '']) {
    final icon = getIcon(LogIcon.success);
    printLine("$icon $message".trimRight(), true);
  }

  /// Prints a collapsible info message.
  void info([String? message = '']) {
    final icon = getIcon(LogIcon.info);
    printLine("$icon $message".trimRight(), true);
  }

  /// Prints a non-collapsible warning message.
  void warn([String? message = '']) {
    final icon = getIcon(LogIcon.warn);
    printLine("$icon $message".trimRight(), false);
  }

  /// Prints a non-collapsible warning message.
  void error([String? message = '']) {
    final icon = getIcon(LogIcon.fail);
    printLine("$icon $message".trimRight(), false);
  }

  /// Adds a [LogEntry] and returns a method for adjusting later.
  LogEntryClosure memo(String message, {bool collapse = true}) {
    if (isClosed) {
      throw StateError('A closed logger cannot accept new messages.');
    }

    final index = _addEntry(LogEntry(
      encoding.encode(message),
      LogEntryType.stdout,
      _indent.length,
      collapse: collapse,
    ));

    return (
      bool success, {
      String? reason,
      LogIcon? icon,
      int? exitCode,
      ProcessFinalizer? finalizer,
      Iterable<String> outputs = const [],
      Iterable<String> errors = const [],
    }) {
      final fallback = getIcon(success ? LogIcon.success : LogIcon.fail);
      final iconChar = getIcon(icon) ?? fallback;
      _adjust(
        index,
        message:
            '${'$message $iconChar'.trimRight()} ${reason ?? ''}'.trimRight(),
        collapse: collapse && success,
      );
      for (final e in outputs) {
        passThru(e);
      }
      for (final e in errors) {
        passThru(e, collapse: false);
      }
      if (finalizer != null && exitCode != null) finalizer(exitCode);
      return success;
    };
  }

  /// Gets an icon character for the specified [icon].
  /// Returns an empty string if [icon] is `null` or cannot be found.
  String? getIcon(LogIcon? icon) => icon != null ? _loggingIcons[icon] : '';

  /// Internally adds an [entry] and returns the index.
  int _addEntry(LogEntry entry) {
    _entries.add(entry);
    _onChange();
    return _entries.indexOf(entry);
  }

  /// Prints the [message] provided after trimming whitespace from each line.
  /// By default, these lines will [collapse] and that can be disabled.
  void passThru(String message, {bool collapse = true}) {
    forPassThru(message, collapse: collapse).forEach((line) {
      printLine(line, collapse);
    });
  }

  /// Prints the [message] provided after trimming whitespace from each line.
  /// By default, these lines will [collapse] and that can be disabled.
  List<String> forPassThru(String message, {bool collapse = true}) {
    if (message.isEmpty) return [];
    final lfp = RegExp(r'\n|\r');
    return message
        .trim()
        .split(lfp)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Gets a [LogPipe] suitable to piping [stdout] or [stderr] from external
  /// processes. These messages can optionally [collapse] and by default will.
  LogPipe pipe({bool collapse = true}) {
    return LogPipe(((message) => passThru(message, collapse: collapse)));
  }

  /// Gets a [LogPipe] suitable to piping [stderr] from external processes.
  /// These messages can optionally [collapse] and by default will not.
  LogPipe pipeErr({bool collapse = false}) {
    final index = _addEntry(
      LogEntry(
        <int>[],
        LogEntryType.stdout,
        _indent.length,
        collapse: collapse,
      ),
    );
    return LogPipe(((message) => _adjust(
          index,
          message: forPassThru(message).lastOrNull ?? '',
        )));
  }

  /// Gets a [LogPipe] suitable to piping [stdout] from external processes.
  /// These messages can optionally [collapse] and by default will.
  LogPipe pipeOut({bool collapse = true}) {
    final index = _addEntry(
      LogEntry(
        <int>[],
        LogEntryType.stderr,
        _indent.length,
        collapse: collapse,
      ),
    );
    return LogPipe(((message) => _adjust(
          index,
          message: forPassThru(message).lastOrNull ?? '',
        )));
  }

  /// Print an optional [message] to [stdout] followed by a new line.
  /// This [message] will [collapse] by default, that can be disabled.
  void printLine([String message = '', bool collapse = true]) {
    printOut("$message\n", collapse: collapse);
  }

  /// Writes a [message] to [stdout] without additional formatting or line ending.
  /// If this [Logger] is closed, this throws a [StateError].
  void printOut(String message, {bool collapse = true}) {
    if (isClosed) {
      throw StateError('A closed logger cannot accept new messages.');
    }

    _addEntry(LogEntry(
      encoding.encode(message),
      LogEntryType.stdout,
      _indent.length,
      collapse: collapse,
    ));
  }

  /// Writes a [message] to [stderr] without additional formatting or line
  /// ending. If this [Logger] is closed, this throws a [StateError].
  /// Error entries are never collapsible.
  void printErr(String message) {
    if (isClosed) {
      throw StateError('A closed logger cannot accept new messages.');
    }

    _addEntry(LogEntry(
      encoding.encode(message),
      LogEntryType.stderr,
      _indent.length,
      collapse: false,
    ));
  }
}

/// A single entry in a log.
class LogEntry extends Comparable<LogEntry> {
  LogEntry(
    this.value,
    this.type,
    this.indent, {
    DateTime? time,
    this.collapse = true,
  }) {
    this.time = time ?? DateTime.now();
  }

  /// If the entry can collapse (gets removed), or not.
  final bool collapse;

  /// The expected output type for this entry.
  final LogEntryType type;

  /// The encoded value of the entry.
  final List<int> value;

  /// The indent size used for rendering.
  final int indent;

  /// The timestamp for this entry.
  late final DateTime time;

  /// Returns the decoded [String] for this entry.
  String render({Encoding encoding = utf8}) {
    if (value.isEmpty) return '';

    final content = encoding.decode(value);
    final logTime = time.toIso8601String().split('T').last.padRight(15, '0');

    return '${'[$logTime]'.gray().dim()} ${''.padLeft(indent)}$content';
  }

  @override
  int compareTo(LogEntry other) {
    return time.compareTo(other.time);
  }
}

/// A screen position, measured in rows and columns from the top-left origin
/// of the screen. Coordinates are zero-based, and converted as necessary
/// for the underlying system representation (e.g. one-based for VT-style
/// displays).
class Coordinate {
  final int row;
  final int col;

  const Coordinate(this.row, this.col);
}
