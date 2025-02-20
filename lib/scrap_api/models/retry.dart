// ignore_for_file: empty_catches

import 'dart:async';

/// Run the [function] each time an exception is thrown until the retryCount
/// is 0.
Future<T> retry<T>(FutureOr<T> Function() function) async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    try {
      return await function();
      // ignore: avoid_catches_without_on_clauses
    } on Exception {}
  }
}
