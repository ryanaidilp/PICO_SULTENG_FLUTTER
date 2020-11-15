import 'package:covid_app/views/home_screen.dart';
import 'package:covid_app/views/views.dart';
import 'package:flutter/material.dart';

class BottomNavScreen extends StatefulWidget {
  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final List _screens = [
    HomeScreen(),
    StatsScreen(),
    ContactScreen(),
    MapScreen()
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: [
          Icons.home,
          Icons.stacked_line_chart,
          Icons.local_hospital,
          Icons.map
        ]
            .asMap()
            .map((key, value) => MapEntry(
                key,
                BottomNavigationBarItem(
                    label: '',
                    icon: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      decoration: BoxDecoration(
                          color: _currentIndex == key
                              ? Colors.blueAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.0)),
                      child: Icon(value),
                    ))))
            .values
            .toList(),
      ),
    );
  }
}
