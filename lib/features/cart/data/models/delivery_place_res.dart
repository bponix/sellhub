class DeliveryPlaceRes {
  DeliveryPlaceRes({
    required this.balance,
    required this.chargeBase,
    required this.chargeMerchantDefined,
    required this.codSupportLabel,
    required this.confidenceLabel,
    required this.confidenceScore,
    required this.deliveryEtaLabel,
    required this.discount,
    required this.id,
    required this.note,
    required this.isActive,
    required this.logisticsAddress,
    required this.logisticsTitle,
    required this.riskNote,
    required this.recommendedAction,
    required this.companyId,
    required this.company,
    required this.title,
    required this.updatedAt,
    required this.zoneLabel,
  });

  final double? balance;
  final int? chargeBase;
  final double? chargeMerchantDefined;
  final String? codSupportLabel;
  final String? confidenceLabel;
  final int? confidenceScore;
  final String? deliveryEtaLabel;
  final double? discount;
  final int? id;
  final String? note;
  final bool? isActive;
  final String? logisticsAddress;
  final String? logisticsTitle;
  final String? riskNote;
  final String? recommendedAction;
  final int? companyId;
  final Company? company;
  final String? title;
  final DateTime? updatedAt;
  final String? zoneLabel;

  factory DeliveryPlaceRes.fromJson(Map<String, dynamic> json) {
    return DeliveryPlaceRes(
      balance: json["balance"],
      chargeBase: json["chargeBase"],
      chargeMerchantDefined: json["chargeMerchantDefined"],
      codSupportLabel: json["codSupportLabel"],
      confidenceLabel: json["confidenceLabel"],
      confidenceScore: json["confidenceScore"],
      deliveryEtaLabel: json["deliveryEtaLabel"],
      discount: json["discount"],
      id: json["id"],
      note: json["note"],
      isActive: json["isActive"],
      logisticsAddress: json["logisticsAddress"],
      logisticsTitle: json["logisticsTitle"],
      riskNote: json["riskNote"],
      recommendedAction: json["recommendedAction"],
      companyId: json["companyId"],
      company: json["company"] == null
          ? null
          : Company.fromJson(json["company"]),
      title: json["title"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      zoneLabel: json["zoneLabel"],
    );
  }
}

class Company {
  Company({
    required this.domain,
    required this.id,
    required this.logo,
    required this.street,
    required this.phone,
  });

  final String? domain;
  final int? id;
  final String? logo;
  final String? street;
  final int? phone;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      domain: json["domain"],
      id: json["id"],
      logo: json["logo"],
      street: json["street"],
      phone: json["phone"],
    );
  }
}
