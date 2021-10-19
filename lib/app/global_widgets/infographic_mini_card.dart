import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';

class InfographicMiniCard extends StatelessWidget {
  const InfographicMiniCard(
      {Key? key, required this.infographic, required this.onTap})
      : super(key: key);

  final Infographic infographic;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: ExtendedImage.network(
                  infographic.images.first as String,
                  clearMemoryCacheWhenDispose: true,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              const SizedBox(height: 4.0),
              Expanded(
                child: Text(
                  infographic.title,
                  maxLines: 2,
                  style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                dateWithDayFormat(infographic.publishedAt),
                maxLines: 2,
                style: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  fontSize: 12.0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
