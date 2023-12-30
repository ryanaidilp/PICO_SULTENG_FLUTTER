import 'package:dependencies/dependencies.dart';

class Failure extends Equatable {
  const Failure({
    required this.message,
  });
  final String message;

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}
