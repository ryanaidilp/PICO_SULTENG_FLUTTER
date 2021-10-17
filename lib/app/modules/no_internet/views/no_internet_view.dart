import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/no_internet_controller.dart';

class NoInternetView extends GetView<NoInternetController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/no_internet.json',
                  width: Get.width * 0.8,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Tidak ada koneksi internet! Pastikan anda memiliki koneksi internet aktif untuk menggunakan aplikasi!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
