import 'package:sellhub/features/cart/data/models/reseller_order_line_draft.dart';

class QuickOrderDraft {
  const QuickOrderDraft({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.title,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.note,
    required this.status,
    required this.deliveryLabel,
    required this.deliveryCharge,
    required this.subtotal,
    required this.total,
    required this.lines,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String title;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String note;
  final String status;
  final String deliveryLabel;
  final int deliveryCharge;
  final int subtotal;
  final int total;
  final List<ResellerOrderLineDraft> lines;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory QuickOrderDraft.fromJson(Map<String, dynamic> json) {
    return QuickOrderDraft(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Quick order',
      buyerName: (json['buyerName'] as String?) ?? 'Buyer',
      buyerPhone: (json['buyerPhone'] as String?) ?? '',
      buyerAddress: (json['buyerAddress'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'draft',
      deliveryLabel: (json['deliveryLabel'] as String?) ?? '',
      deliveryCharge: (json['deliveryCharge'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => ResellerOrderLineDraft.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'title': title,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'note': note,
      'status': status,
      'deliveryLabel': deliveryLabel,
      'deliveryCharge': deliveryCharge,
      'subtotal': subtotal,
      'total': total,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
