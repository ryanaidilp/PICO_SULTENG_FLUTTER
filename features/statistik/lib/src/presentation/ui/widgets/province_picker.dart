import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/province_math.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/watch_cubit.dart';

/// Cubit of the 34 province summaries.
typedef ProvincesCubit = WatchCubit<List<AreaSummary>>;

/// Opens the searchable province list. [onPick] gets the province id.
Future<void> showProvinceSheet(
  BuildContext context, {
  required String? selectedId,
  required ValueChanged<String> onPick,
}) {
  final cubit = context.read<ProvincesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    // The sheet lives in the root overlay, outside this feature's translation
    // provider (only one can exist), so the strings travel as a value.
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: ProvinceSheet(
        t: context.t,
        selectedId: selectedId,
        onPick: onPick,
      ),
    ),
  );
}

/// The list of provinces with a search field. Sulawesi Tengah is first.
class ProvinceSheet extends StatefulWidget {
  const ProvinceSheet({
    required this.t,
    required this.selectedId,
    required this.onPick,
    super.key,
  });

  final Translations t;
  final String? selectedId;
  final ValueChanged<String> onPick;

  @override
  State<ProvinceSheet> createState() => _ProvinceSheetState();
}

class _ProvinceSheetState extends State<ProvinceSheet> {
  String _query = '';

  void _pick(String id) {
    Navigator.of(context).pop();
    widget.onPick(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final k = PicoKitText.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: BlocBuilder<ProvincesCubit, WatchState<List<AreaSummary>>>(
        builder: (context, s) {
          final all = s.data;
          if (s.loading) return const PicoStateView.loading();
          if (all == null) {
            return PicoStateView.error(
              message: t.provinceLoadingFailed,
              onRetry: () => context.read<ProvincesCubit>().refresh(),
            );
          }
          final rows = orderProvinces(all, query: _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: PicoTextField(
                  label: t.provinceSearchLabel,
                  hint: t.provinceSearchHint,
                  textInputAction: TextInputAction.search,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? PicoStateView.empty(
                        message: t.provinceNone(query: _query.trim()),
                      )
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          final id = (r.area as ProvinceArea).id;
                          final selected = id == widget.selectedId;
                          final positive = t.provincePositive(
                            value: k.number(r.latest.cumulative.positive),
                          );
                          return Semantics(
                            button: true,
                            selected: selected,
                            label:
                                '${r.name}, $positive${selected ? ', ${t.provinceSelected}' : ''}',
                            excludeSemantics: true,
                            onTap: () => _pick(id),
                            child: InkWell(
                              onTap: () => _pick(id),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.name,
                                              style: context
                                                  .typography
                                                  .heading
                                                  .h5
                                                  .copyWith(
                                                    color: context
                                                        .colors
                                                        .foreground
                                                        .main,
                                                  ),
                                            ),
                                            Text(
                                              positive,
                                              style: context
                                                  .typography
                                                  .body
                                                  .small
                                                  .copyWith(
                                                    color: context
                                                        .colors
                                                        .foreground
                                                        .subtle,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (selected)
                                        Icon(
                                          Icons.check,
                                          color: context.colors.foreground.main,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
