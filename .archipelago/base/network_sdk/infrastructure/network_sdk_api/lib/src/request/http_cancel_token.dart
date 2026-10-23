import 'package:dependencies_core/meta.dart';

/// Cancels the requests it is passed to through `RequestOptions.cancelToken`.
///
/// A cancelled request throws `HttpCancelledException`, whether it was
/// cancelled before it started or while it was in flight. Cancelling after a
/// request completed does nothing. A token stays cancelled: create a new one
/// for the next request.
///
/// Typical owner: a Cubit/Bloc/Notifier keeps one token and cancels it when
/// it closes, so every request it started is aborted at the transport.
class HttpCancelToken() {
  final _listeners = <void Function()>{};
  bool _isCancelled = false;
  String? _reason;

  /// Whether [cancel] was called.
  bool get isCancelled => _isCancelled;

  /// The reason given to the first [cancel] call.
  String? get reason => _reason;

  /// Listeners still attached; for tests that check settled requests detach.
  @visibleForTesting
  int get listenerCount => _listeners.length;

  /// Cancels every request using this token. Only the first call counts.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    final listeners = List.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// Calls [listener] once on [cancel], or at once if already cancelled.
  ///
  /// Returns a function that detaches [listener]. Adapters detach when the
  /// request settles, so a long-lived token holds no callback per finished
  /// request.
  void Function() onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }
}
