// To parse this JSON data, do
//
//     final provinceTest = provinceTestFromJson(jsonString);

import 'dart:convert';

class ProvinceTest {
  ProvinceTest({
    required this.day,
    required this.date,
    required this.name,
    required this.sample,
    required this.duration,
    required this.positive,
    required this.negative,
    required this.process,
    required this.invalid,
    required this.total,
  });

  final int day;
  final DateTime date;
  final String name;
  final String sample;
  final String duration;
  final int positive;
  final int negative;
  final int process;
  final int invalid;
  final int total;

  factory ProvinceTest.fromRawJson(String str) =>
      ProvinceTest.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory ProvinceTest.fromJson(Map<String, dynamic> json) => ProvinceTest(
        day: json['hari_ke'] as int,
        date: DateTime.parse(json['tanggal'].toString()).toLocal(),
        name: json['nama'].toString(),
        sample: json['sampel'].toString(),
        duration: json['durasi'].toString(),
        positive: json['positif'] as int,
        negative: json['negatif'] as int,
        process: json['proses'] as int,
        invalid: json['invalid'] as int,
        total: json['total'] as int,
      );

  Map<String, dynamic> toJson() => {
        'hari_ke': day,
        'tanggal':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'nama': name,
        'sampel': sample,
        'durasi': duration,
        'positif': positive,
        'negatif': negative,
        'proses': process,
        'invalid': invalid,
        'total': total,
      };
}
