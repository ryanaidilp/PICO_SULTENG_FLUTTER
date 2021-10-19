class NationalStatistic {
  NationalStatistic({
    required this.day,
    required this.updatedAt,
    required this.newPositive,
    required this.totalPositive,
    required this.newRecovered,
    required this.totalRecovered,
    required this.newDeceased,
    required this.totalDeceased,
    required this.newTreatment,
    required this.totalTreatment,
  });

  int day;
  DateTime updatedAt;
  int newPositive;
  int totalPositive;
  int newRecovered;
  int totalRecovered;
  int newDeceased;
  int totalDeceased;
  int newTreatment;
  int totalTreatment;

  factory NationalStatistic.fromJson(Map<String, dynamic> json) =>
      NationalStatistic(
        day: json['hari_ke'] as int,
        updatedAt: DateTime.parse(json['tanggal'].toString()).toLocal(),
        newPositive: json['kasus_baru']['positif'] as int,
        totalPositive: json['kumulatif']['positif'] as int,
        newRecovered: json['kasus_baru']['sembuh'] as int,
        totalRecovered: json['kumulatif']['sembuh'] as int,
        newDeceased: json['kasus_baru']['meninggal'] as int,
        totalDeceased: json['kumulatif']['meninggal'] as int,
        newTreatment: json['kasus_baru']['dalam_perawatan'] as int,
        totalTreatment: json['kumulatif']['dalam_perawatan'] as int,
      );
}
