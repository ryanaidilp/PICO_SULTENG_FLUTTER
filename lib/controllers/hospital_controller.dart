import 'package:covid_app/models/hospital.dart';
import 'package:covid_app/network/api_service.dart';
import 'package:get/state_manager.dart';

class HospitalController extends GetxController {
  var hospitals = List<Hospital>().obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchHospitals();
    super.onInit();
  }

  void fetchHospitals() async {
    try {
      isLoading(true);
      var _hospitals = await APIService.getHospitals();
      if(_hospitals != null) {
        hospitals.assignAll(_hospitals);
      }
    }catch(e) {
      print(e);
    }finally {
      isLoading(false);
    }
  }
}