import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';

class CarousalSliderHomePage extends StatefulWidget {
  const CarousalSliderHomePage({super.key, required this.items});

  final List<SiteSliderRes> items;

  @override
  State<CarousalSliderHomePage> createState() => _CarousalSliderHomePageState();
}

class _CarousalSliderHomePageState extends State<CarousalSliderHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      children: [
        CarouselSlider(
          items: items.asMap().entries.map((entry) {
            final index = entry.key;
            final sliderItem = entry.value;
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColor.safe),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: sliderItem.cover ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColor.safe1,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColor.safe1,
                        alignment: Alignment.center,
                        child: const AppHugeIcon(
                          HugeIcons.strokeRoundedImageNotFound02,
                          color: AppColor.neutral1,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppHugeIcon(
                              HugeIcons.strokeRoundedSparkles,
                              size: 13,
                              color: AppColor.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Featured',
                              style: TextStyle(
                                color: AppColor.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          '${index + 1}/${items.length}',
                          style: const TextStyle(
                            color: AppColor.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 176,
            aspectRatio: 16 / 9,
            viewportFraction: 0.96,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
            scrollDirection: Axis.horizontal,
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColor.safe),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length > 6 ? 6 : items.length, (
                    index,
                  ) {
                    final activeIndex = items.length > 6
                        ? _currentIndex % 6
                        : _currentIndex;
                    final selected = index == activeIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: index == 5 ? 0 : 6),
                      width: selected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected ? AppColor.primary : AppColor.safe,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                if (items.length > 6) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_currentIndex + 1}/${items.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
