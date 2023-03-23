import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:get/get.dart';
import 'package:pico_sulteng_flutter/app/data/models/infographic.dart';

class DetailInfographicController extends GetxController {
  final CarouselController carouselController = CarouselController();
  RxInt activeCarousel = 0.obs;
  final infographic = Rxn<Infographic>(null);

  final count = 0.obs;

  @override
  void onInit() {
    infographic.value = Get.arguments['infographic'] as Infographic;
    super.onInit();
  }

  void onPageChanged(int index, CarouselPageChangedReason reason) {
    activeCarousel.value = index;
  }

  @override
  void onClose() {}
  void increment() => count.value++;
}
