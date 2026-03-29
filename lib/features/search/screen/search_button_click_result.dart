import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';

import '../../../core/config/id_encoder.dart';
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
  State<SearchButtonClickResult> createState() => _SearchButtonClickResultState();
}

class _SearchButtonClickResultState extends State<SearchButtonClickResult> {
  int? _lastSiteId;

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
        subtitle: 'Search results',
        icon: HugeIcons.strokeRoundedSearch01,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _ResultHero(query: widget.query),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
            if (state.loading && state.searchProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.searchProducts.isEmpty) {
              return _SearchResultState(
                icon: HugeIcons.strokeRoundedAlertCircle,
                title: state.error!.title,
                subtitle: 'Try another search or pull to refresh.',
                actionLabel: 'Retry',
                onAction: _refresh,
              );
            }
            if (state.searchProducts.isEmpty) {
              return const _SearchResultState(
                icon: HugeIcons.strokeRoundedPackageSearch01,
                title: 'Search result not found',
                subtitle: 'No products matched this query in the current store.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                itemCount: state.searchProducts.length + 1,
                separatorBuilder: (_, index) => SizedBox(
                  height: index == 0 ? 12 : 10,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Row(
                      children: [
                        _StatPill(
                          icon: HugeIcons.strokeRoundedPackageSearch01,
                          label: '${state.searchProducts.length} found',
                        ),
                        const SizedBox(width: 8),
                        const _StatPill(
                          icon: HugeIcons.strokeRoundedStore01,
                          label: 'Current store',
                        ),
                      ],
                    );
                  }

                  final item = state.searchProducts[index - 1];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == state.searchProducts.length ? 0 : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        final hid = encodeId(item.id!);
                        Navigator.of(context).push(
                          ProductDetailsScreen.route(hid: hid, product: item),
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
                                  imageUrl: item.thumbnail ?? item.images.firstOrNull?.image,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColor.safe1,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'View',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColor.primary,
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
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedSearchVisual,
              size: 20,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full search',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  query.isEmpty ? 'Store catalog results' : query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All matched products from the current store catalog',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(icon, size: 14, color: AppColor.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutral2,
                ),
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
