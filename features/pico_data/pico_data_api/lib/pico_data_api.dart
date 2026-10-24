/// PICO data contract (C05 data ports, C08 settings).
///
/// Pure Dart. Features depend on this package only, never on
/// `pico_data_impl`, dio or JSON.
library;

export 'package:core_infrastructure_api/core_infrastructure_api.dart'
    show Either, Failure, Left, Right;

export 'src/models/archive_facts.dart';
export 'src/models/area.dart';
export 'src/models/cases.dart';
export 'src/models/content.dart';
export 'src/models/directory.dart';
export 'src/models/rt_method.dart';
export 'src/models/stats.dart';
export 'src/repositories/repositories.dart';
export 'src/repositories/settings.dart';
export 'src/repositories/snapshot.dart';
