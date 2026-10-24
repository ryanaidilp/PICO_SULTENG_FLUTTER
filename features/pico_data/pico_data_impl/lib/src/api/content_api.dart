import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/contact_mapper.dart';
import 'package:pico_data_impl/src/api/dates.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';

/// Image fields are kept as stored. Hosts are dead, relative or blocked
/// (ADR-0113), so the client never builds a URL from a relative path.
String? _image(Object? v) => cleanString(v);

Uri? _uri(Object? v) {
  final s = cleanString(v);
  return s == null ? null : Uri.tryParse(s);
}

List<Map<String, dynamic>> _maps(Object? v) =>
    (v as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

/// Banners (C04).
List<Banner> bannersFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    Banner(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String,
      link: _uri(j['link']),
      imageUrl: _image(j['image']),
    ),
];

/// One infographics page. Images are ordered by `queue`.
InfographicPage infographicsFrom(Map<String, dynamic> data, int page) {
  final pagination = data['pagination'] as Map<String, dynamic>?;
  return InfographicPage(
    page: page,
    hasNext: pagination?['has_next'] == true,
    items: [
      for (final j in _maps(data['data']))
        Infographic(
          id: (j['id'] as num).toInt(),
          title: j['title'] as String,
          source: _uri(j['source']),
          imageUrls: [
            for (final i
                in _maps(j['images'])..sort(
                  (a, b) => ((a['queue'] as num?) ?? 0).compareTo(
                    (b['queue'] as num?) ?? 0,
                  ),
                ))
              ?_image(i['image_url']),
          ],
        ),
    ],
  );
}

/// Donations (C04).
List<Donation> donationsFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    Donation(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String,
      initiator: cleanString(j['initiator']) ?? '',
      description: cleanString(j['description']),
      url: _uri(j['url']),
      imageUrl: _image(j['image']),
      acceptsGoods: j['accept_noncash'] == true,
      deliveryAddress: cleanString(j['delivery_address']),
      accounts: [
        for (final a in _maps(j['bank_accounts']))
          BankAccount(
            bankName:
                ((a['bank'] as Map<String, dynamic>?)?['nickname'] ??
                        (a['bank'] as Map<String, dynamic>?)?['name'] ??
                        '')
                    as String,
            accountNumber: '${a['account_number']}',
            accountHolder: cleanString(a['account_name']) ?? '',
            logoUrl: _image((a['bank'] as Map<String, dynamic>?)?['logo']),
          ),
      ],
      contacts: contactList(j['contacts']),
    ),
];

/// Telemedicine services (C04).
List<Telemedicine> telemedicinesFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    Telemedicine(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String,
      isFree: j['is_free'] == true,
      schedules: [
        for (final s in _maps(j['schedules']))
          Schedule(
            days: cleanString(s['operational_day']) ?? '',
            time: cleanString(s['operational_time']) ?? '',
            timezone: cleanString(s['timezone']) ?? '',
          ),
      ],
      contacts: contactList(j['contacts']),
    ),
];

/// Partners (C04).
List<Partner> partnersFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    Partner(
      name: j['name'] as String,
      link: _uri(j['link']),
      imageUrl: _image(j['image']),
      inFooter: j['in_footer'] == true,
    ),
];

/// Content endpoints of C04.
class ContentApi {
  /// Creates the API over [client].
  ContentApi(this._client);

  final PicoApiClient _client;

  /// `GET /banners?load_all=true`.
  Future<Either<PicoFailure, List<Banner>>> banners() =>
      _client.fetch(PicoEndpoints.banners);

  /// `GET /infographics?page=N&per_page=20`, the only paged call.
  Future<Either<PicoFailure, InfographicPage>> infographics(int page) =>
      _client.fetch(PicoEndpoints.infographics(page));

  /// `GET /donations?load_all=true`.
  Future<Either<PicoFailure, List<Donation>>> donations() =>
      _client.fetch(PicoEndpoints.donations);

  /// `GET /telemedicines?load_all=true`.
  Future<Either<PicoFailure, List<Telemedicine>>> telemedicines() =>
      _client.fetch(PicoEndpoints.telemedicines);

  /// `GET /partners?load_all=true`.
  Future<Either<PicoFailure, List<Partner>>> partners() =>
      _client.fetch(PicoEndpoints.partners);
}
