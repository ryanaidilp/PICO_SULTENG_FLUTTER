import 'package:flutter/foundation.dart';
import 'package:pico_ui_kit/src/components/atoms/display/pico_countdown_timer.dart'
    show PicoCountdownTimer;

/// Controller for [PicoCountdownTimer] that provides pause, resume,
/// and reset capabilities.
///
/// ```dart
/// final controller = PicoCountdownController();
///
/// // In widget tree
/// PicoCountdownTimer.duration(
///   duration: Duration(minutes: 5),
///   controller: controller,
/// )
///
/// // Control
/// controller.pause();
/// controller.resume();
/// controller.reset();
/// ```
class PicoCountdownController() extends ChangeNotifier {
  _PicoCountdownControllerCallback? _callback;

  bool _isPaused = false;

  /// Whether the countdown is currently paused.
  bool get isPaused => _isPaused;

  /// Pauses the countdown timer.
  void pause() {
    _isPaused = true;
    _callback?.onPause();
    notifyListeners();
  }

  /// Resumes the countdown timer.
  void resume() {
    _isPaused = false;
    _callback?.onResume();
    notifyListeners();
  }

  /// Resets the countdown timer to the original duration.
  void reset() {
    _isPaused = false;
    _callback?.onReset();
    notifyListeners();
  }

  /// Starts the countdown timer manually.
  void start() {
    _isPaused = false;
    _callback?.onStart();
    notifyListeners();
  }
}

/// Internal callback interface for the countdown controller.
abstract class _PicoCountdownControllerCallback() {
  void onPause();
  void onResume();
  void onReset();
  void onStart();
}

/// Mixin for widget state to implement controller callbacks.
mixin PicoCountdownControllerMixin implements _PicoCountdownControllerCallback {
  /// Attaches the controller to this widget.
  void attachController(PicoCountdownController? controller) {
    controller?._callback = this;
  }

  /// Detaches the controller from this widget.
  void detachController(PicoCountdownController? controller) {
    controller?._callback = null;
  }
}
