import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';

import '../../../../../core/constants/app_color.dart';

class SingleCustomerReviewCard extends StatelessWidget {
  const SingleCustomerReviewCard({super.key, required this.review});

  final CustomerReviewResModel review;

  @override
  Widget build(BuildContext context) {
    final rating = review.rating?.toInt() ?? 0;
    final reviewerName = review.user?.name?.trim().isNotEmpty == true
        ? review.user!.name!
        : 'Customer';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColor.text.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppNetworkImage(
                    imageUrl: review.user?.avatar,
                    fit: BoxFit.cover,
                    backgroundColor: AppColor.safe1,
                    icon: HugeIcons.strokeRoundedUserCircle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final active = index < rating;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == 4 ? 0 : 2,
                              ),
                              child: AppHugeIcon(
                                HugeIcons.strokeRoundedStar,
                                color: active
                                    ? AppColor.primary
                                    : AppColor.neutral1,
                                secondaryColor: active
                                    ? AppColor.primary.withValues(alpha: 0.18)
                                    : null,
                                size: 14,
                              ),
                            );
                          }),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.safe1.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo(review.createdAt),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ((review.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.description!.trim(),
              style: const TextStyle(
                color: AppColor.neutral3,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
