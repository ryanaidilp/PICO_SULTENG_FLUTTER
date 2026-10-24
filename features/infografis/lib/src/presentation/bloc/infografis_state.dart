import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// The infographics loaded so far, newest first.
final class InfografisState extends Equatable {
  const new({
    this.items = const [],
    this.loadedPages = 0,
    this.hasNext = false,
    this.loading = true,
    this.loadingMore = false,
    this.failure,
    this.fetchedAt,
    this.isStale = false,
  });

  /// Items of every loaded page, in page order.
  final List<Infographic> items;

  /// How many pages are loaded.
  final int loadedPages;

  /// Whether the last loaded page says there is a next one.
  final bool hasNext;

  /// True until the first page arrives.
  final bool loading;

  /// True while a later page loads.
  final bool loadingMore;

  /// Failure of the first page with no saved copy, or of a later page.
  final PicoFailure? failure;

  /// When the newest page was fetched.
  final DateTime? fetchedAt;

  /// Whether the newest page came from a stale copy.
  final bool isStale;

  /// Item by id, or null.
  Infographic? byId(int id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  InfografisState copyWith({
    List<Infographic>? items,
    int? loadedPages,
    bool? hasNext,
    bool? loading,
    bool? loadingMore,
    PicoFailure? failure,
    bool clearFailure = false,
    DateTime? fetchedAt,
    bool? isStale,
  }) => InfografisState(
    items: items ?? this.items,
    loadedPages: loadedPages ?? this.loadedPages,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: clearFailure ? null : failure ?? this.failure,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isStale: isStale ?? this.isStale,
  );

  @override
  List<Object?> get props => [
    items,
    loadedPages,
    hasNext,
    loading,
    loadingMore,
    failure,
    fetchedAt,
    isStale,
  ];
}
