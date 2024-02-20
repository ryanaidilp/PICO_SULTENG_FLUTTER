import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

@RoutePage()
class TestDetailPage extends StatelessWidget {
  const TestDetailPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LatestCovidTestCubit, LatestCovidTestState>(
        builder: (context, state) {
          if (state is LatestCovidTestLoadedState) {
            final testDescriptions = {
              'pcr': context.i10n.test.pcr.description,
              'rdt': context.i10n.test.rdt.description,
            };

            return DefaultTabController(
              length: state.data.length,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    context.i10n.card_case_label.total_test,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  bottom: ButtonsTabBar(
                    backgroundColor: context.picoColors.semantic.primary,
                    unselectedBackgroundColor: Colors.transparent,
                    radius: 8.r,
                    buttonMargin: EdgeInsets.all(8.r),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                    ),
                    borderWidth: 1.sp,
                    borderColor: context.picoColors.outline.semantic.primary,
                    unselectedBorderColor:
                        context.picoColors.outline.neutral.strong,
                    labelStyle: PicoTextStyle.body(
                      color: Colors.white,
                    ),
                    unselectedLabelStyle: PicoTextStyle.body(
                      color: context.picoColors.text.neutral.subtle,
                    ),
                    tabs: List.generate(
                      state.data.length,
                      (index) => Tab(
                        text: state.data[index].nameAbbreviation,
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: List.generate(
                    state.data.length,
                    (index) {
                      final test = state.data[index];

                      return ListView(
                        padding: EdgeInsets.all(16.r),
                        children: [
                          PicoUpdatedAtPlaceholder(
                            label: test.name,
                            date: DateHelper.buildUpdatedAtText(test.updatedAt),
                          ),
                          8.verticalSpace,
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.orange.shade100.withOpacity(0.5),
                                    blurRadius: 10.r,
                                    spreadRadius: 3.r,
                                    offset: Offset.fromDirection(-30, 5),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(10.r),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange,
                                    Colors.orange.shade200,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      test.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      testDescriptions[test.nameAbbreviation
                                              .toLowerCase()] ??
                                          '',
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 10.sp,
                                        ),
                                        4.horizontalSpace,
                                        Text(
                                          context.i10n.card_case_label.sample,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      test.sample,
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 10.sp,
                                        ),
                                        4.horizontalSpace,
                                        Text(
                                          context.i10n.card_case_label.duration,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      test.duration,
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          8.verticalSpace,
                          PicoTotalTestCard(
                            total: test.total,
                          ),
                          8.verticalSpace,
                          StaggeredGrid.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.w,
                            mainAxisSpacing: 8.h,
                            children: [
                              PicoTestCaseCard.reactive(
                                count: test.positive,
                                percentage: test.reactivePercentage,
                              ),
                              PicoTestCaseCard.nonReactive(
                                count: test.negative,
                                percentage: test.nonReactivePercentage,
                              ),
                              PicoTestCaseCard.invalid(
                                count: test.invalid,
                                percentage: test.invalidPercentage,
                              ),
                              PicoTestCaseCard.process(
                                count: test.process,
                                percentage: test.inProcessPercentage,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                context.i10n.card_case_label.total_test,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Center(
              child: SpinKitChasingDots(
                color: context.picoColors.semantic.primary,
                size: 20.sp,
              ),
            ),
          );
        },
      );
}
