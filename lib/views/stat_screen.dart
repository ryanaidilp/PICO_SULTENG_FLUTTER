import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:covid_app/controllers/statistic_controller.dart';
import 'package:covid_app/models/local.dart';
import 'package:covid_app/models/national.dart';
import 'package:covid_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final statController =
      Get.find<StatisticController>(tag: 'StatisticController');
  Local _local;
  National _national;

  int _indexData = 0;
  int _indexType = 0;

  List<Widget> _dataWidgets = List<Widget>();

  @override
  void initState() {
    super.initState();
    if (!statController.loadingLocal.value) {
      _local = statController.locals.last;
      _dataWidgets.add(StatsGrid(
        total: _local.cumulativePositive,
        recovered: _local.cumulativeRecovered,
        active: _local.cumulativeUnderTreatment,
        deceased: _local.cumulativeDeceased,
        newActive: _local.newUnderTreatment,
        newTotal: _local.newPositive,
        newRecovered: _local.newRecovered,
        newDeceased: _local.newDeceased,
      ));
    }
    if (!statController.loadingNational.value) {
      _national = statController.nationals.last;
      _dataWidgets.add(StatsGrid(
        total: _national.cumulativePositive,
        recovered: _national.cumulativeRecovered,
        active: _national.cumulativeUnderTreatment,
        deceased: _national.cumulativeDeceased,
        newTotal: _national.newPositive,
        newActive: _national.newUnderTreatment,
        newRecovered: _national.newRecovered,
        newDeceased: _national.newDeceased,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: CustomAppBar(),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildLocationTabBar(),
          _buildCategoryTabBar(),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            sliver: SliverToBoxAdapter(
              child: _dataWidgets.isNotEmpty
                  ? _dataWidgets[_indexData]
                  : Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 20.0),
            sliver: SliverToBoxAdapter(
                child: CovidChart(
              location: _indexData,
              type: _indexType,
            )),
          ),
        ],
      ),
    );
  }

  SliverPadding _buildCategoryTabBar() {
    return SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverToBoxAdapter(
        child: DefaultTabController(
          length: 2,
          child: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.transparent,
            tabs: <Widget>[
              Text('Harian'),
              Text('Kumulatif'),
            ],
            onTap: (index) => setState(() => _indexType = index),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildLocationTabBar() {
    return SliverToBoxAdapter(
      child: DefaultTabController(
        length: 2,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          height: 50.0,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(25.0)),
          child: TabBar(
            indicator: BubbleTabIndicator(
                tabBarIndicatorSize: TabBarIndicatorSize.tab,
                indicatorHeight: 40.0,
                indicatorColor: Colors.white),
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white,
            tabs: <Widget>[
              Text('Sulawesi Tengah'),
              Text('Indonesia'),
            ],
            onTap: (index) => setState(() => _indexData = index),
          ),
        ),
      ),
    );
  }

  SliverPadding _buildHeader() {
    return SliverPadding(
      padding: EdgeInsets.all(20.0),
      sliver: SliverToBoxAdapter(
          child: Text(
        'Statistik',
        style: TextStyle(
            color: Colors.white, fontSize: 25.0, fontWeight: FontWeight.bold),
      )),
    );
  }
}
