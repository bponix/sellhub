import 'package:sellhub/core/store/store_registry.dart';

/// Want to show another seller
/// Change Site ID and Domain Name
class AppConstants {
  static int get kDefaultSiteId => StoreRegistry.currentStore?.siteId ?? 0;
  static const int kDefaultFirst = 16;
  static String get kDefaultDomain =>
      StoreRegistry.currentStore?.domain ?? 'sellhub.bponi.com';
  static const String kBaseUrl = 'https://api.bponi.com/x';
  static const String kApiKey = 'admin';
  static const String kFallbackToken =
      'BPONI-AUTH eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOjc2ODgwLCJleHAiOjE3NTUwNTk5ODcsInJvbGUiOjN9.SN26e_Ss3kOcNvaoo5fNwqay3EBvovvoklTWGb_B2qw';
  static const String kAuthTokenKey = 'auth_token';
  static const String kAuthUserID = 'user_id';
  static const String kAuthCustomerID = 'customer_id';
  static const String kGuestKey = 'is_guest';
  static const String kLoginKey = 'is_login';
  static const String kCartBox = "cart_box";
  static const String kFavBox = "fav_box";
}
