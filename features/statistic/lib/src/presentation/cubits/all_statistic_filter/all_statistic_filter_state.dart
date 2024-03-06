part of 'all_statistic_filter_cubit.dart';

@immutable
class AllStatisticFilterState extends Equatable {
  const AllStatisticFilterState({
    required this.lastItem,
    this.hoveredItem,
    this.year,
  });

  factory AllStatisticFilterState.fromJson(JSON json) =>
      AllStatisticFilterState(
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

final class AllStatisticFilterInitial extends AllStatisticFilterState {
  AllStatisticFilterInitial() : super(lastItem: Statistic());
}

final class AllStatisticFilterUpdated extends AllStatisticFilterState {
  const AllStatisticFilterUpdated({
    required super.lastItem,
    super.hoveredItem,
    super.year,
  });
}
