import 'package:pico_data_api/src/models/area.dart';
import 'package:pico_data_api/src/models/cases.dart';
import 'package:pico_data_api/src/models/content.dart';
import 'package:pico_data_api/src/models/directory.dart';
import 'package:pico_data_api/src/models/stats.dart';
import 'package:pico_data_api/src/repositories/snapshot.dart';

/// Case numbers (C02). TTL 24 h.
abstract interface class CaseRepository {
  /// Latest national day.
  Watch<CaseDay> watchNationalLatest({bool forceRefresh = false});

  /// Full series of an area, ascending by date.
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false});

  /// Latest day of each of the 34 provinces.
  Watch<List<AreaSummary>> watchProvinceSummaries({bool forceRefresh = false});

  /// Latest day of each of the 13 kabupaten.
  Watch<List<AreaSummary>> watchRegencySummaries({bool forceRefresh = false});
}

/// Tests, gender and vaccination (C03). TTL 24 h.
abstract interface class StatsRepository {
  /// Test methods.
  Watch<List<TestType>> watchTestTypes({bool forceRefresh = false});

  /// Latest totals per type, Sulteng.
  Watch<List<TestTotal>> watchLatestTests({bool forceRefresh = false});

  /// Latest gender split, Sulteng.
  Watch<GenderSnapshot> watchLatestGender({bool forceRefresh = false});

  /// Vaccination series.
  Watch<VaccinationSeries> watchVaccination(
    VaccinationScope scope, {
    bool forceRefresh = false,
  });
}

/// Directories (C03). TTL 6 h.
abstract interface class DirectoryRepository {
  /// Hospitals.
  Watch<List<Hospital>> watchHospitals({bool forceRefresh = false});

  /// Task forces grouped by kabupaten.
  Watch<List<TaskForceGroup>> watchTaskForces({bool forceRefresh = false});

  /// Vaccination sites.
  Watch<List<VaccineLocation>> watchVaccineLocations({
    bool forceRefresh = false,
  });
}

/// Content (C04). TTL 6 h.
abstract interface class ContentRepository {
  /// Banners.
  Watch<List<Banner>> watchBanners({bool forceRefresh = false});

  /// One page of infographics, 20 per page.
  Watch<InfographicPage> watchInfographics({
    required int page,
    bool forceRefresh = false,
  });

  /// Donations.
  Watch<List<Donation>> watchDonations({bool forceRefresh = false});

  /// Telemedicine services.
  Watch<List<Telemedicine>> watchTelemedicines({bool forceRefresh = false});

  /// Partners.
  Watch<List<Partner>> watchPartners({bool forceRefresh = false});
}

/// Local data admin for Pengaturan (C05).
abstract interface class LocalDataAdmin {
  /// Bytes in the snapshot store plus the image cache.
  Future<int> cachedBytes();

  /// Deletes every saved copy.
  Future<void> clearAll();
}
