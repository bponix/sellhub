import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/product_viability/product_viability_widgets.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';

import '../../../core/config/id_encoder.dart';
import '../../product/data/models/product_res_common.dart';
import '../../product/screens/product_details_screen.dart';
import '../presentation/cubit/search_cubit.dart';
import '../presentation/cubit/search_state.dart';

class SearchButtonClickResult extends StatefulWidget {
  const SearchButtonClickResult({
    super.key,
    required this.query,
    required this.siteId,
  });

  final String query;
  final int siteId;

  @override
  State<SearchButtonClickResult> createState() =>
      _SearchButtonClickResultState();
}

class _SearchButtonClickResultState extends State<SearchButtonClickResult> {
  int? _lastSiteId;
  ProductViabilityFilter _viabilityFilter = ProductViabilityFilter.all;
  ProductViabilitySort _viabilitySort = ProductViabilitySort.featured;

  void _applySellerLens(String lens) {
    switch (lens) {
      case 'whatsapp':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.goodMargin;
          _viabilitySort = ProductViabilitySort.featured;
        });
        break;
      case 'facebook':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.highRepeatPotential;
          _viabilitySort = ProductViabilitySort.featured;
        });
        break;
      case 'margin':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.goodMargin;
          _viabilitySort = ProductViabilitySort.highestMargin;
        });
        break;
      case 'risk':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.beginnerFriendly;
          _viabilitySort = ProductViabilitySort.lowestRisk;
        });
        break;
      case 'cod':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.beginnerFriendly;
          _viabilitySort = ProductViabilitySort.featured;
        });
        break;
      case 'repeat':
        setState(() {
          _viabilityFilter = ProductViabilityFilter.highRepeatPotential;
          _viabilitySort = ProductViabilitySort.highRepeatPotential;
        });
        break;
      default:
        setState(() {
          _viabilityFilter = ProductViabilityFilter.all;
          _viabilitySort = ProductViabilitySort.featured;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() {
    final activeSiteId =
        context.read<StoreContextCubit>().state.activeStore?.siteId ??
        AppConstants.kDefaultSiteId;
    return context.read<SearchCubit>().searchProductsByButtonClick(
      widget.query,
      activeSiteId,
      16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSiteId =
        context.read<StoreContextCubit>().state.activeStore?.siteId ??
        AppConstants.kDefaultSiteId;
    if (_lastSiteId != activeSiteId) {
      _lastSiteId = activeSiteId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SearchCubit>().ensureSite(activeSiteId);
        _refresh();
      });
    }
    return Scaffold(
      appBar: SellHubTopAppBar(
        title: widget.query.isEmpty ? 'Results' : widget.query,
        subtitle: 'Find products to sell',
        icon: HugeIcons.strokeRoundedSearch01,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  final visibleProducts = applyProductViability(
                    state.searchProducts,
                    filter: _viabilityFilter,
                    sort: _viabilitySort,
                  );
                  if (state.loading && state.searchProducts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null && state.searchProducts.isEmpty) {
                    return _SearchResultState(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      title: state.error!.title,
                      subtitle: 'Try another keyword or pull to refresh.',
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    );
                  }
                  if (state.searchProducts.isEmpty) {
                    return const _SearchResultState(
                      icon: HugeIcons.strokeRoundedPackageSearch01,
                      title: 'No products found',
                      subtitle:
                          'No products matched this query across active suppliers.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      itemCount: visibleProducts.length + 1,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: index == 0 ? 12 : 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${visibleProducts.length} matches',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColor.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  PopupMenuButton<ProductViabilitySort>(
                                    onSelected: (value) {
                                      setState(() {
                                        _viabilitySort = value;
                                      });
                                    },
                                    itemBuilder: (context) =>
                                        ProductViabilitySort.values
                                            .map(
                                              (sort) => PopupMenuItem(
                                                value: sort,
                                                child: Text(sort.name),
                                              ),
                                            )
                                            .toList(growable: false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.safe1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _viabilitySort.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColor.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _SellerLensSummaryCard(
                                filter: _viabilityFilter,
                                sort: _viabilitySort,
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _SellerLensChip(
                                      label: 'All',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter.all &&
                                          _viabilitySort ==
                                              ProductViabilitySort.featured,
                                      onTap: () => _applySellerLens('all'),
                                    ),
                                    _SellerLensChip(
                                      label: 'WhatsApp',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .goodMargin &&
                                          _viabilitySort ==
                                              ProductViabilitySort.featured,
                                      onTap: () => _applySellerLens('whatsapp'),
                                    ),
                                    _SellerLensChip(
                                      label: 'Facebook',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .highRepeatPotential &&
                                          _viabilitySort ==
                                              ProductViabilitySort.featured,
                                      onTap: () => _applySellerLens('facebook'),
                                    ),
                                    _SellerLensChip(
                                      label: 'Good margin',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .goodMargin &&
                                          _viabilitySort ==
                                              ProductViabilitySort
                                                  .highestMargin,
                                      onTap: () => _applySellerLens('margin'),
                                    ),
                                    _SellerLensChip(
                                      label: 'Low risk',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .beginnerFriendly &&
                                          _viabilitySort ==
                                              ProductViabilitySort.lowestRisk,
                                      onTap: () => _applySellerLens('risk'),
                                    ),
                                    _SellerLensChip(
                                      label: 'COD-friendly',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .beginnerFriendly &&
                                          _viabilitySort ==
                                              ProductViabilitySort.featured,
                                      onTap: () => _applySellerLens('cod'),
                                    ),
                                    _SellerLensChip(
                                      label: 'Repeat sell',
                                      selected:
                                          _viabilityFilter ==
                                              ProductViabilityFilter
                                                  .highRepeatPotential &&
                                          _viabilitySort ==
                                              ProductViabilitySort
                                                  .highRepeatPotential,
                                      onTap: () => _applySellerLens('repeat'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        final item = visibleProducts[index - 1];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == state.searchProducts.length
                                ? 0
                                : 0,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              final hid = encodeId(item.id!);
                              Navigator.of(context).push(
                                ProductDetailsScreen.route(
                                  hid: hid,
                                  product: item,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColor.safe),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColor.safe1,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AppNetworkImage(
                                        imageUrl:
                                            item.thumbnail ??
                                            item.images.firstOrNull?.image,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        backgroundColor: AppColor.safe1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColor.text,
                                                fontWeight: FontWeight.w700,
                                                height: 1.25,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '৳ ${item.price}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColor.text,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _activeCueLabel(item),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColor.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ProductViabilityCompactBlock(
                                          product: item,
                                          maxLabels: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColor.primarySoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const AppHugeIcon(
                                      HugeIcons.strokeRoundedArrowRight02,
                                      size: 14,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activeCueLabel(ProductResCommon item) {
    if (_viabilityFilter == ProductViabilityFilter.goodMargin &&
        _viabilitySort == ProductViabilitySort.featured) {
      return 'WhatsApp';
    }
    if (_viabilityFilter == ProductViabilityFilter.highRepeatPotential &&
        _viabilitySort == ProductViabilitySort.featured) {
      return 'Facebook';
    }
    if (_viabilityFilter == ProductViabilityFilter.beginnerFriendly &&
        _viabilitySort == ProductViabilitySort.featured) {
      return 'COD';
    }
    if (_viabilityFilter == ProductViabilityFilter.beginnerFriendly &&
        _viabilitySort == ProductViabilitySort.lowestRisk) {
      return 'Low risk';
    }
    if (_viabilityFilter == ProductViabilityFilter.highRepeatPotential &&
        _viabilitySort == ProductViabilitySort.highRepeatPotential) {
      return 'Repeat';
    }
    final viability = ProductViabilityEngine.build(item);
    if (viability.labels.contains('Good margin') ||
        viability.maxMargin >= 180) {
      return 'Margin';
    }
    if (viability.labels.contains('High repeat potential')) {
      return 'Repeat';
    }
    if (viability.deliveryRisk != ViabilityRiskLevel.high &&
        viability.returnSensitivity != ViabilityRiskLevel.high) {
      return 'Low risk';
    }
    return 'Sell';
  }
}

class _SearchResultState extends StatelessWidget {
  const _SearchResultState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHugeIcon(icon, size: 40, color: AppColor.neutral2),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => onAction!.call(),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerLensChip extends StatelessWidget {
  const _SellerLensChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColor.safe1 : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.safe,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppColor.primary : AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerLensSummaryCard extends StatelessWidget {
  const _SellerLensSummaryCard({required this.filter, required this.sort});

  final ProductViabilityFilter filter;
  final ProductViabilitySort sort;

  String get _summary {
    if (filter == ProductViabilityFilter.goodMargin &&
        sort == ProductViabilitySort.highestMargin) {
      return 'Push higher-margin products when the buyer is warm and the supplier is trusted.';
    }
    if (filter == ProductViabilityFilter.beginnerFriendly &&
        sort == ProductViabilitySort.lowestRisk) {
      return 'Safer picks for COD and first-time resellers in Bangladesh.';
    }
    if (filter == ProductViabilityFilter.highRepeatPotential) {
      return 'These products are better for repeat-sell and neighborhood follow-up.';
    }
    return 'Use seller lenses to switch between WhatsApp, Facebook, COD, margin, and repeat-selling priorities.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        _summary,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColor.neutral2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
