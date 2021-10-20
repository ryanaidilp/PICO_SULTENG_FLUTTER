import 'dart:convert';

import 'package:flutter_config/flutter_config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pico_sulteng_flutter/app/data/models/article.dart';
import 'package:pico_sulteng_flutter/app/data/models/banner.dart' as model;
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';
import 'package:pico_sulteng_flutter/app/data/models/national_statistic.dart';
import 'package:pico_sulteng_flutter/app/data/models/province_test.dart';
import 'package:pico_sulteng_flutter/app/data/models/regency_statistic.dart';
import 'package:pico_sulteng_flutter/app/data/models/statistic.dart';
import 'package:pico_sulteng_flutter/app/data/models/vaccine.dart';

class ApiProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = FlutterConfig.get('BASE_URL').toString();
  }

  Future<List<model.Banner>> loadBanners() async {
    final response = await get('/banner');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final List<dynamic> data = response.body['data'] as List;
    return data
        .map((e) => model.Banner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Statistic> loadProvince() async {
    final response = await get('/statistik/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data'] as Map<String, dynamic>;
    return Statistic.fromJson(data);
  }

  Future<List<ProvinceTest>> loadProvinceTest() async {
    final response = await get('/test/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final List<dynamic> data = response.body['data'] as List<dynamic>;
    return data
        .map((e) => ProvinceTest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vaccine> loadProvinceVaccine() async {
    final response = await get('/vaksin/72/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data'];
    return Vaccine.fromJson(data as Map<String, dynamic>);
  }

  Future<Vaccine> loadNationalVaccine() async {
    final response = await get('/vaksin/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data'];
    return Vaccine.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Infographic>> loadInfographics(int page) async {
    final response = await get('/infografis?page=$page');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data']['data'] as List<dynamic>;

    return data
        .map((json) => Infographic.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Article>> loadArticles(int page) async {
    const baseUrl =
        'https://newsapi.org/v2/everything?q=covid&language=id&page=';
    final String key = FlutterConfig.get('NEWSAPI_API_KEY').toString();
    final StringBuffer buffer = StringBuffer();
    buffer.writeAll([baseUrl, page, '&apiKey=', key]);
    final response = await http.get(Uri.parse(buffer.toString()));

    if (response.statusCode != 200) {
      throw Exception(response.reasonPhrase);
    }

    final dataResponse = jsonDecode(response.body);
    final data = dataResponse['articles'] as List<dynamic>;

    return data
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<NationalStatistic> loadNationalStatistic() async {
    final response = await get('/nasional/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data'] as Map<String, dynamic>;

    return NationalStatistic.fromJson(data);
  }

  Future<List<RegencyStatistic>> loadRegencyStatistic() async {
    final response = await get('/provinsi/72/terkini');

    if (response.hasError) {
      throw Exception(response.statusText.toString());
    }

    final data = response.body['data'] as List<dynamic>;

    return data
        .map((json) => RegencyStatistic.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
