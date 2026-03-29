import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SplashShimmer extends StatelessWidget {
  const SplashShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0F1F), Color(0xFF0F1E2E), Color(0xFF0C2636)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: const Color(0xFF1F2A3A),
                highlightColor: const Color(0xFF2C3A4E),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16202F),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Shimmer.fromColors(
                baseColor: const Color(0xFF1F2A3A),
                highlightColor: const Color(0xFF2C3A4E),
                child: Container(
                  width: 200,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16202F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Shimmer.fromColors(
                baseColor: const Color(0xFF1F2A3A),
                highlightColor: const Color(0xFF2C3A4E),
                child: Container(
                  width: 140,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16202F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
