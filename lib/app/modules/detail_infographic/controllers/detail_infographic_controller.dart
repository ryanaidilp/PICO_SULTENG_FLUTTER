import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:get/get.dart';

class DetailInfographicController extends GetxController {
  final CarouselController carouselController = CarouselController();
  RxInt activeCarousel = 0.obs;

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  void onPageChanged(int index, CarouselPageChangedReason reason) {
    activeCarousel.value = index;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {}
  void increment() => count.value++;
}
