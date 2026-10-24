/// Notification permission state.
enum PushNotificationPermission() {
  /// User has granted permission.
  granted,

  /// User has denied permission.
  denied,

  /// Permission is granted provisionally (iOS 12+ quiet notifications).
  provisional,

  /// Permission has not been requested yet.
  notDetermined,
}
