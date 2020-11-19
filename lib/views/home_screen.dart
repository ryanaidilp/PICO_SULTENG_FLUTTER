import 'package:covid_app/controllers/district_controller.dart';
import 'package:covid_app/controllers/province_controller.dart';
import 'package:covid_app/controllers/statistic_controller.dart';
import 'package:covid_app/models/district.dart';
import 'package:covid_app/models/local.dart';
import 'package:covid_app/models/national.dart';
import 'package:covid_app/models/province.dart';
import 'package:covid_app/utils/styles.dart';
import 'package:covid_app/utils/utils.dart';
import 'package:covid_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _location = 'Sulteng';
  final _provinceController =
      Get.put(ProvinceController(), tag: 'ProvinceController');
  final _districtController =
      Get.put(DistrictController(), tag: 'DistrictController');
  final _statisticController =
      Get.put(StatisticController(), tag: 'StatisticController');

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: CustomAppBar(),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: <Widget>[
          _buildHeader(screenHeight),
          _buildPreventionTips(screenHeight),
          _buildSelfEnumerationSection(screenHeight),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Kasus di $_location',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: screenHeight * 0.02)
                ],
              ),
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSelfEnumerationSection(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        padding: const EdgeInsets.all(10.0),
        height: screenHeight * 0.15,
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent[100], Colors.blueAccent[400]],
            ),
            borderRadius: BorderRadius.circular(20.0)),
        child: InkWell(
          onTap: () {
            launch('https://detexi.id');
          },
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Image.asset('assets/images/detexi.png'),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Konsultasi Online',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0),
                      ),
                      SizedBox(height: 10.0),
                      Expanded(
                        child: Text(
                          'Anda bergejala COVID-19? Ingin memeriksakan diri tapi takut keluar rumah? Kini kamu bisa memeriksakan diri dari rumah. Tekan banner ini untuk konsultasi.',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14.0),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.0),
                  bottomRight: Radius.circular(40.0))),
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: Image.asset('assets/images/virus.png')),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'COVID-19',
                            style: TextStyle(
                                fontSize: 25.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          LocationDropdown(
                              locations: ['Sulteng', 'Indonesia'],
                              location: _location,
                              onChanged: (val) =>
                                  setState(() => _location = val))
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Apakah anda merasa kurang sehat?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Jika kamu merasa kurang sehat dan mengalami gejala COVID-19, hubungi nomor dibawah ini.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15.0,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton.icon(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            onPressed: () {
                              launch('tel:119');
                            },
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Call Center',
                                  style: Styles.buttonTextStyle,
                                ),
                                Text(
                                  'Nomor Darurat',
                                  style: TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.blueAccent[700]),
                                ),
                                Text(
                                  '119',
                                  style: TextStyle(
                                      color: Colors.blueAccent[400],
                                      fontSize: 12.0),
                                )
                              ],
                            ),
                            icon: Icon(
                              Icons.phone,
                              color: Colors.blueAccent[700],
                            ),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            textColor: Colors.blueAccent[700],
                          ),
                          FlatButton.icon(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            onPressed: () {
                              launch('tel:0811404119');
                            },
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Hotline',
                                  style: Styles.buttonTextStyle,
                                ),
                                Text(
                                  'Dinkes Sulteng',
                                  style: TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.blueAccent[700]),
                                ),
                                Text(
                                  '+62811-404-119',
                                  style: TextStyle(
                                      color: Colors.blueAccent[400],
                                      fontSize: 12.0),
                                )
                              ],
                            ),
                            icon: Icon(
                              Icons.phone,
                              color: Colors.blueAccent[700],
                            ),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            textColor: Colors.blueAccent[700],
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ],
          )),
    );
  }

  SliverToBoxAdapter _buildPreventionTips(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tips Pencegahan',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: preventions
                    .map((e) => Column(
                          children: <Widget>[
                            Image.asset(
                              e.keys.first,
                              height: screenHeight * 0.12,
                            ),
                            Text(e.values.first)
                          ],
                        ))
                    .toList()),
          ],
        ),
      ),
    );
  }

  Obx _buildContent() {
    return Obx(() {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _location == 'Sulteng'
                ? _buildDistrictList()
                : _buildProvinceList(),
          ),
        ),
      );
    });
  }

  Widget _buildLatestUpdateSection(DateTime lastUpdate) {
    return Row(
      children: <Widget>[
        Text(
          'Pembaruan terakhir : ',
          style: TextStyle(color: Colors.grey, fontSize: 12.0),
        ),
        Text(
          '${DateFormat.yMMMMEEEEd('id').format(lastUpdate)} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 12.0
          ),
        )
      ],
    );
  }

  Widget _buildLocalData(String title, Color color) {
    if (_statisticController.loadingLocal.value) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    Local local = _statisticController.locals.last;
    int newCase = 0;
    int cumulative = 0;
    switch (title) {
      case 'POSITIF':
        newCase = local.newPositive;
        cumulative = local.cumulativePositive;
        break;
      case 'SEMBUH':
        newCase = local.newRecovered;
        cumulative = local.cumulativeRecovered;
        break;
      case 'DIRAWAT':
        newCase = local.newUnderTreatment;
        cumulative = local.cumulativeUnderTreatment;
        break;
      case 'MENINGGAL':
        newCase = local.newDeceased;
        cumulative = local.cumulativeDeceased;
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Sulawesi Tengah',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10.0),
        ),
        Text(
          formatNumber(cumulative),
          style: Styles.caseNumberTextStyle
              .copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildNewCaseIcon(newCase, color),
            SizedBox(width: 2.0),
            Text(
              formatNumber(newCase),
              style: Styles.caseNumberTextStyle
                  .copyWith(color: color, fontSize: 16.0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNationalData(String title, Color color) {
    if (_statisticController.loadingNational.value) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    National national = _statisticController.nationals.last;
    int newCase = 0;
    int cumulative = 0;
    switch (title) {
      case 'POSITIF':
        newCase = national.newPositive;
        cumulative = national.cumulativePositive;
        break;
      case 'SEMBUH':
        newCase = national.newRecovered;
        cumulative = national.cumulativeRecovered;
        break;
      case 'DIRAWAT':
        newCase = national.newUnderTreatment;
        cumulative = national.cumulativeUnderTreatment;
        break;
      case 'MENINGGAL':
        newCase = national.newDeceased;
        cumulative = national.cumulativeDeceased;
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Indonesia',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10.0),
        ),
        Text(
          formatNumber(cumulative),
          style: Styles.caseNumberTextStyle
              .copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildNewCaseIcon(newCase, color),
            SizedBox(width: 2.0),
            Text(
              formatNumber(newCase),
              style: Styles.caseNumberTextStyle
                  .copyWith(color: color, fontSize: 16.0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewCaseIcon(int number, Color color) {
    var icon = number > 0
        ? Icons.arrow_circle_up_rounded
        : Icons.arrow_circle_down_rounded;
    return Icon(
      icon,
      color: color,
      size: 18.0,
    );
  }

  Widget _buildCaseCard(String title, Color color) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 16.0),
            ),
            Row(
              children: <Widget>[
                Expanded(child: _buildLocalData(title, color)),
                Expanded(child: _buildNationalData(title, color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCaseSection() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _buildCaseCard('POSITIF', Colors.red[800])),
            Expanded(child: _buildCaseCard('DIRAWAT', Colors.blueAccent[700])),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(child: _buildCaseCard('SEMBUH', Colors.green[800])),
            Expanded(child: _buildCaseCard('MENINGGAL', Colors.yellow[800])),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildDistrictList() {
    List<Widget> _widgets = List<Widget>();
    if (_districtController.isLoading.value) {
      _widgets.add(Center(
        child: CircularProgressIndicator(),
      ));
      return _widgets;
    }
    var _lastUpdate = _districtController.districts[0].updatedAt;
    _widgets.add(_buildLatestUpdateSection(_lastUpdate));
    _widgets.add(SizedBox(height: 10.0));
    _widgets.add(_buildCardCaseSection());
    _widgets.add(SizedBox(height: 10.0));
    _widgets.add(Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        'Daftar Kabupaten',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      ),
    ));
    _widgets.addAll(_districtController.districts.map((district) {
      return _buildDistrictCard(district);
    }).toList());
    return _widgets;
  }

  Widget _buildDistrictCard(District district) {
    return Card(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              district.name,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
            Divider(thickness: 1.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      'Positif',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                    Text(
                      formatNumber(district.positive),
                      style: Styles.caseNumberTextStyle
                          .copyWith(color: Colors.red[800]),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      'Dirawat',
                      style: TextStyle(color: Colors.blueAccent[700]),
                    ),
                    Text(
                      '${district.positive - (district.deceased + district.recovered)}',
                      style: Styles.caseNumberTextStyle
                          .copyWith(color: Colors.blueAccent[700]),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      'Sembuh',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                    Text(
                      '${district.recovered}',
                      style: Styles.caseNumberTextStyle
                          .copyWith(color: Colors.green[800]),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      'Meninggal',
                      style: TextStyle(color: Colors.yellow[800]),
                    ),
                    Text(
                      '${district.deceased}',
                      style: Styles.caseNumberTextStyle
                          .copyWith(color: Colors.yellow[800]),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProvinceList() {
    List<Widget> _widgets = List<Widget>();
    if (_provinceController.isLoading.value) {
      _widgets.add(Center(
        child: CircularProgressIndicator(),
      ));
      return _widgets;
    }
    var _lastUpdate = _provinceController.provinces[0].updatedAt;
    _widgets.add(Row(
      children: <Widget>[
        Text(
          'Pembaruan terakhir : ',
          style: TextStyle(color: Colors.grey, fontSize: 12.0),
        ),
        Text(
          '${DateFormat.yMMMMEEEEd('id').format(_lastUpdate)} ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 12.0
          ),
        )
      ],
    ));
    _widgets.add(SizedBox(height: 10.0));
    _widgets.add(_buildCardCaseSection());
    _widgets.add(SizedBox(height: 10.0));
    _widgets.add(Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        'Daftar Provinsi',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      ),
    ));
    _widgets.addAll(_provinceController.provinces.map((province) {
      return _buildProvinceCard(province);
    }).toList());
    return _widgets;
  }

  Widget _buildProvinceCard(Province province) {
    return Card(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              province.name,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
            Divider(thickness: 1.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Positif',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                      Text(
                        formatNumber(province.positive),
                        style: Styles.caseNumberTextStyle
                            .copyWith(color: Colors.red[800]),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Dirawat',
                        style: TextStyle(color: Colors.blueAccent[700]),
                      ),
                      Text(
                        formatNumber(province.underTreatment),
                        style: Styles.caseNumberTextStyle
                            .copyWith(color: Colors.blueAccent[700]),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Sembuh',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                      Text(
                        formatNumber(province.recovered),
                        style: Styles.caseNumberTextStyle
                            .copyWith(color: Colors.green[800]),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Meninggal',
                        style: TextStyle(color: Colors.yellow[800]),
                      ),
                      Text(
                        formatNumber(province.deceased),
                        style: Styles.caseNumberTextStyle
                            .copyWith(color: Colors.yellow[800]),
                      )
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
