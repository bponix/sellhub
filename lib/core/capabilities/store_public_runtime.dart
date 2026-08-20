import 'package:equatable/equatable.dart';
import 'package:sellhub/core/market/store_market_settings.dart';

class StorePublicRuntime extends Equatable {
  const StorePublicRuntime({
    required this.ready,
    required this.code,
    required this.message,
    required this.action,
    required this.retryable,
    this.siteTitle,
    this.market = const StoreMarketSettings(),
  });

  final bool ready;
  final String code;
  final String message;
  final String action;
  final bool retryable;
  final String? siteTitle;
  final StoreMarketSettings market;

  factory StorePublicRuntime.fromJson(Map<String, dynamic> json) {
    return StorePublicRuntime(
      ready: json['ready'] == true,
      code: json['code'] as String? ?? 'RUNTIME_UNAVAILABLE',
      message: json['message'] as String? ?? 'SellHub supply is unavailable.',
      action: json['action'] as String? ?? 'Choose another store',
      retryable: json['retryable'] == true,
      siteTitle: json['siteTitle'] as String?,
      market: json['market'] is Map<String, dynamic>
          ? StoreMarketSettings.fromJson(json['market'] as Map<String, dynamic>)
          : const StoreMarketSettings(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    ready,
    code,
    retryable,
    market.countryCode,
    market.currencyCode,
    market.source,
  ];
}
