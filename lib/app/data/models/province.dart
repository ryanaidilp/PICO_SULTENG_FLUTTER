class Province {
  Province({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.positive,
    required this.recovered,
    required this.deceased,
    required this.underTreatment,
    required this.deathRatio,
    required this.mapId,
  });

  String id;
  DateTime updatedAt;
  String name;
  int positive;
  int recovered;
  int deceased;
  int underTreatment;
  double deathRatio;
  String mapId;

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: json['kode_provinsi'].toString(),
        updatedAt: DateTime.parse(json['updated_at'].toString()).toLocal(),
        name: json['provinsi'] as String,
        positive: json['positif'] as int,
        recovered: json['sembuh'] as int,
        deceased: json['meninggal'] as int,
        underTreatment: json['dalam_perawatan'] as int,
        deathRatio: json['rasio_kematian'] as double,
        mapId: json['map_id'] as String,
      );
}
