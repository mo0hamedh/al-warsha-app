import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Stream<bool> get onlineStatus =>
      Connectivity().onConnectivityChanged.map((results) {
        // results is a List<ConnectivityResult> in connectivity_plus ^6.0.0
        return results.isNotEmpty && !results.contains(ConnectivityResult.none);
      });

  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
