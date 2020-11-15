import 'dart:convert';

National nationalFromJson(String str) => National.fromJson(jsonDecode(str));

class National {
  const National(
      {this.day,
      this.date,
      this.cumulativePositive,
      this.cumulativeUnderTreatment,
      this.cumulativeRecovered,
      this.cumulativeDeceased,
      this.newPositive,
      this.newUnderTreatment,
      this.newRecovered,
      this.newDeceased,
      this.weeklyPositive,
      this.weeklyUnderTreatment,
      this.weeklyRecovered,
      this.weeklyDeceased});

  final int day;
  final DateTime date;
  final int cumulativePositive;
  final int cumulativeUnderTreatment;
  final int cumulativeRecovered;
  final int cumulativeDeceased;
  final int newPositive;
  final int newUnderTreatment;
  final int newRecovered;
  final int newDeceased;
  final double weeklyPositive;
  final double weeklyUnderTreatment;
  final double weeklyRecovered;
  final double weeklyDeceased;

  factory National.fromJson(Map<String, dynamic> json) => National(
    day: json['hari_ke'],
    date: DateTime.parse(json['tanggal']),
    cumulativePositive: json['kumulatif']['positif'],
    cumulativeUnderTreatment: json['kumulatif']['dalam_perawatan'],
    cumulativeRecovered: json['kumulatif']['sembuh'],
    cumulativeDeceased: json['kumulatif']['meninggal'],
    newPositive: json['kasus_baru']['positif'],
    newUnderTreatment: json['kasus_baru']['dalam_perawatan'],
    newRecovered: json['kasus_baru']['sembuh'],
    newDeceased: json['kasus_baru']['meninggal'],
    weeklyPositive: double.parse(json['rekap']['rata_rata']['mingguan']['positif'].toString()),
    weeklyUnderTreatment: double.parse(json['rekap']['rata_rata']['mingguan']['dalam_perawatan'].toString()),
    weeklyRecovered: double.parse(json['rekap']['rata_rata']['mingguan']['sembuh'].toString()),
    weeklyDeceased: double.parse(json['rekap']['rata_rata']['mingguan']['meninggal'].toString()),
  );
}
