import 'package:args/command_runner.dart';
import 'package:size_analyzer/src/commands/analyze_command.dart';
import 'package:size_analyzer/src/commands/update_baseline_command.dart';

class SizeAnalyzerCommand() extends Command<int> {
  this {
    addSubcommand(AnalyzeCommand());
    addSubcommand(UpdateBaselineCommand());
  }

  @override
  String get name => 'size-analyzer';

  @override
  String get description =>
      'Analyze Flutter --analyze-size output and compare against a develop baseline.';
}
