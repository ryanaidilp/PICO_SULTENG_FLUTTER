// To parse this JSON data, do
//
//     final local = localFromJson(jsonString);

import 'dart:convert';

Local localFromJson(String str) => Local.fromJson(json.decode(str));

class Local {
  const Local(
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
      this.weeklyRecovered,
      this.weeklyDeceased});

  final int day;
  final String date;
  final int cumulativePositive;
  final int cumulativeUnderTreatment;
  final int cumulativeRecovered;
  final int cumulativeDeceased;
  final int newPositive;
  final int newUnderTreatment;
  final int newRecovered;
  final int newDeceased;
  final double weeklyPositive;
  final double weeklyRecovered;
  final double weeklyDeceased;

  factory Local.fromJson(Map<String, dynamic> json) {
    int cumulativeUnderTreatment = json['kumulatif']['positif'] -
        (json['kumulatif']['sembuh'] + json['kumulatif']['meninggal']);
    int newUnderTreatment = json['kasus_baru']['positif'] -
        (json['kasus_baru']['sembuh'] + json['kasus_baru']['meninggal']);
    return Local(
      day: json['hari_ke'],
      date: json['tanggal'],
      cumulativePositive: json['kumulatif']['positif'],
      cumulativeUnderTreatment: cumulativeUnderTreatment,
      cumulativeRecovered: json['kumulatif']['sembuh'],
      cumulativeDeceased: json['kumulatif']['meninggal'],
      newPositive: json['kasus_baru']['positif'],
      newUnderTreatment: newUnderTreatment,
      newRecovered: json['kasus_baru']['sembuh'],
      newDeceased: json['kasus_baru']['meninggal'],
      weeklyPositive: double.parse(
          json['rekap']['rata_rata']['mingguan']['positif'].toString()),
      weeklyRecovered: double.parse(
          json['rekap']['rata_rata']['mingguan']['sembuh'].toString()),
      weeklyDeceased: double.parse(
          json['rekap']['rata_rata']['mingguan']['meninggal'].toString()),
    );
  }
}
