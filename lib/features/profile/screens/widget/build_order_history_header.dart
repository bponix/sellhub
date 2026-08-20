import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/widget/app_huge_icon.dart';

class buildHeaderOrderHistoryTable extends StatelessWidget {
  const buildHeaderOrderHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe, width: 1),
      ),
      child: Row(
        children: [
          const AppHugeIcon(
            HugeIcons.strokeRoundedInvoice03,
            size: 16,
            color: AppColor.primary,
          ),
          const SizedBox(width: 10),
          _buildHeaderCell(text: 'SL', width: 40, alignment: Alignment.center),
          _buildHeaderCell(text: 'Order Info', width: 140),
          _buildHeaderCell(
            text: 'Status',
            width: 120,
            alignment: Alignment.center,
          ),
          _buildHeaderCell(text: 'Update', width: 160),
          _buildHeaderCell(text: 'Customer', width: 180),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 42),
            child: Text(
              'Action',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColor.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell({
    required String text,
    required double width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColor.text,
        ),
      ),
    );
  }
}
