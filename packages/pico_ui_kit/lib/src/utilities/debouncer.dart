import 'dart:async';

import 'package:flutter/foundation.dart';

/// A simple debouncer that delays execution.
class Debouncer({required final int milliseconds}) {
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
  bool get isPending => _timer?.isActive ?? false;
}
