import 'package:flutter/material.dart';

class LocationDropdown extends StatelessWidget {
  const LocationDropdown(
      {@required this.locations,
      @required this.location,
      @required this.onChanged});

  final List<String> locations;
  final String location;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      height: 40.0,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30.0)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: location,
          onChanged: onChanged,
          items: locations
              .map(
                (e) => DropdownMenuItem(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_rounded,
                        size: 14.0,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        e,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  value: e,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
