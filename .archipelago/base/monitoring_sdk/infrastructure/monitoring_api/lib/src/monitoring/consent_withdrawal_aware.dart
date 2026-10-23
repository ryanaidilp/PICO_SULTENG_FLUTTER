/// Optional capability for monitoring implementations that hold data of their
/// own (buffers, offline caches, collection switches).
///
/// `ConsentAwareMonitoring` calls [onConsentWithdrawn] when diagnostics
/// consent is withdrawn after monitoring started. Unlike
/// `AppMonitoring.dispose`, which is an orderly shutdown and may flush what it
/// holds, this must stop collecting and discard buffered data without sending
/// it. A later grant calls `initialize` again.
///
/// Implementations that do not implement this get `dispose` instead.
abstract interface class ConsentWithdrawalAware() {
  /// Stop collecting and drop anything buffered, without sending it.
  Future<void> onConsentWithdrawn();
}
