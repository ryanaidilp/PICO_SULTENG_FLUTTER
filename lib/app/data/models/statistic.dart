class Statistic {
  Statistic({
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
    required this.newObservation,
    required this.totalObservation,
    required this.newFinishedObservation,
    required this.totalFinishedObservation,
    required this.totalActiveObservation,
    required this.newSupervision,
    required this.totalSupervision,
    required this.newFinishedSupervision,
    required this.totalFinishedSupervision,
    required this.totalActiveSupervision,
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
  int newObservation;
  int totalObservation;
  int newFinishedObservation;
  int totalFinishedObservation;
  int totalActiveObservation;
  int newSupervision;
  int totalSupervision;
  int newFinishedSupervision;
  int totalFinishedSupervision;
  int totalActiveSupervision;

  factory Statistic.fromJson(Map<String, dynamic> json) => Statistic(
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
        newObservation: json['kasus_baru']['ODP'] as int,
        totalObservation: json['kumulatif']['ODP'] as int,
        newFinishedObservation: json['kasus_baru']['selesai_ODP'] as int,
        totalFinishedObservation: json['kumulatif']['selesai_ODP'] as int,
        totalActiveObservation: json['kumulatif']['dalam_ODP'] as int,
        newSupervision: json['kasus_baru']['PDP'] as int,
        totalSupervision: json['kumulatif']['PDP'] as int,
        newFinishedSupervision: json['kasus_baru']['selesai_PDP'] as int,
        totalFinishedSupervision: json['kumulatif']['selesai_PDP'] as int,
        totalActiveSupervision: json['kumulatif']['dalam_PDP'] as int,
      );
}
