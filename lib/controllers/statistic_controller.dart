import 'package:covid_app/models/local.dart';
import 'package:covid_app/models/national.dart';
import 'package:covid_app/network/api_service.dart';
import 'package:get/state_manager.dart';

class StatisticController extends GetxController {
  var nationals = List<National>().obs;
  var locals = List<Local>().obs;
  var loadingNational = true.obs;
  var loadingLocal = true.obs;

  @override
  void onInit() {
    fetchDataNational();
    fetchDataLocal();
    super.onInit();
  }

  void fetchDataNational() async {
    try {
      loadingNational(true);
      var _nationals = await APIService.getNationalCaseHistory();
      if (_nationals != null) {
        nationals.assignAll(_nationals);
      }
    } catch (e) {
      print(e);
    } finally {
      loadingNational(false);
    }
  }

  void fetchDataLocal() async {
    try {
      loadingLocal(true);
      var _locals = await APIService.getLocalCaseHistory();
      if (_locals != null) {
        locals.assignAll(_locals);
      }
    } catch (e) {
      print(e);
    } finally {
      loadingLocal(false);
    }
  }
}
