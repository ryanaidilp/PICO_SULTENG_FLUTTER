class RegencyStatistic {
  RegencyStatistic({
    required this.day,
    required this.name,
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
  String name;
  DateTime updatedAt;
  int newPositive;
  int totalPositive;
  int newRecovered;
  int totalRecovered;
  int newDeceased;
  int totalDeceased;
  int newTreatment;
  int totalTreatment;

  factory RegencyStatistic.fromJson(Map<String, dynamic> json) =>
      RegencyStatistic(
        day: json['hari_ke'] as int,
        name: json['kabupaten'] as String,
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
