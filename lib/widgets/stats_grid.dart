import 'package:covid_app/utils/utils.dart';
import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid(
      {this.total,
      this.active,
      this.recovered,
      this.deceased,
      this.newActive,
      this.newTotal,
      this.newDeceased,
      this.newRecovered});

  final int total;
  final int active;
  final int recovered;
  final int deceased;
  final int newTotal;
  final int newActive;
  final int newRecovered;
  final int newDeceased;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      child: Column(
        children: <Widget>[
          Flexible(
            child: Row(
              children: <Widget>[
                _buildStatCard('Total Kasus', Colors.red[800], total, newTotal),
                _buildStatCard(
                    'Dirawat', Colors.blueAccent[700], active, newActive),
              ],
            ),
          ),
          Flexible(
            child: Row(
              children: <Widget>[
                _buildStatCard(
                    'Sembuh', Colors.green[800], recovered, newRecovered),
                _buildStatCard(
                    'Meninggal', Colors.yellow[800], deceased, newDeceased),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Expanded _buildStatCard(String title, Color color, int value, int newValue) {
    IconData _icon = newValue > 0
        ? Icons.arrow_circle_up_rounded
        : Icons.arrow_circle_down_rounded;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              formatNumber(value),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
            Row(
              children: <Widget>[
                Icon(_icon, color: Colors.white, size: 16.0),
                SizedBox(width: 2.0),
                Text(
                  formatNumber(newValue),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
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
