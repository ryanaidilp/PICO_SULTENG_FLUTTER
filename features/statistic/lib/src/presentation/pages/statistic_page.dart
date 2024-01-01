import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/blocs/blocs.dart';
import 'package:statistic/src/presentation/widgets/statistic_detail_section.dart';

@RoutePage()
class StatisticPage extends StatefulWidget {
  const StatisticPage({
    super.key,
  });

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _titleVisibilityNotifier;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_checkScrollOffset);
    _titleVisibilityNotifier = ValueNotifier(0);
  }

  void _checkScrollOffset() {
    if (_scrollController.hasClients) {
      _titleVisibilityNotifier.value =
          _scrollController.offset >= 20 ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollOffset);
    _titleVisibilityNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: _titleVisibilityNotifier,
          builder: (_, value, child) => AnimatedOpacity(
            opacity: value,
            duration: 300.milliseconds,
            child: child,
          ),
          child: BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestStatisticLoadedState(data: final data) =>
                  PicoUpdatedAtPlaceholder(
                    date: DateHelper.buildUpdatedAtText(
                      data.updatedAt.toLocal(),
                    ),
                    label: context.i10n.data_case_label,
                  ),
                LatestStatisticFailedState() => PicoUpdatedAtPlaceholder(
                    date: '-',
                    label: context.i10n.data_case_label,
                  ),
                _ => PicoUpdatedAtPlaceholder(
                    date: '12 December 2023 12.05 WITA',
                    label: context.i10n.data_case_label,
                  ).sekeletonize(),
              },
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          const StatisticDetailSection(),
          24.verticalSpace,
        ],
      ),
    );
  }
}
