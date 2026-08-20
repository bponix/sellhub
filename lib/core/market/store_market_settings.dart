class StoreMarketSettings {
  const StoreMarketSettings({
    this.countryCode = 'BD',
    this.currencyCode = 'BDT',
    this.defaultLanguage = 'bn',
    this.languageCodes = const <String>['bn', 'en'],
    this.timezone = 'Asia/Dhaka',
    this.phoneCountryCode = '+880',
    this.phoneNationalPrefix = '0',
    this.phoneMinDigits = 10,
    this.phoneMaxDigits = 11,
    this.taxEnabled = false,
    this.taxLabel = 'VAT',
    this.defaultTaxRate = 0,
    this.pricesIncludeTax = false,
    this.logisticsZoneModel = 'domestic_lanes',
    this.localLaneLabel = 'Dhaka',
    this.remoteLaneLabel = 'Outside Dhaka',
    this.cashOnDeliveryEnabled = true,
    this.payoutMethods = const <String>['mobile_banking', 'bank_transfer'],
    this.defaultPayoutMethod = 'mobile_banking',
    this.source = 'mobile_fallback',
    this.appOverrideApplied = false,
  });

  final String countryCode;
  final String currencyCode;
  final String defaultLanguage;
  final List<String> languageCodes;
  final String timezone;
  final String phoneCountryCode;
  final String phoneNationalPrefix;
  final int phoneMinDigits;
  final int phoneMaxDigits;
  final bool taxEnabled;
  final String taxLabel;
  final double defaultTaxRate;
  final bool pricesIncludeTax;
  final String logisticsZoneModel;
  final String localLaneLabel;
  final String remoteLaneLabel;
  final bool cashOnDeliveryEnabled;
  final List<String> payoutMethods;
  final String defaultPayoutMethod;
  final String source;
  final bool appOverrideApplied;

  factory StoreMarketSettings.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key, List<String> fallback) {
      final value = json[key];
      if (value is! List) return fallback;
      final values = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      return values.isEmpty ? fallback : values;
    }

    return StoreMarketSettings(
      countryCode: json['countryCode'] as String? ?? 'BD',
      currencyCode: json['currencyCode'] as String? ?? 'BDT',
      defaultLanguage: json['defaultLanguage'] as String? ?? 'bn',
      languageCodes: strings('languageCodes', const <String>['bn', 'en']),
      timezone: json['timezone'] as String? ?? 'Asia/Dhaka',
      phoneCountryCode: json['phoneCountryCode'] as String? ?? '+880',
      phoneNationalPrefix: json['phoneNationalPrefix'] as String? ?? '0',
      phoneMinDigits: (json['phoneMinDigits'] as num?)?.toInt() ?? 10,
      phoneMaxDigits: (json['phoneMaxDigits'] as num?)?.toInt() ?? 11,
      taxEnabled: json['taxEnabled'] == true,
      taxLabel: json['taxLabel'] as String? ?? 'VAT',
      defaultTaxRate: (json['defaultTaxRate'] as num?)?.toDouble() ?? 0,
      pricesIncludeTax: json['pricesIncludeTax'] == true,
      logisticsZoneModel:
          json['logisticsZoneModel'] as String? ?? 'domestic_lanes',
      localLaneLabel: json['localLaneLabel'] as String? ?? 'Dhaka',
      remoteLaneLabel: json['remoteLaneLabel'] as String? ?? 'Outside Dhaka',
      cashOnDeliveryEnabled: json['cashOnDeliveryEnabled'] != false,
      payoutMethods: strings('payoutMethods', const <String>[
        'mobile_banking',
        'bank_transfer',
      ]),
      defaultPayoutMethod:
          json['defaultPayoutMethod'] as String? ?? 'mobile_banking',
      source: json['source'] as String? ?? 'platform_default',
      appOverrideApplied: json['appOverrideApplied'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'countryCode': countryCode,
    'currencyCode': currencyCode,
    'defaultLanguage': defaultLanguage,
    'languageCodes': languageCodes,
    'timezone': timezone,
    'phoneCountryCode': phoneCountryCode,
    'phoneNationalPrefix': phoneNationalPrefix,
    'phoneMinDigits': phoneMinDigits,
    'phoneMaxDigits': phoneMaxDigits,
    'taxEnabled': taxEnabled,
    'taxLabel': taxLabel,
    'defaultTaxRate': defaultTaxRate,
    'pricesIncludeTax': pricesIncludeTax,
    'logisticsZoneModel': logisticsZoneModel,
    'localLaneLabel': localLaneLabel,
    'remoteLaneLabel': remoteLaneLabel,
    'cashOnDeliveryEnabled': cashOnDeliveryEnabled,
    'payoutMethods': payoutMethods,
    'defaultPayoutMethod': defaultPayoutMethod,
    'source': source,
    'appOverrideApplied': appOverrideApplied,
  };

  String normalizeNationalPhone(Object? input) {
    var digits = (input ?? '').toString().replaceAll(RegExp(r'\D'), '');
    final countryDigits = phoneCountryCode.replaceAll(RegExp(r'\D'), '');
    final prefixDigits = phoneNationalPrefix.replaceAll(RegExp(r'\D'), '');
    if (countryDigits.isNotEmpty && digits.startsWith(countryDigits)) {
      digits = digits.substring(countryDigits.length);
    }
    if (prefixDigits.isNotEmpty && !digits.startsWith(prefixDigits)) {
      digits = '$prefixDigits$digits';
    }
    return digits;
  }

  bool isPhoneValid(Object? input) {
    final length = normalizeNationalPhone(input).length;
    return length >= phoneMinDigits && length <= phoneMaxDigits;
  }

  String normalizeInternationalPhone(Object? input) {
    final national = normalizeNationalPhone(input);
    final prefixDigits = phoneNationalPrefix.replaceAll(RegExp(r'\D'), '');
    final subscriber =
        prefixDigits.isNotEmpty && national.startsWith(prefixDigits)
        ? national.substring(prefixDigits.length)
        : national;
    return '$phoneCountryCode$subscriber';
  }

  String deliveryLaneLabel({required bool local}) =>
      local ? localLaneLabel : remoteLaneLabel;

  double taxFor(double subtotal) {
    if (!taxEnabled || defaultTaxRate <= 0) return 0;
    final rate = defaultTaxRate / 100;
    return pricesIncludeTax
        ? subtotal - subtotal / (1 + rate)
        : subtotal * rate;
  }
}
