import 'package:covid_app/models/district.dart';
import 'package:covid_app/network/api_service.dart';
import 'package:get/state_manager.dart';

class DistrictController extends GetxController {
  var districts = List<District>().obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchDistricts();
    super.onInit();
  }

  void fetchDistricts() async {
    try {
      isLoading(true);
      var _districts = await APIService.getAllDistrict();
      if(_districts != null) {
        districts.assignAll(_districts);
      }
    }catch(e) {

    }finally {
      isLoading(false);
    }
  }
}