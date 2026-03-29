class DeliveryPlaceRes {
  DeliveryPlaceRes({
    required this.balance,
    required this.chargeBase,
    required this.chargeMerchantDefined,
    required this.discount,
    required this.id,
    required this.note,
    required this.isActive,
    required this.logisticsAddress,
    required this.logisticsTitle,
    required this.companyId,
    required this.company,
    required this.title,
    required this.updatedAt,
  });

  final double? balance;
  final int? chargeBase;
  final double? chargeMerchantDefined;
  final double? discount;
  final int? id;
  final String? note;
  final bool? isActive;
  final String? logisticsAddress;
  final String? logisticsTitle;
  final int? companyId;
  final Company? company;
  final String? title;
  final DateTime? updatedAt;

  factory DeliveryPlaceRes.fromJson(Map<String, dynamic> json) {
    return DeliveryPlaceRes(
      balance: json["balance"],
      chargeBase: json["chargeBase"],
      chargeMerchantDefined: json["chargeMerchantDefined"],
      discount: json["discount"],
      id: json["id"],
      note: json["note"],
      isActive: json["isActive"],
      logisticsAddress: json["logisticsAddress"],
      logisticsTitle: json["logisticsTitle"],
      companyId: json["companyId"],
      company: json["company"] == null
          ? null
          : Company.fromJson(json["company"]),
      title: json["title"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
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
