import 'package:covid_app/models/Posts.dart';
import 'package:covid_app/network/api_service.dart';
import 'package:get/state_manager.dart';

class PostsController extends GetxController {
  var posts = List<Posts>().obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchPostsData();
    super.onInit();
  }

  void fetchPostsData() async {
    try {
      isLoading(true);
      var _posts = await APIService.getAllPosts();
      if (_posts != null) {
        posts.assignAll(_posts);
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading(false);
    }
  }
}
