part of 'all_national_statistic_filter_cubit.dart';

@immutable
class AllNationalStatisticFilterState extends Equatable {
  const AllNationalStatisticFilterState({
    required this.lastItem,
    this.hoveredItem,
    this.year,
  });

  factory AllNationalStatisticFilterState.fromJson(JSON json) =>
      AllNationalStatisticFilterState(
        lastItem: StatisticModel.fromJson(json['last_item'] as JSON).toEntity(),
        hoveredItem: json['hovered_item'] != null
            ? StatisticModel.fromJson(json['hovered_item'] as JSON).toEntity()
            : null,
        year: json['year'] as int?,
      );

  final Statistic lastItem;
  final Statistic? hoveredItem;
  final int? year;

  @override
  List<Object?> get props => [lastItem, hoveredItem, year];

  JSON toJson() => {
        'last_item': StatisticModel.fromEntity(lastItem).toJson(),
        'hovered_item': hoveredItem != null
            ? StatisticModel.fromEntity(hoveredItem!).toJson()
            : null,
        'year': year,
      };
}

final class AllNationalStatisticFilterInitial
    extends AllNationalStatisticFilterState {
  AllNationalStatisticFilterInitial() : super(lastItem: Statistic());
}

final class AllNationalStatisticFilterUpdated
    extends AllNationalStatisticFilterState {
  const AllNationalStatisticFilterUpdated({
    required super.lastItem,
    super.hoveredItem,
    super.year,
  });
}
