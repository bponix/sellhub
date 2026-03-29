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
              final selectedCategory = categoriesState.selectCategory;
              final selectedTitle =
                  selectedCategory?.translation ??
                  selectedCategory?.title ??
                  'Browse';
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryHero(
                      title: selectedTitle,
                      categoryCount: categories.length,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColor.safe.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.safe.withValues(alpha: 0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 86,
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
                                context.read<CategoriesCubit>().setCategoryIndex(
                                  index,
                                  categoryItem,
                                );
                              },
                              child: Container(
                                width: 76,
                                margin: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
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
                                              borderRadius: BorderRadius.circular(14),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.labelSmall
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
                                      duration: const Duration(milliseconds: 180),
                                      width: selected ? 16 : 6,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColor.primary
                                            : AppColor.safe,
                                        borderRadius: BorderRadius.circular(999),
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
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 9,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.72,
                                  ),
                              itemBuilder: (_, __) => const AppSkeletonCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppSkeleton(height: 92, radius: 18),
                                    Spacer(),
                                    AppSkeleton(width: 62, height: 20, radius: 999),
                                    SizedBox(height: 8),
                                    AppSkeleton(height: 28, radius: 10),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (items.isEmpty) {
                            return const _CategoryStateCard(
                              icon: HugeIcons.strokeRoundedPackageSearch01,
                              title: 'No subcategories found',
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<CategoriesCubit>().reset();
                              await context.read<CategoriesCubit>().fetchSubCategory(
                                siteId,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _CategorySectionLead(
                                      title: 'Subcategories',
                                      subtitle: selectedTitle,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColor.safe1,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${items.length + 1} items',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: AppColor.neutral2,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: GridView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 0.76,
                                        ),
                                    itemCount: items.length + 1,
                                    itemBuilder: (context, index) {
                                        if (index == items.length) {
                                          return GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<CategoriesCubit>()
                                                  .fetchCategoriesAllProduct(
                                                    siteId,
                                                    16,
                                                    categoriesState.selectCategory?.id ?? 0,
                                                    0,
                                                  );

                                              Navigator.of(context).push(
                                                _fadeRoute(
                                                  SubCategoryProductsScreen(
                                                    subCategoryId: -1,
                                                    title: items[0].title ?? '',
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
                                            child: _CategoryGridCard(
                                              imageUrl:
                                                  categoriesState
                                                      .selectCategory
                                                      ?.image ??
                                                  'https://thumbs.dreamstime.com/b/more-d-word-increase-improve-larger-bigger-demand-letters-to-illustrate-desire-improved-results-growing-supply-36806749.jpg',
                                              title: 'See All',
                                              accent: true,
                                            ),
                                          );
                                        }

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
                                            title: sub.translation ?? sub.title ?? '',
                                          ),
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
  const _CategoryGridCard({
    required this.imageUrl,
    required this.title,
    this.accent = false,
  });

  final String imageUrl;
  final String title;
  final bool accent;

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
                      color: accent ? const Color(0xFFFFF6DD) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent ? AppColor.accent : AppColor.safe,
                        width: accent ? 1.4 : 1,
                      ),
                      boxShadow: accent
                          ? [
                              BoxShadow(
                                color: AppColor.accent.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
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
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent
                            ? AppColor.accent.withValues(alpha: 0.25)
                            : AppColor.safe.withValues(alpha: 0.7),
                      ),
                    ),
                    child: AppHugeIcon(
                      accent
                          ? HugeIcons.strokeRoundedArrowRight01
                          : HugeIcons.strokeRoundedArrowUpRight01,
                      size: 10,
                      color: accent ? AppColor.accent : AppColor.primary,
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
                      fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
                      color: accent ? AppColor.accent : AppColor.text,
                      height: compact ? 1.05 : 1.1,
                    ),
                  ),
                ),
              ),
              Container(
                width: accent ? 16 : 8,
                height: 2.5,
                decoration: BoxDecoration(
                  color: accent ? AppColor.accent : AppColor.safe,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({
    required this.title,
    required this.categoryCount,
  });

  final String title;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColor.safe.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6FADD),
                  Color(0xFFE8F2C9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedGridView,
              size: 18,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category flow',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColor.neutral2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
            ),
            child: Column(
              children: [
                Text(
                  '$categoryCount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySectionLead extends StatelessWidget {
  const _CategorySectionLead({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDF7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColor.safe.withValues(alpha: 0.85)),
          ),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
