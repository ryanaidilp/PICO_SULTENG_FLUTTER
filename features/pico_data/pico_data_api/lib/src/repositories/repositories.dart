import 'package:pico_data_api/src/models/area.dart';
import 'package:pico_data_api/src/models/cases.dart';
import 'package:pico_data_api/src/models/content.dart';
import 'package:pico_data_api/src/models/directory.dart';
import 'package:pico_data_api/src/models/stats.dart';
import 'package:pico_data_api/src/repositories/snapshot.dart';

/// Case numbers (C02). TTL per resource class: see the C05 policy table.
abstract interface class CaseRepository {
  /// Latest national day.
  Watch<CaseDay> watchNationalLatest({bool forceRefresh = false});

  /// The newest national Rt reading, or null data when no day has one.
  ///
  /// Small and local: it comes from the saved copy or the bundled seed and
  /// never starts a network request, so Beranda can show it without loading
  /// the full series (C05 offline-first policy).
  Watch<LatestRt?> watchNationalLatestRt({bool forceRefresh = false});

  /// Full series of an area, ascending by date.
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false});

  /// Latest day of each of the 34 provinces.
  Watch<List<AreaSummary>> watchProvinceSummaries({bool forceRefresh = false});

  /// Latest day of each of the 13 kabupaten.
  Watch<List<AreaSummary>> watchRegencySummaries({bool forceRefresh = false});
}

/// Tests, gender and vaccination (C03). TTL: policy table (C05).
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

/// Directories (C03). TTL: policy table (C05).
abstract interface class DirectoryRepository {
  /// The 13 kabupaten and kota: code and name. Light, unlike the case series.
  Watch<List<Regency>> watchRegencies({bool forceRefresh = false});

  /// Hospitals.
  Watch<List<Hospital>> watchHospitals({bool forceRefresh = false});

  /// Task forces grouped by kabupaten.
  Watch<List<TaskForceGroup>> watchTaskForces({bool forceRefresh = false});

  /// Vaccination sites.
  Watch<List<VaccineLocation>> watchVaccineLocations({
    bool forceRefresh = false,
  });
}

/// Content (C04). TTL: policy table (C05).
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
