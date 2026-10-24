import 'dart:io';

import 'package:monorepo_toolkit/src/command_runner.dart';

Future<void> main(List<String> args) async {
  await _flushThenExit(await MonorepoToolkitCommandRunner().run(args));
}

/// Flushes the stdout and stderr streams, then exits the program with the
/// given status code.
Future<void> _flushThenExit(int status) =>
    Future.wait<void>([stdout.close(), stderr.close()])
        .then<void>((_) => exit(status));
