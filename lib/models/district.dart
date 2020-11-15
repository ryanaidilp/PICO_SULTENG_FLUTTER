// To parse this JSON data, do
//
//     final district = districtFromJson(jsonString);

import 'dart:convert';

District districtFromJson(String str) => District.fromJson(json.decode(str));

String districtToJson(District data) => json.encode(data.toJson());

class District {
  District({
    this.districtCode,
    this.name,
    this.updatedAt,
    this.positive,
    this.negative,
    this.recovered,
    this.deceased,
    this.odp,
    this.finishedObservation,
    this.underObservation,
    this.pdp,
    this.finishedSupervision,
    this.underSupervision,
    this.deathRatio,
  });

  int districtCode;
  String name;
  DateTime updatedAt;
  int positive;
  int negative;
  int recovered;
  int deceased;
  int odp;
  int finishedObservation;
  int underObservation;
  int pdp;
  int finishedSupervision;
  int underSupervision;
  double deathRatio;

  factory District.fromJson(Map<String, dynamic> json) => District(
    districtCode: json["no"],
    name: json["kabupaten"],
    updatedAt: DateTime.parse(json["terakhir_diperbarui"]),
    positive: json["positif"],
    negative: json["negatif"],
    recovered: json["sembuh"],
    deceased: json["meninggal"],
    odp: json["ODP"],
    finishedObservation: json["selesai_pemantauan"],
    underObservation: json["dalam_pemantauan"],
    pdp: json["PDP"],
    finishedSupervision: json["selesai_pengawasan"],
    underSupervision: json["dalam_pengawasan"],
    deathRatio: json["rasio_kematian"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "no": districtCode,
    "kabupaten": name,
    "terakhir_diperbarui": updatedAt.toIso8601String(),
    "positif": positive,
    "negatif": negative,
    "sembuh": recovered,
    "meninggal": deceased,
    "ODP": odp,
    "selesai_pemantauan": finishedObservation,
    "dalam_pemantauan": underObservation,
    "PDP": pdp,
    "selesai_pengawasan": finishedSupervision,
    "dalam_pengawasan": underSupervision,
    "rasio_kematian": deathRatio,
  };
}
