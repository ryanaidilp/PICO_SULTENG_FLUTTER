import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'Cured Case',
  type: PicoCaseCard,
)
Widget curedCasedCard(BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: StaggeredGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            children: [
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
              PicoCaseCard.cured(
                total: context.knobs.int.input(
                  label: 'Total',
                  description: 'Total cured.',
                ),
                newCase: context.knobs.int.input(
                  label: 'New Case',
                  description: 'New cured case.',
                ),
              ),
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
            ],
          ),
        ),
      ),
    );

@UseCase(
  name: 'Under Treatment Case',
  type: PicoCaseCard,
)
Widget treatmentCasedCard(BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: StaggeredGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            children: [
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
              PicoCaseCard.treatment(
                total: context.knobs.int.input(
                  label: 'Total',
                  description: 'Total under treatment.',
                ),
                newCase: context.knobs.int.input(
                  label: 'New Case',
                  description: 'New under treatment case.',
                ),
              ),
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
            ],
          ),
        ),
      ),
    );

@UseCase(
  name: 'Death Case',
  type: PicoCaseCard,
)
Widget deathCaseCasrd(BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: StaggeredGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            children: [
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
              PicoCaseCard.death(
                total: context.knobs.int.input(
                  label: 'Total',
                  description: 'Total death.',
                ),
                newCase: context.knobs.int.input(
                  label: 'New Case',
                  description: 'New death case.',
                ),
              ),
              SizedBox(
                width: 1.sw,
                height: 50.h,
              ),
            ],
          ),
        ),
      ),
    );
