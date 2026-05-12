import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

Future<int?> showResellerPriceSheet(
  BuildContext context, {
  required ProductResCommon product,
  int? initialPrice,
}) {
  final basePrice = product.price?.round() ?? 0;
  final minSellPrice =
      ((product.minResellPrice ?? product.maxResellPrice ?? product.price ?? 0))
          .round()
          .clamp(basePrice, 1 << 31);
  final maxSellPrice =
      ((product.maxResellPrice ?? product.minResellPrice ?? product.price ?? 0))
          .round()
          .clamp(minSellPrice, 1 << 31);
  final recommended = maxSellPrice > minSellPrice
      ? ((minSellPrice + maxSellPrice) / 2).round()
      : maxSellPrice;
  final controller = TextEditingController(
    text: (initialPrice ?? recommended).toString(),
  );

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final current =
              int.tryParse(controller.text.trim())?.clamp(minSellPrice, maxSellPrice) ??
              recommended;
          final profit = current - basePrice;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColor.safe,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set selling price',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.translation ?? product.title ?? 'Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PricePill(
                        label: 'Base',
                        value: '৳${convertToBengaliNumber(basePrice)}',
                        tone: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PricePill(
                        label: 'Range',
                        value:
                            '৳${convertToBengaliNumber(minSellPrice)}-${convertToBengaliNumber(maxSellPrice)}',
                        tone: AppColor.safe1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PresetButton(
                        label: 'Safe',
                        value: minSellPrice,
                        onTap: () {
                          controller.text = '$minSellPrice';
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PresetButton(
                        label: 'Recommended',
                        value: recommended,
                        onTap: () {
                          controller.text = '$recommended';
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PresetButton(
                        label: 'Premium',
                        value: maxSellPrice,
                        onTap: () {
                          controller.text = '$maxSellPrice';
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Buyer price',
                    prefixText: '৳ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PricePill(
                          label: 'Profit',
                          value: '৳${convertToBengaliNumber(profit)}',
                          tone: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PricePill(
                          label: 'Order',
                          value: 'Editable later',
                          tone: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDFF55A),
                      foregroundColor: AppColor.text,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      final parsed = int.tryParse(controller.text.trim());
                      if (parsed == null) return;
                      Navigator.of(context).pop(
                        parsed.clamp(minSellPrice, maxSellPrice),
                      );
                    },
                    child: const Text('Add to list'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '৳${convertToBengaliNumber(value)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
