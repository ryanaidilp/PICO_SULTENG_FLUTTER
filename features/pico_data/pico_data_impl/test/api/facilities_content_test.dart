import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

import 'fake_adapter.dart';

PicoApiClient client(String fixtureName) => PicoApiClient.create(
  baseUrl: 'https://pico.test/api/v1',
  userAgent: 'test',
  adapter: FakeAdapter([fixtureReply(fixtureName)]),
  retryDelay: Duration.zero,
);

void main() {
  group('facilities', () {
    test('hospital 7271025: contacts as tel URIs, beds, coordinates', () async {
      final h = (await FacilitiesApi(
        client('hospitals_per_page_1.json'),
      ).hospitals()).right.single;
      expect(h.code, '7271025');
      expect(h.regencyCode, '7271');
      expect(h.location, const LatLng(-0.8959781, 119.8874783));
      expect(h.contacts.first.kind, ContactKind.phone);
      expect(h.contacts.first.uri, Uri.parse('tel:081213756763'));
      expect(h.beds.first.typeName, 'IGD Khusus Covid');
      expect(h.beds.first.available, 2);
      expect(h.igdCount, 2);
    });

    test('missing coordinates become null, not 0,0', () {
      final h = hospitalsFrom([
        {
          'id': 1,
          'regency_id': 7271,
          'name': 'X',
          'hospital_code': '1',
          'latitude': 0,
          'longitude': 0,
        },
      ]).single;
      expect(h.location, isNull);
    });

    test('task forces: Banggai has 2 members with phone contacts', () async {
      final g = (await FacilitiesApi(
        client('task-forces_per_page_1.json'),
      ).taskForces()).right.single;
      expect(g.regencyName, 'Banggai');
      expect(g.members.length, 2);
      expect(g.members.first.contacts.single.value, '081241415651');
    });

    test('vaccine location: hours kept, null quota stays null', () async {
      final l = (await FacilitiesApi(
        client('vaccination_locations_per_page_1.json'),
      ).vaccineLocations()).right.single;
      expect(l.hours, '08:00 - 12:00');
      expect(l.dailyQuota, isNull);
      expect(l.firstDose, isFalse);
    });
  });

  group('stats', () {
    test('test types: 5 with keys', () async {
      final t = (await StatsApi(
        client('stats_test-types.json'),
      ).testTypes()).right;
      expect(t.map((e) => e.key), ['pcr', 'rdt', 'tcm', 'rdt_ab', 'rdt_ag']);
      expect(t.first.isRecommended, isTrue);
    });

    test('latest tests: highest day per type, no date', () async {
      final t = (await StatsApi(
        client('stats_tests_sample.json'),
      ).latestTests()).right;
      expect(t.map((e) => e.typeKey), ['pcr', 'rdt']);
      expect(t.first.positive, 193);
      expect(t.first.negative, 1406);
      expect(t.first.sourceDay, 520);
    });

    test('latestTestsFrom keeps the highest day, whatever the order', () {
      Map<String, dynamic> row(int day, int pos) => {
        'day': day,
        'process': 0,
        'invalid': 0,
        'positive': pos,
        'negative': 0,
        'test_type': {'key': 'pcr'},
      };
      expect(
        latestTestsFrom([row(9, 90), row(3, 30), row(7, 70)]).single.positive,
        90,
      );
    });

    test(
      'gender latest: day 799, male positive 10,199, age group order',
      () async {
        final g = (await StatsApi(
          client('stats_gender_latest.json'),
        ).latestGender()).right;
        expect(g.sourceDay, 799);
        expect(g.positive.male.total, 10199);
        expect(g.positive.female.ageGroups['55_plus'], 1223);
        expect(g.positive.male.ageGroups.keys.first, '0_14');
        expect(g.pdp.female.total, 112);
      },
    );

    test(
      'Sulteng vaccination: 2021-05-04, health worker coverage 100.36',
      () async {
        final s = (await StatsApi(
          client('vaccination_province_per_page_1.json'),
        ).vaccination(VaccinationScope.sulteng)).right;
        final d = s.days.single;
        expect(d.date, DateTime(2021, 5, 4));
        expect(d.total.cumulativeDose1, 81885);
        expect(
          d.groups[VaccineGroup.healthWorker]!.doses.coverageDose1,
          100.36,
        );
        expect(d.groups[VaccineGroup.publik]!.target, 1374811);
      },
    );

    test('national vaccination fixture parses and keys by date', () async {
      final s = (await StatsApi(
        client('vaccination_national_per_page_1.json'),
      ).vaccination(VaccinationScope.national)).right;
      expect(s.days.single.date, DateTime(2021, 2, 1));
    });
  });

  group('content', () {
    test('banners: 3 with links and image urls kept as stored', () async {
      final b = (await ContentApi(client('banners.json')).banners()).right;
      expect(b.length, 3);
      expect(
        b.first.link,
        Uri.parse('https://www.instagram.com/p/CR5q6ObHWJP'),
      );
      expect(b.first.imageUrl, startsWith('https://banuacoders.com'));
    });

    test('infographics: page, hasNext and images in queue order', () async {
      final p = (await ContentApi(
        client('infographics_per_page_1.json'),
      ).infographics(1)).right;
      expect(p.page, 1);
      expect(p.hasNext, isTrue);
      expect(p.items.single.id, 146);
      expect(p.items.single.imageUrls.length, 3);
      expect(p.items.single.imageUrls.first, endsWith('1.jpg'));
    });

    test('donations: bank, goods, WhatsApp link with digits only', () async {
      final d = (await ContentApi(
        client('donations_per_page_1.json'),
      ).donations()).right.single;
      expect(d.acceptsGoods, isTrue);
      expect(d.accounts.single.bankName, 'BCA');
      expect(d.accounts.single.accountNumber, '7921024685');
      final wa = d.contacts.firstWhere((c) => c.kind == ContactKind.whatsapp);
      expect(
        wa.uri,
        Uri.parse('https://api.whatsapp.com/send?phone=6285256087018'),
      );
      expect(
        d.imageUrl,
        'donations/July2021/eihpXTSucqIThKxLYGeT.jpg',
        reason: 'relative path is not rebuilt',
      );
    });

    test('telemedicine: free, schedule, Telegram link', () async {
      final t = (await ContentApi(
        client('telemedicines_per_page_1.json'),
      ).telemedicines()).right.single;
      expect(t.isFree, isTrue);
      expect(t.schedules.single.days, 'Senin-Jumat');
      expect(t.contacts.single.uri, Uri.parse('https://t.me/evansevansevans'));
    });

    test('partners parse', () async {
      final p = (await ContentApi(
        client('partners_per_page_2.json'),
      ).partners()).right;
      expect(p.first.name, 'Detexi');
      expect(p.first.inFooter, isTrue);
    });

    test('hospital contacts endpoint rows (nested shape) parse too', () async {
      final r = await client('contacts_owner_type_hospital_owner_id_19.json')
          .getData('/contacts');
      final rows = r.right! as List<dynamic>;
      final contacts = contactList(rows);
      expect(contacts, isNotEmpty);
      expect(contacts.first.kind, ContactKind.phone);
    });
  });

  group('contact URIs', () {
    test('table from C04', () {
      Uri? u(int t, String v) => contactFrom(t, null, v)?.uri;
      expect(u(1, 'a@b.id'), Uri.parse('mailto:a@b.id'));
      expect(u(3, '0451123'), isNull, reason: 'fax is text only');
      expect(u(4, 'example.org'), Uri.parse('https://example.org'));
      expect(u(4, 'https://example.org/x'), Uri.parse('https://example.org/x'));
      expect(
        u(5, '0812 345-6'),
        Uri.parse('https://api.whatsapp.com/send?phone=08123456'),
      );
      expect(u(8, '@palu'), Uri.parse('https://instagram.com/palu'));
      expect(u(9, 'abc'), Uri.parse('https://line.me/R/ti/p/abc'));
    });

    test('"NULL" and blank values are dropped', () {
      expect(contactFrom(2, 'Telepon', 'NULL'), isNull);
      expect(contactFrom(2, 'Telepon', ''), isNull);
      expect(
        contactList([
          {
            'contact_type_id': 2,
            'contact_type_name': 'Telepon',
            'contact': 'NULL',
          },
        ]),
        isEmpty,
      );
    });
  });
}
