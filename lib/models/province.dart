import 'dart:convert';

Province provinceFromJson(String str) => Province.fromJson(json.decode(str));

String provinceToJson(Province data) => json.encode(data.toJson());

class Province {
  Province({
    this.provinceCode,
    this.updatedAt,
    this.name,
    this.positive,
    this.underTreatment,
    this.deceased,
    this.recovered,
    this.deathRatio,
    this.mapId,
  });

  int provinceCode;
  DateTime updatedAt;
  String name;
  int positive;
  int underTreatment;
  int deceased;
  int recovered;
  double deathRatio;
  String mapId;

  factory Province.fromJson(Map<String, dynamic> json) => Province(
    provinceCode: json["kode_provinsi"],
    updatedAt: DateTime.parse(json["updated_at"]),
    name: json["provinsi"],
    positive: json["positif"],
    underTreatment: json["dalam_perawatan"],
    deceased: json["meninggal"],
    recovered: json["sembuh"],
    deathRatio: json["rasio_kematian"].toDouble(),
    mapId: json["map_id"],
  );

  Map<String, dynamic> toJson() => {
    "kode_provinsi": provinceCode,
    "updated_at": updatedAt.toIso8601String(),
    "provinsi": name,
    "positif": positive,
    "dalam_perawatan": underTreatment,
    "meninggal": deceased,
    "sembuh": recovered,
    "rasio_kematian": deathRatio,
    "map_id": mapId,
  };
}
