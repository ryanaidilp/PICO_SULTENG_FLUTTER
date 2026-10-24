import 'package:dependencies_core/equality.dart';
import 'package:pico_data_api/src/models/directory.dart';

/// A home banner.
final class Banner extends Equatable {
  /// Creates a banner.
  const new({required this.id, required this.title, this.link, this.imageUrl});

  /// API id.
  final int id;

  /// Title.
  final String title;

  /// Link to open.
  final Uri? link;

  /// Image URL, null when missing.
  final String? imageUrl;

  @override
  List<Object?> get props => [id, title, link, imageUrl];
}

/// An infographic.
final class Infographic extends Equatable {
  /// Creates an infographic.
  const new({
    required this.id,
    required this.title,
    required this.imageUrls,
    this.source,
  });

  /// API id.
  final int id;

  /// Title.
  final String title;

  /// Source link.
  final Uri? source;

  /// Image URLs.
  final List<String> imageUrls;

  @override
  List<Object?> get props => [id, title, source, imageUrls];
}

/// One page of infographics (20 per page).
final class InfographicPage extends Equatable {
  /// Creates a page.
  const new({required this.items, required this.page, required this.hasNext});

  /// Items.
  final List<Infographic> items;

  /// Page number from 1.
  final int page;

  /// Whether another page exists.
  final bool hasNext;

  @override
  List<Object?> get props => [items, page, hasNext];
}

/// A bank account for donations.
final class BankAccount extends Equatable {
  /// Creates an account.
  const new({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.logoUrl,
  });

  /// Bank name.
  final String bankName;

  /// Account number as sent by the API.
  final String accountNumber;

  /// Holder name.
  final String accountHolder;

  /// Bank logo URL.
  final String? logoUrl;

  @override
  List<Object?> get props => [bankName, accountNumber, accountHolder, logoUrl];
}

/// A donation campaign.
final class Donation extends Equatable {
  /// Creates a donation.
  const new({
    required this.id,
    required this.title,
    required this.initiator,
    required this.acceptsGoods,
    required this.accounts,
    required this.contacts,
    this.description,
    this.url,
    this.imageUrl,
    this.deliveryAddress,
  });

  /// API id.
  final int id;

  /// Title.
  final String title;

  /// Who runs it.
  final String initiator;

  /// Description.
  final String? description;

  /// Link.
  final Uri? url;

  /// Image URL.
  final String? imageUrl;

  /// Whether goods are accepted.
  final bool acceptsGoods;

  /// Where to send goods.
  final String? deliveryAddress;

  /// Bank accounts.
  final List<BankAccount> accounts;

  /// Contacts.
  final List<Contact> contacts;

  @override
  List<Object?> get props => [
    id,
    title,
    initiator,
    description,
    url,
    imageUrl,
    acceptsGoods,
    deliveryAddress,
    accounts,
    contacts,
  ];
}

/// Opening day and time of a telemedicine service.
final class Schedule extends Equatable {
  /// Creates a schedule.
  const new({required this.days, required this.time, required this.timezone});

  /// For example `Senin-Jumat`.
  final String days;

  /// For example `07:00-20:00`.
  final String time;

  /// For example `WIB`.
  final String timezone;

  @override
  List<Object?> get props => [days, time, timezone];
}

/// A telemedicine doctor or service.
final class Telemedicine extends Equatable {
  /// Creates a service.
  const new({
    required this.id,
    required this.name,
    required this.isFree,
    required this.schedules,
    required this.contacts,
  });

  /// API id.
  final int id;

  /// Name.
  final String name;

  /// Free of charge.
  final bool isFree;

  /// Schedules.
  final List<Schedule> schedules;

  /// Contacts.
  final List<Contact> contacts;

  @override
  List<Object?> get props => [id, name, isFree, schedules, contacts];
}

/// A partner shown in the footer or About.
final class Partner extends Equatable {
  /// Creates a partner.
  const new({
    required this.name,
    required this.inFooter,
    this.link,
    this.imageUrl,
  });

  /// Name.
  final String name;

  /// Link.
  final Uri? link;

  /// Logo URL.
  final String? imageUrl;

  /// Shown in the footer.
  final bool inFooter;

  @override
  List<Object?> get props => [name, link, imageUrl, inFooter];
}
