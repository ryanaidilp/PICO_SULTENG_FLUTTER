class ApiEndpoint {
  const ApiEndpoint._();

  static String banner() => '/banner';

  static String history() => '/nasional';
  static String latest() => '${history()}/terkini';

  static String historyProvince() => '/statistik';
  static String latestProvince() => '${historyProvince()}/terkini';

  static String infographics({
    int page = 1,
  }) =>
      '/infografis?page=$page';

  static String regenciesStatisticsByProvince({
    required String provinceCode,
  }) =>
      '/provinsi/$provinceCode/terkini';

  static String testLatest() => '/test/terkini';

  static String vaccineLatest({
    String? provinceCode,
  }) =>
      provinceCode == null
          ? '/vaksin/terkini'
          : '/vaksin/$provinceCode/terkini';
}
