import 'package:get_storage/get_storage.dart';

import 'keys.dart';

class AppLogic {
  String accessToken = '';

  //User? user;
  final box = GetStorage();

  Future<void> init() async {
    final userPref = box.read(AppKeys.user);
    if (userPref != null) {
      // User userFromLocalStorage = User.fromJson(jsonDecode(userPref));
      // user = userFromLocalStorage;
    }
    // final accessTokenPref = box.read(AppKeys.accessToken);
    // if (accessTokenPref != null) {
    //   accessToken = accessTokenPref;
    // }
  }

  Future<void> clearDataAndRouteToLogin() async {
    //AppRouter.router.go(Routes.login);
    accessToken = '';
    //user = null;
    await box.erase();
  }
}
