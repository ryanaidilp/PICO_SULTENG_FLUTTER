import 'package:flutter/material.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';

class CardCase extends StatelessWidget {
  const CardCase({
    Key? key,
    required this.bgColorIcon,
    required this.colorIcon,
    required this.icon,
    this.iconSize = 12.0,
    required this.total,
    required this.newCase,
    required this.label,
  }) : super(key: key);

  final Color bgColorIcon;
  final Color colorIcon;
  final IconData icon;
  final double iconSize;
  final int total;
  final int newCase;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColorIcon,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      icon,
                      color: colorIcon,
                      size: iconSize,
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              numberFormat(total),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              formatNewCase(newCase),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
