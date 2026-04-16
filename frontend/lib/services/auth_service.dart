import 'api_service.dart';
import 'storage_service.dart';

class UserModel {
  String email;
  String password;
  String mobile;
  String school;
  String ideal;
  String place;

  UserModel({
    required this.email,
    required this.password,
    required this.mobile,
    required this.school,
    required this.ideal,
    required this.place,
  });
}

class AuthService {
  static UserModel? currentUser;

  /// Logs out the current user and clears any stored session.
  ///
  /// After logout, the app will require the user to authenticate again.
  static Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // ignore network issues; local logout still proceeds
    }
    await StorageService.clearToken();
    await StorageService.setDemoMode(false);
  }

  /// Returns true if a valid auth token exists or the app is in demo mode.
  static Future<bool> isAuthenticated() async {
    final demoMode = await StorageService.isDemoMode();
    if (demoMode) return true;

    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Returns the currently stored role for the logged in user.
  /// In demo mode, this returns "demo".
  static Future<String> getRole() async {
    final demoMode = await StorageService.isDemoMode();
    if (demoMode) return 'demo';
    return (await StorageService.getRole()) ?? 'user';
  }

  /// Sets the app into demo mode, clearing any stored auth token.
  static Future<void> startDemoMode() async {
    await StorageService.clearToken();
    await StorageService.setDemoMode(true);
  }

  /// Returns true if the user is authenticated or the app is in demo mode.
  static Future<bool> isAuthenticatedOrDemo() async {
    return await isAuthenticated();
  }
}
