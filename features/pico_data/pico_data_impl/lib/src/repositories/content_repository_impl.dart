import 'package:dependencies/di.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/ttl.dart';

/// [ContentRepository] over the snapshot source (C05). TTL 6 h.
@LazySingleton(as: ContentRepository)
class ContentRepositoryImpl implements ContentRepository {
  /// Creates the repository.
  ContentRepositoryImpl(this._source);

  final SnapshotSource _source;

  @override
  Watch<List<Banner>> watchBanners({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.banners,
        ttl: PicoTtl.content,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<InfographicPage> watchInfographics({
    required int page,
    bool forceRefresh = false,
  }) => _source.watch(
    PicoEndpoints.infographics(page),
    ttl: PicoTtl.content,
    forceRefresh: forceRefresh,
  );

  @override
  Watch<List<Donation>> watchDonations({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.donations,
        ttl: PicoTtl.content,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<Telemedicine>> watchTelemedicines({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.telemedicines,
        ttl: PicoTtl.content,
        forceRefresh: forceRefresh,
      );

  @override
  Watch<List<Partner>> watchPartners({bool forceRefresh = false}) =>
      _source.watch(
        PicoEndpoints.partners,
        ttl: PicoTtl.content,
        forceRefresh: forceRefresh,
      );
}
