import 'package:flutter/material.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';

class VaccineTargetCard extends StatelessWidget {
  const VaccineTargetCard({
    super.key,
    required this.total,
    required this.label,
    required this.color,
  });

  final int total;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              numberFormat(total),
              style: TextStyle(
                color: color,
                fontSize: 36.0,
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
