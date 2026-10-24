import 'package:freezed_annotation/freezed_annotation.dart';

part 'informasi_state.freezed.dart';

/// State for the Informasi feature bloc.
@freezed
sealed class InformasiState with _$InformasiState {
  const factory initial() = InformasiInitial;
  const factory loading() = InformasiLoading;
  const factory loaded() = InformasiLoaded;
  const factory error(String message) = InformasiError;
}
