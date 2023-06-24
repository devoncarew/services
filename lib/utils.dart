import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

Future<int> execLog(
  String executable,
  List<String> arguments,
  String cwd, {
  bool throwOnError = false,
}) async {
  print('$executable ${arguments.join(' ')}');

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: cwd,
  );
  process.stdout
      .transform<String>(utf8.decoder)
      .listen((string) => stdout.write(string));
  process.stderr
      .transform<String>(utf8.decoder)
      .listen((string) => stderr.write(string));

  final code = await process.exitCode;
  if (throwOnError && code != 0) {
    throw ProcessException(executable, arguments,
        'Error running ${[executable, ...arguments].take(2).join(' ')}', code);
  }
  return code;
}

typedef TaskFunction<T> = Future<T> Function();

class TaskScheduler {
  final Queue<_Task<dynamic>> _taskQueue = Queue<_Task<dynamic>>();
  bool _isActive = false;

  Future<T> execute<T>(TaskFunction<T> taskFn) {
    if (!_isActive) {
      _isActive = true;
      return taskFn().whenComplete(_next);
    }
    final taskResult = Completer<T>();
    _taskQueue.add(_Task<T>(taskFn, taskResult));
    return taskResult.future;
  }

  void _next() {
    assert(_isActive);
    if (_taskQueue.isEmpty) {
      _isActive = false;
      return;
    }
    final first = _taskQueue.removeFirst();
    first.taskResult.complete(first.taskFn().whenComplete(_next));
  }
}

class _Task<T> {
  final TaskFunction<T> taskFn;
  final Completer<T> taskResult;

  _Task(this.taskFn, this.taskResult);
}
