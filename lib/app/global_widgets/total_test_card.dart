import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class TotalTestCard extends StatelessWidget {
  const TotalTestCard({Key? key, required this.total, this.onPressed})
      : super(key: key);

  final int total;
  final GestureTapCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      tileColor: Colors.grey.shade50,
      title: Text(
        LocaleKeys.test_label.tr,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 14.0,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      subtitle: Text(
        numberFormat(total),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 26.0,
          overflow: TextOverflow.ellipsis,
          color: Colors.black,
        ),
      ),
      trailing: IconButton(
        onPressed: onPressed,
        splashColor: Colors.white,
        icon: Icon(
          Iconsax.arrow_right_14,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
