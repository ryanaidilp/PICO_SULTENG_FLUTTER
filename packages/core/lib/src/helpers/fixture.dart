import 'dart:convert';
import 'dart:io';

class Fixture {
  const Fixture._();

  static String fixture(String name) =>
      File('test/fixtures/$name').readAsStringSync();
  static Map<String, dynamic> jsonFromFixture(String name) {
    final jsonString = fixture(name);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    return data;
  }
}
