import 'package:covid_app/controllers/district_controller.dart';
import 'package:covid_app/controllers/province_controller.dart';
import 'package:covid_app/models/district.dart';
import 'package:covid_app/models/province.dart';
import 'package:covid_app/widgets/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final provinceController =
      Get.find<ProvinceController>(tag: 'ProvinceController');
  final districtController =
      Get.find<DistrictController>(tag: 'DistrictController');

  List<District> _districts;
  List<Province> _province;

  @override
  void initState() {
    if (!districtController.isLoading.value) {
      _districts = districtController.districts;
    }

    if (!provinceController.isLoading.value) {
      _province = provinceController.provinces;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: CustomAppBar(),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [_buildHeader(screenHeight), _buildMapContent()],
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(double screenHeight) {
    return SliverToBoxAdapter(
        child: Container(
      height: screenHeight * 0.1,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40.0),
              bottomRight: Radius.circular(40.0))),
      child: Stack(children: <Widget>[
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
                      'Peta Penyebaran',
                      style: TextStyle(
                          fontSize: 25.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        )
      ]),
    ));
  }

  Widget _buildNationalMap() {
    if (_province == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: [
        Text('Peta Sebaran Kasus COVID-19 di Indonesia'),
        SizedBox(height: 5.0),
        SfMaps(
          layers: [
            MapShapeLayer(
              strokeColor: Colors.grey,
              delegate: MapShapeLayerDelegate(
                  shapeFile: 'assets/geojson/indonesia.json',
                  shapeDataField: 'id',
                  dataCount: _province.length,
                  primaryValueMapper: (int index) => _province[index].mapId,
                  dataLabelMapper: (int index) =>
                      _province[index].positive.toString(),
                  shapeTooltipTextMapper: (int index) {
                    var province = _province[index];
                    return '${province.name}\nPositif: ${province.positive}';
                  },
                  bubbleSizeMapper: (int index) =>
                      double.parse(_province[index].positive.toString()),
                  bubbleTooltipTextMapper: (int index) {
                    var province = _province[index];
                    return '${province.name}' +
                        '\nPositif  : ${province.positive}' +
                        '\nDirawat  : ${province.underTreatment}' +
                        '\nSembuh   : ${province.recovered}' +
                        '\nMeninggal: ${province.deceased}';
                  }

                  // shapeColorMappers: [
                  //   MapColorMapper(from: 0, to: 10, color: Colors.red[100]),
                  //   MapColorMapper(from: 11, to: 20, color: Colors.red[200]),
                  //   MapColorMapper(from: 21, to: 30, color: Colors.red[300]),
                  //   MapColorMapper(from: 31, to: 40, color: Colors.red[400]),
                  //   MapColorMapper(from: 41, to: 50, color: Colors.red[500]),
                  //   MapColorMapper(from: 51, to: 60, color: Colors.red[600]),
                  // ],
                  // shapeColorValueMapper: (int index) =>
                  //     _province[index].positive,
                  ),
              showDataLabels: true,
              dataLabelSettings: MapDataLabelSettings(
                  textStyle: TextStyle(color: Colors.white)),
              bubbleSettings:
                  MapBubbleSettings(opacity: 0.8, color: Colors.red[800]),
              showBubbles: true,
              enableBubbleTooltip: true,
              zoomPanBehavior: MapZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
              ),
              loadingBuilder: (BuildContext context) {
                return Container(
                  height: 25,
                  width: 25,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                );
              },
            )
          ],
        ),
      ],
    );
  }

  Widget _buildLocalMap() {
    if (_districts == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: [
        Text('Peta Sebaran Kasus COVID-19 di Sulawesi Tengah'),
        SizedBox(height: 5.0),
        SfMaps(
          layers: [
            MapShapeLayer(
              strokeColor: Colors.grey,
              delegate: MapShapeLayerDelegate(
                  shapeFile: 'assets/geojson/sulteng.json',
                  shapeDataField: 'id',
                  dataCount: _districts.length,
                  primaryValueMapper: (int index) => _districts[index].name,
                  dataLabelMapper: (int index) =>
                      _districts[index].positive.toString(),
                  bubbleTooltipTextMapper: (int index) {
                    var district = _districts[index];
                    return '${district.name}' +
                        '\nPositif  : ${district.positive}' +
                        '\nDirawat  : ${district.positive - (district.deceased + district.recovered)}' +
                        '\nSembuh   : ${district.recovered}' +
                        '\nMeninggal: ${district.deceased}';
                  },
                  bubbleSizeMapper: (int index) =>
                      double.parse(_districts[index].positive.toString())
                  // shapeColorMappers: [
                  //   MapColorMapper(from: 0, to: 10, color: Colors.red[100]),
                  //   MapColorMapper(from: 11, to: 20, color: Colors.red[200]),
                  //   MapColorMapper(from: 21, to: 30, color: Colors.red[300]),
                  //   MapColorMapper(from: 31, to: 40, color: Colors.red[400]),
                  //   MapColorMapper(from: 41, to: 50, color: Colors.red[500]),
                  //   MapColorMapper(from: 51, to: 60, color: Colors.red[600]),
                  // ],
                  // shapeColorValueMapper: (int index) =>
                  //     _districts[index].positive,
                  ),
              showDataLabels: true,
              dataLabelSettings: MapDataLabelSettings(
                  textStyle: TextStyle(color: Colors.white)),
              enableBubbleTooltip: true,
              bubbleSettings: MapBubbleSettings(
                opacity: 0.8,
                color: Colors.red[800],
              ),
              showBubbles: true,
              zoomPanBehavior: MapZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
              ),
              loadingBuilder: (BuildContext context) {
                return Container(
                  height: 25,
                  width: 25,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                );
              },
            )
          ],
        ),
      ],
    );
  }

  _tooltipBuilder(context, index) {
    var district = _districts[index];
    return Container(
      color: Colors.white,
      width: 180.0,
      height: 80.0,
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Text(
            district.name,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  SliverPadding _buildMapContent() {
    return SliverPadding(
      padding: EdgeInsets.all(20.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: <Widget>[
            Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildLocalMap(),
              ),
            ),
            SizedBox(height: 10.0),
            Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildNationalMap(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
