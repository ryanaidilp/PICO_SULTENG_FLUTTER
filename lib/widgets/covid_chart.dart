import 'package:covid_app/controllers/statistic_controller.dart';
import 'package:covid_app/models/local.dart';
import 'package:covid_app/models/national.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CovidChart extends StatelessWidget {
  CovidChart({this.location, this.type});

  final int location;
  final int type;

  final statController =
  Get.find<StatisticController>(tag: 'StatisticController');

  Widget _buildBarChart(List<ColumnSeries<dynamic, String>> series,
      String location, String type) {
    return Container(
      child: SfCartesianChart(
          title: ChartTitle(text: 'Kasus $type Harian $location'),
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(),
          zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enablePinching: true,
              enableSelectionZooming: true,
              enableDoubleTapZooming: true),
          series: series),
    );
  }

  Widget _buildLineChart(List<LineSeries<dynamic, String>> series,
      String location, String type) {
    return Container(
      child: SfCartesianChart(
        title: ChartTitle(text: 'Kasus $type Harian $location'),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            enablePinching: true,
            enableSelectionZooming: true,
            enableDoubleTapZooming: true),
        series: series,
      ),
    );
  }

  Widget _buildPositiveChart() {
    if (location == 0) {
      var series = <ColumnSeries<Local, String>>[
        ColumnSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Positif',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.newPositive,
          color: Colors.red[800],
        )
      ];
      return _buildBarChart(series, 'Sulawesi Tengah', 'Positif');
    }
    var series = <ColumnSeries<National, String>>[
      ColumnSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Positif',
        dataSource: statController.nationals,
        xValueMapper: (National national, _) =>
            DateFormat.yMMMd('id').format(national.date),
        yValueMapper: (National national, _) => national.newPositive,
        color: Colors.red[800],
      )
    ];
    return _buildBarChart(series, 'Indonesia', 'Positif');
  }

  Widget _buildRecoveredChart() {
    if (location == 0) {
      var series = <ColumnSeries<Local, String>>[
        ColumnSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Sembuh',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.newRecovered,
          color: Colors.green[800],
        )
      ];
      return _buildBarChart(series, 'Sulawesi Tengah', 'Sembuh');
    }
    var series = <ColumnSeries<National, String>>[
      ColumnSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Sembuh',
        dataSource: statController.nationals,
        xValueMapper: (National national, _) =>
            DateFormat.yMMMd('id').format(national.date),
        yValueMapper: (National national, _) => national.newRecovered,
        color: Colors.green[800],
      )
    ];
    return _buildBarChart(series, 'Indonesia', 'Sembuh');
  }

  Widget _buildDeceasedChart() {
    if (location == 0) {
      var series = <ColumnSeries<Local, String>>[
        ColumnSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Meninggal',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.newDeceased,
          color: Colors.yellow[800],
        )
      ];
      return _buildBarChart(series, 'Sulawesi Tengah', 'Meninggal');
    }
    var series = <ColumnSeries<National, String>>[
      ColumnSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Meninggal',
        dataSource: statController.nationals,
        xValueMapper: (National national, _) =>
            DateFormat.yMMMd('id').format(national.date),
        yValueMapper: (National national, _) => national.newRecovered,
        color: Colors.yellow[800],
      )
    ];
    return _buildBarChart(series, 'Indonesia', 'Meninggal');
  }

  Widget _buildUnderTreatmentChart() {
    if (location == 0) {
      var series = <LineSeries<Local, String>>[
        LineSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Dirawat',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.newUnderTreatment,
          color: Colors.blueAccent[700],
        )
      ];
      return _buildLineChart(series, 'Sulawesi Tengah', 'Dirawat');
    }
    var series = <LineSeries<National, String>>[
      LineSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Dirawat',
        dataSource: statController.nationals,
        xValueMapper: (National national, _) =>
            DateFormat.yMMMd('id').format(national.date),
        yValueMapper: (National national, _) => national.newUnderTreatment,
        color: Colors.blueAccent[700],
      )
    ];
    return _buildLineChart(series, 'Indonesia', 'Dirawat');
  }

  Widget _buildDailyChart() {
    return Column(
      children: <Widget>[
        _buildUnderTreatmentChart(),
        _buildPositiveChart(),
        _buildRecoveredChart(),
        _buildDeceasedChart()
      ],
    );
  }

  Widget _buildCumulativeChart() {
    if (location == 0) {
      var series = <LineSeries<Local, String>>[
        LineSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Positif',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.cumulativePositive,
          color: Colors.red[800],
        ),
        LineSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Sembuh',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.cumulativeRecovered,
          color: Colors.green[800],
        ),
        LineSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Meninggal',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.cumulativeDeceased,
          color: Colors.yellow[800],
        ),
        LineSeries<Local, String>(
          xAxisName: 'Tanggal',
          name: 'Dirawat',
          dataSource: statController.locals,
          xValueMapper: (Local local, _) => local.date,
          yValueMapper: (Local local, _) => local.cumulativeUnderTreatment,
          color: Colors.blueAccent[700],
        )
      ];
      return _buildLineChart(series, 'Sulawesi Tengah', 'Kumulatif');
    }

    var series = <LineSeries<National, String>>[
      LineSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Positif',
        dataSource: statController.nationals,
        xValueMapper: (National local, _) => DateFormat.yMMMd('id').format(local.date),
        yValueMapper: (National local, _) => local.cumulativePositive,
        color: Colors.red[800],
      ),
      LineSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Sembuh',
        dataSource: statController.nationals,
        xValueMapper: (National local, _) => DateFormat.yMMMd('id').format(local.date),
        yValueMapper: (National local, _) => local.cumulativeRecovered,
        color: Colors.green[800],
      ),
      LineSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Meninggal',
        dataSource: statController.nationals,
        xValueMapper: (National local, _) => DateFormat.yMMMd('id').format(local.date),
        yValueMapper: (National local, _) => local.cumulativeDeceased,
        color: Colors.yellow[800],
      ),
      LineSeries<National, String>(
        xAxisName: 'Tanggal',
        name: 'Dirawat',
        dataSource: statController.nationals,
        xValueMapper: (National local, _) => DateFormat.yMMMd('id').format(local.date),
        yValueMapper: (National local, _) => local.cumulativeUnderTreatment,
        color: Colors.blueAccent[700],
      )
    ];
    return _buildLineChart(series, 'Indonesia', 'Kumulatif');
  }

  Widget _buildChartSection() {
    List<Widget> widgets = [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Visualisasi',
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
      ),
    ];
    if(type == 0) {
      widgets.add(_buildDailyChart());
    } else{
      widgets.add(_buildCumulativeChart());
    }
    return Column(
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery
          .of(context)
          .size
          .width,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0))),
      child: _buildChartSection(),
    );
  }
}
