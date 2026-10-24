import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:layanan/src/domain/satgas_math.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/watch_cubit.dart';
import 'package:layanan/src/presentation/ui/widgets/layanan_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

typedef SatgasCubit = WatchCubit<List<TaskForceGroup>>;

/// `/layanan/satgas`: task force contacts by kabupaten, expandable, with a
/// kabupaten chip row and a search field.
@RoutePage()
class SatgasPage extends StatefulWidget {
  const new({this.launcher, super.key});

  /// Opens a link. For tests.
  final UriLauncher? launcher;

  @override
  State<SatgasPage> createState() => _SatgasPageState();
}

class _SatgasPageState extends State<SatgasPage> {
  final _controller = TextEditingController();
  String _query = '';
  String? _regency;
  final _open = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SatgasCubit, WatchState<List<TaskForceGroup>>>(
        builder: (context, s) {
          final cubit = context.read<SatgasCubit>();
          final t = context.t;
          if (s.loading) return const PicoStateView.loading();
          final all = s.data;
          if (all == null) {
            void retry() => unawaited(cubit.refresh());
            return s.failure?.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry);
          }
          final groups = filterTaskForces(
            all,
            regencyCode: _regency,
            query: _query,
          );
          final k = PicoKitText.of(context);
          return RefreshIndicator.adaptive(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PageHeader(title: t.satgasTitle),
                const SizedBox(height: 8),
                ArchiveNote(text: t.satgasNote),
                const SizedBox(height: 12),
                PicoTextField(
                  controller: _controller,
                  label: t.satgasSearchLabel,
                  hint: t.satgasSearchHint,
                  textInputAction: TextInputAction.search,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: t.searchClear,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: Text(t.allRegencies),
                      selected: _regency == null,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() => _regency = null),
                    ),
                    for (final g in all)
                      ChoiceChip(
                        label: Text(g.regencyName),
                        selected: _regency == g.regencyCode,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: (_) =>
                            setState(() => _regency = g.regencyCode),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (all.isEmpty)
                  SizedBox(
                    height: 240,
                    child: PicoStateView.empty(message: t.noTaskforce),
                  )
                else if (groups.isEmpty)
                  SizedBox(
                    height: 240,
                    child: PicoStateView.empty(
                      message: t.noTaskforceMatch(query: _query.trim()),
                    ),
                  )
                else
                  for (final g in groups)
                    _Group(
                      group: g,
                      count: t.membersCount(count: k.number(g.members.length)),
                      // A filter or a search shows its result opened.
                      open:
                          _open.contains(g.regencyCode) ||
                          _regency != null ||
                          _query.trim().isNotEmpty,
                      onToggle: () => setState(() {
                        if (!_open.remove(g.regencyCode)) {
                          _open.add(g.regencyCode);
                        }
                      }),
                      launcher: widget.launcher,
                    ),
              ],
            ),
          );
        },
      );
}

class _Group extends StatelessWidget {
  const new({
    required this.group,
    required this.count,
    required this.open,
    required this.onToggle,
    required this.launcher,
  });

  final TaskForceGroup group;
  final String count;
  final bool open;
  final VoidCallback onToggle;
  final UriLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label:
                '${group.regencyName}, $count, ${open ? t.expanded : t.collapsed}',
            excludeSemantics: true,
            onTap: onToggle,
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.regencyName,
                            style: context.typography.heading.h5.copyWith(
                              color: context.colors.foreground.main,
                            ),
                          ),
                          Text(
                            count,
                            style: context.typography.body.small.copyWith(
                              color: context.colors.foreground.subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: context.colors.foreground.main,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            for (final m in group.members) ...[
              const Divider(height: 16),
              Text(
                m.name,
                style: context.typography.body.regular.copyWith(
                  color: context.colors.foreground.main,
                  fontWeight: FontWeight.w600,
                ),
              ),
              contactActions(m.contacts, launcher),
            ],
        ],
      ),
    );
  }
}
