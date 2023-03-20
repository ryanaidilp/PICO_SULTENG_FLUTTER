import 'package:flutter/material.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';

class CardTestCase extends StatelessWidget {
  const CardTestCase({
    super.key,
    required this.label,
    required this.count,
    required this.percentage,
    this.isInvalid = false,
  });

  final String label;
  final int count;
  final double percentage;
  final bool isInvalid;

  @override
  Widget build(BuildContext context) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeAll(['(', percentageFormat(percentage), ')']);

    return Card(
      elevation: 0.0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(height: 6.0),
            Text(
              numberFormat(count),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22.0,
                color: isInvalid ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              buffer.toString(),
            ),
          ],
        ),
      ),
    );
  }
}
