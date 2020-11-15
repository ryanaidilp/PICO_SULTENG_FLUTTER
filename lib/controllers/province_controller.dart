import 'package:covid_app/models/province.dart';
import 'package:covid_app/network/api_service.dart';
import 'package:get/state_manager.dart';

class ProvinceController extends GetxController {
  var provinces = List<Province>().obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchProvince();
    super.onInit();
  }

  void fetchProvince() async {
    try{
      isLoading(true);
      var _provinces = await APIService.getAllProvince();
      if(_provinces != null) {
        provinces.assignAll(_provinces);
      }
    }catch(e) {
      print(e.toString());
    }finally {
      isLoading(false);
    }
  }
}