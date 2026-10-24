import 'package:size_analyzer/src/models/size_node.dart';

/// Optional hook for sending size metrics to an external service.
///
/// Implement this and pass it to `SizeAnalyzerService` to forward data to
/// Prometheus, Datadog, Firebase, or any other backend. Default is no-op.
abstract class const SizeMetricsReporter() {
  Future<void> report({
    required String platform,
    required List<SizeNode> nodes,
    required String? version,
  });
}

class const NoopSizeMetricsReporter() extends SizeMetricsReporter {
  @override
  Future<void> report({
    required String platform,
    required List<SizeNode> nodes,
    required String? version,
  }) async {}
}
