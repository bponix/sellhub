class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = 'https://api.bponi.com/x';
  static const String appUpdateAppKey = 'sellhub';
  static const bool firebaseEnabled = false;
  static const List<String> appLinkHosts = <String>[
    'sellhub.bponi.com',
    'bponi.com',
    'www.bponi.com',
  ];
  static const String appLinkScheme = 'sellhub';
  static const String mediaBaseUrl =
      'https://bponi.sgp1.cdn.digitaloceanspaces.com/bponi/';
}
