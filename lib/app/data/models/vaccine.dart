import 'dart:convert';

class Vaccine {
  Vaccine({
    required this.day,
    required this.updatedAt,
    required this.totalTarget,
    required this.totalFirstNew,
    required this.totalFirstCumulative,
    required this.totalSecondNew,
    required this.totalSecondCumulative,
    required this.healthWorkerTarget,
    required this.healthWorkerFirstNew,
    required this.healthWorkerFirstCumulative,
    required this.healthWorkerSecondNew,
    required this.healthWorkerSecondCumulative,
    required this.publicWorkerTarget,
    required this.publicWorkerFirstNew,
    required this.publicWorkerFirstCumulative,
    required this.publicWorkerSecondNew,
    required this.publicWorkerSecondCumulative,
    required this.elderlyTarget,
    required this.elderlyFirstNew,
    required this.elderlyFirstCumulative,
    required this.elderlySecondNew,
    required this.elderlySecondCumulative,
    required this.publicTarget,
    required this.publicFirstNew,
    required this.publicFirstCumulative,
    required this.publicSecondNew,
    required this.publicSecondCumulative,
    required this.teenagerTarget,
    required this.teenagerFirstNew,
    required this.teenagerFirstCumulative,
    required this.teenagerSecondNew,
    required this.teenagerSecondCumulative,
  });

  int day;
  DateTime updatedAt;
  int totalTarget;
  int totalFirstNew;
  int totalFirstCumulative;
  int totalSecondNew;
  int totalSecondCumulative;
  int healthWorkerTarget;
  int healthWorkerFirstNew;
  int healthWorkerFirstCumulative;
  int healthWorkerSecondNew;
  int healthWorkerSecondCumulative;
  int elderlyTarget;
  int elderlyFirstNew;
  int elderlyFirstCumulative;
  int elderlySecondNew;
  int elderlySecondCumulative;
  int publicWorkerTarget;
  int publicWorkerFirstNew;
  int publicWorkerFirstCumulative;
  int publicWorkerSecondNew;
  int publicWorkerSecondCumulative;
  int publicTarget;
  int publicFirstNew;
  int publicFirstCumulative;
  int publicSecondNew;
  int publicSecondCumulative;
  int teenagerTarget;
  int teenagerFirstNew;
  int teenagerFirstCumulative;
  int teenagerSecondNew;
  int teenagerSecondCumulative;

  factory Vaccine.fromRawJson(String str) =>
      Vaccine.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => jsonEncode(toJson());

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
        day: json['hari_ke'] as int,
        updatedAt: DateTime.parse(json['tanggal'].toString()).toLocal(),
        totalTarget: json['target_vaksin'] as int,
        totalFirstNew: json['semua']['vaksin_pertama']['baru'] as int,
        totalFirstCumulative:
            json['semua']['vaksin_pertama']['kumulatif'] as int,
        totalSecondNew: json['semua']['vaksin_kedua']['baru'] as int,
        totalSecondCumulative:
            json['semua']['vaksin_kedua']['kumulatif'] as int,
        healthWorkerTarget: json['target_nakes'] as int,
        healthWorkerFirstNew: json['nakes']['vaksin_pertama']['baru'] as int,
        healthWorkerFirstCumulative:
            json['nakes']['vaksin_pertama']['kumulatif'] as int,
        healthWorkerSecondNew: json['nakes']['vaksin_kedua']['baru'] as int,
        healthWorkerSecondCumulative:
            json['nakes']['vaksin_kedua']['kumulatif'] as int,
        publicWorkerTarget: json['target_petugas_publik'] as int,
        publicWorkerFirstNew:
            json['petugas_publik']['vaksin_pertama']['baru'] as int,
        publicWorkerFirstCumulative:
            json['petugas_publik']['vaksin_pertama']['kumulatif'] as int,
        publicWorkerSecondNew:
            json['petugas_publik']['vaksin_kedua']['baru'] as int,
        publicWorkerSecondCumulative:
            json['petugas_publik']['vaksin_kedua']['kumulatif'] as int,
        elderlyTarget: json['target_lansia'] as int,
        elderlyFirstNew: json['lansia']['vaksin_pertama']['baru'] as int,
        elderlyFirstCumulative:
            json['lansia']['vaksin_pertama']['kumulatif'] as int,
        elderlySecondNew: json['lansia']['vaksin_kedua']['baru'] as int,
        elderlySecondCumulative:
            json['lansia']['vaksin_kedua']['kumulatif'] as int,
        publicTarget: json['target_publik'] as int,
        publicFirstNew: json['publik']['vaksin_pertama']['baru'] as int,
        publicFirstCumulative:
            json['publik']['vaksin_pertama']['kumulatif'] as int,
        publicSecondNew: json['publik']['vaksin_kedua']['baru'] as int,
        publicSecondCumulative:
            json['publik']['vaksin_kedua']['kumulatif'] as int,
        teenagerTarget: json['target_remaja'] as int,
        teenagerFirstNew: json['remaja']['vaksin_pertama']['baru'] as int,
        teenagerFirstCumulative:
            json['remaja']['vaksin_pertama']['kumulatif'] as int,
        teenagerSecondNew: json['remaja']['vaksin_kedua']['baru'] as int,
        teenagerSecondCumulative:
            json['remaja']['vaksin_kedua']['kumulatif'] as int,
      );

  Map<String, dynamic> toJson() => {};
}
