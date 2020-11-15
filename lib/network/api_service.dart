import 'dart:async';
import 'dart:convert';

import 'package:covid_app/models/Posts.dart';
import 'package:covid_app/models/district.dart';
import 'package:covid_app/models/hospital.dart';
import 'package:covid_app/models/local.dart';
import 'package:covid_app/models/national.dart';
import 'package:covid_app/models/province.dart';
import 'package:http/http.dart' as http;

enum Endpoint { district, province, hospital, posts, local, national }

class APIService {
  static var client = http.Client();

  static Future<List<Province>> getAllProvince() async {
    final url = _getUrl(Endpoint.province);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<Province> _provinces =
          _data.map((json) => provinceFromJson(jsonEncode(json))).toList();
      return _provinces;
    } else {
      return null;
    }
  }

  static Future<List<District>> getAllDistrict() async {
    final url = _getUrl(Endpoint.district);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<District> _district =
          _data.map((json) => districtFromJson(jsonEncode(json))).toList();
      return _district;
    } else {
      return null;
    }
  }

  static Future<List<National>> getNationalCaseHistory() async {
    final url = _getUrl(Endpoint.national);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<National> _national =
          _data.map((json) => nationalFromJson(jsonEncode(json))).toList();
      return _national;
    } else {
      return null;
    }
  }

  static Future<List<Hospital>> getHospitals() async {
    final url = _getUrl(Endpoint.hospital);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<Hospital> _hospital =
          _data.map((e) => hospitalFromJson(jsonEncode(e))).toList();
      return _hospital;
    } else {
      return null;
    }
  }

  static Future<List<Posts>> getAllPosts() async {
    final url = _getUrl(Endpoint.posts);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<Posts> _posts =
          _data.map((e) => postsFromJson(jsonEncode(e))).toList();
      return _posts;
    } else {
      return null;
    }
  }

  static Future<List<Local>> getLocalCaseHistory() async {
    final url = _getUrl(Endpoint.local);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      List _data = body['data'];
      List<Local> _local =
          _data.map((json) => localFromJson(jsonEncode(json))).toList();
      return _local;
    } else {
      return null;
    }
  }

  static final String _host = 'BASE_URL';

  static String _getUrl(Endpoint endpoint) => '$_host/${_paths[endpoint]}';

  static Map<Endpoint, String> _paths = {
    Endpoint.district: 'kabupaten',
    Endpoint.province: 'provinsi',
    Endpoint.national: 'nasional',
    Endpoint.local: 'statistik',
    Endpoint.hospital: 'rumahsakit',
    Endpoint.posts: 'posko'
  };
}
