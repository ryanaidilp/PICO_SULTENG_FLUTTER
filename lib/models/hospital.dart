// To parse this JSON data, do
//
//     final hospital = hospitalFromJson(jsonString);

import 'dart:convert';

Hospital hospitalFromJson(String str) => Hospital.fromJson(json.decode(str));

String hospitalToJson(Hospital data) => json.encode(data.toJson());

class Hospital {
  Hospital({
    this.no,
    this.name,
    this.address,
    this.telephone,
    this.email,
    this.longitude,
    this.latitude,
  });

  int no;
  String name;
  String address;
  String telephone;
  String email;
  double longitude;
  double latitude;

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
    no: json["no"],
    name: json["nama"],
    address: json["alamat"],
    telephone: json["telepon"],
    email: json["email"],
    longitude: json["longitude"].toDouble(),
    latitude: json["latitude"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "no": no,
    "nama": name,
    "alamat": address,
    "telepon": telephone,
    "email": email,
    "longitude": longitude,
    "latitude": latitude,
  };
}
