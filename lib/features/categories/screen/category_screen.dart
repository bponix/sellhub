import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/app_skeleton.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_state.dart';
import 'package:sellhub/features/categories/screen/sub_category_products_screen.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _selectedIndex = 0;
  int? _lastSiteId;

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: BlocBuilder<StorefrontCubit, StorefrontState>(
        builder: (context, storefrontState) {
          final siteId = StoreScope.siteIdFromState(storefrontState);
          if (_lastSiteId != siteId) {
            _lastSiteId = siteId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedIndex = 0;
              });
              context.read<CategoriesCubit>().reset();
              context.read<CategoriesCubit>().fetchSubCategory(siteId);
              context.read<CategoriesCubit>().fetchSubSubCategory(siteId);
            });
          }
          return BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, categoriesState) {
              final categories = storefrontState.allCategory;
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find by category or selling lane',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.safe1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.safe),
                      ),
                      child: Text(
                        'Choose a category first, then switch to a Bangladesh seller lens like student budget, repeat buy, margin, or COD safer inside the catalog.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final categoryItem = categories[index];
                            final title =
                                categoryItem.translation ??
                                categoryItem.title ??
                                '';
                            final imageUrl =
                                categoryItem.image ?? categoryItem.cover ?? '';
                            final initial = title.isNotEmpty
                                ? String.fromCharCode(
                                    title.runes.first,
                                  ).toUpperCase()
                                : '';
                            final selected = _selectedIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                                context
                                    .read<CategoriesCubit>()
                                    .setCategoryIndex(index, categoryItem);
                              },
                              child: Container(
                                width: 82,
                                margin: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? AppColor.primary
                                              : AppColor.safe,
                                          width: selected ? 1.5 : 1,
                                        ),
                                        boxShadow: selected
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x121B7B7C),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: AppNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                backgroundColor: selected
                                                    ? Colors.white
                                                    : Colors.white,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initial,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: selected
                                                      ? AppColor.primary
                                                      : AppColor.text,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: selected
                                                ? AppColor.primary
                                                : AppColor.text,
                                            fontWeight: selected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 10.4,
                                            height: 1.1,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: selected ? 16 : 6,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColor.primary
                                            : AppColor.safe,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final items = categoriesState.filteredSubCategory;

                          if (categoriesState.error != null && items.isEmpty) {
                            return _CategoryStateCard(
                              icon: HugeIcons.strokeRoundedAlertCircle,
                              title: categoriesState.error!.title,
                              onRetry: () => context
                                  .read<CategoriesCubit>()
                                  .fetchSubCategory(siteId),
                            );
                          }

                          if (categoriesState.isLoading && items.isEmpty) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount =
                                    constraints.maxWidth >= 430 ? 4 : 3;
                                final childAspectRatio = crossAxisCount == 4
                                    ? 0.76
                                    : 0.84;
                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 9,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: childAspectRatio,
                                      ),
                                  itemBuilder: (_, __) => const AppSkeletonCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppSkeleton(height: 92, radius: 18),
                                        Spacer(),
                                        AppSkeleton(
                                          width: 62,
                                          height: 20,
                                          radius: 999,
                                        ),
                                        SizedBox(height: 8),
                                        AppSkeleton(height: 28, radius: 10),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          if (items.isEmpty) {
                            return const _CategoryStateCard(
                              icon: HugeIcons.strokeRoundedPackageSearch01,
                              title: 'No items',
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<CategoriesCubit>().reset();
                              await context
                                  .read<CategoriesCubit>()
                                  .fetchSubCategory(siteId);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Subcategories',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<CategoriesCubit>()
                                            .fetchCategoriesAllProduct(
                                              siteId,
                                              16,
                                              categoriesState
                                                      .selectCategory
                                                      ?.id ??
                                                  0,
                                              0,
                                            );

                                        Navigator.of(context).push(
                                          _fadeRoute(
                                            SubCategoryProductsScreen(
                                              subCategoryId: -1,
                                              title:
                                                  categoriesState
                                                      .selectCategory
                                                      ?.translation ??
                                                  categoriesState
                                                      .selectCategory
                                                      ?.title ??
                                                  'Browse',
                                              seeAll: true,
                                              categoryId:
                                                  categoriesState
                                                      .selectCategory
                                                      ?.id ??
                                                  0,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('See all'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final crossAxisCount =
                                          constraints.maxWidth >= 430 ? 4 : 3;
                                      final childAspectRatio =
                                          crossAxisCount == 4 ? 0.8 : 0.9;
                                      return GridView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossAxisCount,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                              childAspectRatio:
                                                  childAspectRatio,
                                            ),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          final sub = items[index];
                                          return GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<CategoriesCubit>()
                                                  .fetchSubCategoriesProduct(
                                                    siteId,
                                                    16,
                                                    sub.id ?? 0,
                                                    0,
                                                  );

                                              Navigator.of(context).push(
                                                _fadeRoute(
                                                  SubCategoryProductsScreen(
                                                    subCategoryId: sub.id ?? 0,
                                                    title: sub.title ?? '',
                                                    seeAll: false,
                                                    categoryId: -1,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: _CategoryGridCard(
                                              imageUrl: sub.image ?? '',
                                              title:
                                                  sub.translation ??
                                                  sub.title ??
                                                  '',
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 140;
        final iconSize = compact ? 54.0 : 58.0;
        final titleTopGap = compact ? 6.0 : 7.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColor.safe, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        backgroundColor: Colors.white,
                        icon: HugeIcons.strokeRoundedGridView,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: titleTopGap),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 10.1 : 10.6,
                      fontWeight: FontWeight.w700,
                      color: AppColor.text,
                      height: compact ? 1.05 : 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryStateCard extends StatelessWidget {
  const _CategoryStateCard({
    required this.icon,
    required this.title,
    this.onRetry,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHugeIcon(icon, size: 36, color: AppColor.neutral2),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
