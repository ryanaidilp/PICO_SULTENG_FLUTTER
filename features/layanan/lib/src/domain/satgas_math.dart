import 'package:layanan/src/domain/hospital_math.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Groups left after the kabupaten chip ([regencyCode], null for all) and the
/// search [query] (accent and case insensitive, on member or kabupaten name).
/// A group whose kabupaten name matches keeps all its members.
List<TaskForceGroup> filterTaskForces(
  List<TaskForceGroup> groups, {
  String? regencyCode,
  String query = '',
}) {
  final q = foldText(query.trim());
  return [
    for (final g in groups)
      if (regencyCode == null || g.regencyCode == regencyCode)
        if (q.isEmpty || foldText(g.regencyName).contains(q))
          g
        else if (g.members.any((m) => foldText(m.name).contains(q)))
          TaskForceGroup(
            regencyCode: g.regencyCode,
            regencyName: g.regencyName,
            members: [
              for (final m in g.members)
                if (foldText(m.name).contains(q)) m,
            ],
          ),
  ];
}
