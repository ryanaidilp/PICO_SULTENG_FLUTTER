import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/domain.dart';

part 'banner_event.dart';
part 'banner_state.dart';
part 'banner_bloc.freezed.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  BannerBloc() : super(BannerState.initial()) {
    on<BannerEvent>(
      (event, emit) async {
        if (event is _LoadBannerEvent) {
          emit(BannerState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (failure) => emit(
              BannerState.failed(failure: failure),
            ),
            (data) => emit(
              BannerState.loaded(
                data: data,
              ),
            ),
          );
        }
      },
    );
  }
  final _usecase = getIt<GetAllBanner>();
}
