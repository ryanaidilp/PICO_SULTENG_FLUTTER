import 'package:dependencies_core/equality.dart';

/// A WGS84 point in decimal degrees.
final class LatLng extends Equatable {
  /// Creates a point.
  const new(this.latitude, this.longitude);

  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Kind of contact. Chooses the icon and the action (C04 table).
enum ContactKind {
  /// Email, `mailto:`.
  email,

  /// Phone, `tel:`.
  phone,

  /// Fax, shown as text.
  fax,

  /// Website.
  web,

  /// WhatsApp.
  whatsapp,

  /// Telegram.
  telegram,

  /// Twitter.
  twitter,

  /// Instagram.
  instagram,

  /// Line.
  line,
}

/// A way to reach someone.
final class Contact extends Equatable {
  /// Creates a contact.
  const new({
    required this.kind,
    required this.label,
    required this.value,
    this.uri,
  });

  /// Kind.
  final ContactKind kind;

  /// Label from the API (for example "Telepon").
  final String label;

  /// The raw value.
  final String value;

  /// Link to open, null for fax and for values that do not parse.
  final Uri? uri;

  @override
  List<Object?> get props => [kind, label, value, uri];
}

/// Bed type with free and total numbers. Never derive a percentage above 100.
final class Bed extends Equatable {
  /// Creates a bed row.
  const new({
    required this.typeName,
    required this.available,
    required this.total,
  });

  /// Bed type name.
  final String typeName;

  /// Free beds.
  final int available;

  /// All beds.
  final int total;

  @override
  List<Object?> get props => [typeName, available, total];
}

/// A referral hospital.
final class Hospital extends Equatable {
  /// Creates a hospital.
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.regencyCode,
    required this.contacts,
    required this.beds,
    required this.igdCount,
    this.location,
  });

  /// API id.
  final int id;

  /// Hospital code, for example `7271025`.
  final String code;

  /// Name.
  final String name;

  /// Address.
  final String address;

  /// Regency code.
  final String regencyCode;

  /// Coordinates, null when missing (0 or null in the API).
  final LatLng? location;

  /// Contacts.
  final List<Contact> contacts;

  /// Beds.
  final List<Bed> beds;

  /// Emergency room count.
  final int igdCount;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    address,
    regencyCode,
    location,
    contacts,
    beds,
    igdCount,
  ];
}

/// One task force member.
final class TaskForce extends Equatable {
  /// Creates a member.
  const new({required this.name, required this.contacts});

  /// Name and role.
  final String name;

  /// Contacts.
  final List<Contact> contacts;

  @override
  List<Object?> get props => [name, contacts];
}

/// Task force members of one kabupaten.
final class TaskForceGroup extends Equatable {
  /// Creates a group.
  const new({
    required this.regencyCode,
    required this.regencyName,
    required this.members,
  });

  /// Regency code.
  final String regencyCode;

  /// Regency name.
  final String regencyName;

  /// Members.
  final List<TaskForce> members;

  @override
  List<Object?> get props => [regencyCode, regencyName, members];
}

/// A vaccination site.
final class VaccineLocation extends Equatable {
  /// Creates a location.
  const new({
    required this.name,
    required this.address,
    required this.regencyCode,
    required this.firstDose,
    required this.secondDose,
    this.hours,
    this.dailyQuota,
    this.stockRemaining,
    this.notes,
  });

  /// Name.
  final String name;

  /// Address.
  final String address;

  /// Regency code.
  final String regencyCode;

  /// Opening hours, null when `"NULL"` or empty.
  final String? hours;

  /// Offers dose 1.
  final bool firstDose;

  /// Offers dose 2.
  final bool secondDose;

  /// Daily quota.
  final int? dailyQuota;

  /// Remaining stock.
  final int? stockRemaining;

  /// Notes.
  final String? notes;

  @override
  List<Object?> get props => [
    name,
    address,
    regencyCode,
    hours,
    firstDose,
    secondDose,
    dailyQuota,
    stockRemaining,
    notes,
  ];
}

/// A kabupaten or kota of Sulawesi Tengah (code and name as the API spells
/// them). Directory rows carry only the code, so lists group by this name.
final class Regency extends Equatable {
  /// Creates a regency.
  const Regency({required this.code, required this.name});

  /// Code, for example `7271`.
  final String code;

  /// Name, for example `Kota Palu`.
  final String name;

  @override
  List<Object?> get props => [code, name];
}
