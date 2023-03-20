import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/core/utils/helper.dart';
import 'package:pico_sulteng_flutter/app/data/models/article.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        elevation: 10.0,
        shadowColor: Colors.grey.shade200,
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () {
            Get.toNamed(Routes.inAppWebPage, arguments: {
              'title': article.title,
              'link': article.url,
            },);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10.0),
                  topLeft: Radius.circular(10.0),
                ),
                child: ExtendedImage.network(
                  article.cover,
                  width: double.infinity,
                  height: 200.0,
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 18.0,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      dateWithDayFormat(
                        article.publishedAt,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    RichText(
                      text: TextSpan(
                        text: article.author,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14.0,
                        ),
                        children: [
                          const TextSpan(text: ' - '),
                          TextSpan(text: article.source),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      article.description,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
