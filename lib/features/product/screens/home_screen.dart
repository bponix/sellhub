import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/app_skeleton.dart';
import 'package:sellhub/core/widget/carousal_slider.dart';
import 'package:sellhub/core/widget/search_widget.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_batch_entry.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/profile/data/model/repeat_sell_reminder.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:sellhub/features/categories/screen/sub_category_products_screen.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/screens/widget/allPartHomePage.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';
import 'package:sellhub/injection_container.dart' as di;

enum _HomeDiscoveryFocus {
  all,
  whatsapp,
  facebook,
  cod,
  lowRisk,
  goodMargin,
  repeat,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _pagePadding = 16;
  static const double _sectionGap = 18;
  static const double _blockGap = 12;
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _flashSaleController = ScrollController();
  final ScrollController _newArrivalController = ScrollController();
  _HomeDiscoveryFocus _discoveryFocus = _HomeDiscoveryFocus.all;
  Map<String, dynamic>? _onboardingProfile;
  bool _onboardingLoaded = false;

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
    _loadOnboardingProfile();
  }

  void _onScroll() {
    if (_mainScrollController.position.extentAfter < 200) {
      final storefront = context.read<StorefrontCubit>().state;
      final siteId = storefront.siteDetails?.id;
      if (siteId == null) return;
      if (!storefront.isFetchingMore && storefront.hasMorePopular) {
        context.read<StorefrontCubit>().loadMoreData(
          siteId,
          AppConstants.kDefaultFirst,
          storefront.categoryIndex == 0
              ? null
              : storefront.allCategory[storefront.categoryIndex - 1].id,
          false,
          false,
        );
      }
    }
  }

  Future<void> _loadOnboardingProfile() async {
    final profile = await LocalStorage.getResellerOnboardingProfile();
    if (!mounted) return;
    setState(() {
      _onboardingProfile = profile;
      _onboardingLoaded = true;
    });
  }

  String? _searchModeForFocus(_HomeDiscoveryFocus focus) {
    switch (focus) {
      case _HomeDiscoveryFocus.whatsapp:
        return 'whatsapp';
      case _HomeDiscoveryFocus.facebook:
        return 'facebook';
      case _HomeDiscoveryFocus.cod:
        return 'cod';
      case _HomeDiscoveryFocus.lowRisk:
        return 'low-risk';
      case _HomeDiscoveryFocus.goodMargin:
        return 'good-margin';
      case _HomeDiscoveryFocus.repeat:
        return 'repeat';
      case _HomeDiscoveryFocus.all:
        return null;
    }
  }

  String? _searchQueryForFocus(_HomeDiscoveryFocus focus) {
    switch (focus) {
      case _HomeDiscoveryFocus.whatsapp:
        return 'bundle';
      case _HomeDiscoveryFocus.facebook:
        return 'fashion';
      case _HomeDiscoveryFocus.cod:
        return 'home';
      case _HomeDiscoveryFocus.lowRisk:
        return 'daily';
      case _HomeDiscoveryFocus.goodMargin:
        return 'gift';
      case _HomeDiscoveryFocus.repeat:
        return 'beauty';
      case _HomeDiscoveryFocus.all:
        return null;
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _flashSaleController.dispose();
    _newArrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (context, storefrontState) {
        final siteId = storefrontState.siteDetails?.id;
        if (siteId != null &&
            storefrontState.allCategory.isNotEmpty &&
            storefrontState.homeCategoryProducts.isEmpty &&
            !storefrontState.homeCategoryLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<StorefrontCubit>().ensureHomeCategorySections(
              siteId,
              AppConstants.kDefaultFirst,
              maxSections: storefrontState.allCategory.length,
            );
          });
        }

        final hasVisibleContent =
            storefrontState.siteSlider.isNotEmpty ||
            storefrontState.allCategory.isNotEmpty ||
            storefrontState.products.isNotEmpty ||
            storefrontState.flashSale.isNotEmpty ||
            storefrontState.newArrival.isNotEmpty ||
            storefrontState.topBrand.isNotEmpty;

        return RefreshIndicator(
          onRefresh: _refreshStorefront,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _pagePadding,
                    12,
                    _pagePadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      if (storefrontState.error != null &&
                          storefrontState.products.isEmpty &&
                          storefrontState.siteSlider.isEmpty)
                          _InlineHomeState(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          title: storefrontState.error!.title,
                          actionLabel: 'Retry',
                          onAction: _refreshStorefront,
                        ),
                      if (storefrontState.isLoading && !hasVisibleContent)
                        const _HomeSkeleton(),
                    ],
                  ),
                ),
              ),
              if (!(storefrontState.isLoading && !hasVisibleContent))
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchHeaderDelegate(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _pagePadding,
                        0,
                        _pagePadding,
                        _blockGap,
                      ),
                      child: SearchWidget(
                        onTap: () => AppRouter.pushSearchScreen(
                          context,
                          mode: _searchModeForFocus(_discoveryFocus),
                          query: _searchQueryForFocus(_discoveryFocus),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!(storefrontState.isLoading && !hasVisibleContent))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _pagePadding,
                    4,
                    _pagePadding,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (storefrontState.siteSlider.isNotEmpty) ...[
                          CarousalSliderHomePage(
                            items: storefrontState.siteSlider,
                          ),
                          const SizedBox(height: _sectionGap),
                        ],
                        if (storefrontState.allCategory.isNotEmpty) ...[
                          _TwoRowCategoryRail(
                            categories: storefrontState.allCategory,
                            onTap: (category, title) =>
                                _openCategory(category, title),
                          ),
                          const SizedBox(height: _sectionGap),
                        ],
                        _DiscoveryFocusStrip(
                          current: _discoveryFocus,
                          onChanged: (focus) {
                            if (_discoveryFocus == focus) return;
                            setState(() {
                              _discoveryFocus = focus;
                            });
                          },
                        ),
                        const SizedBox(height: _sectionGap),
                        _HomeOperatorSummaryCard(
                          focus: _discoveryFocus,
                          supplierName:
                              storefrontState.siteDetails?.title?.trim(),
                          storefrontState: storefrontState,
                        ),
                        const SizedBox(height: _sectionGap),
                        if (_onboardingLoaded && _requiresOnboardingSetup()) ...[
                          _ResellerOnboardingSetupCard(
                            categoryNames: storefrontState.allCategory
                                .map((category) => category.title?.trim() ?? '')
                                .where((title) => title.isNotEmpty)
                                .take(8)
                                .toList(growable: false),
                            initialProfile: _onboardingProfile,
                            onSaved: (profile) {
                              setState(() {
                                _onboardingProfile = profile;
                              });
                            },
                          ),
                          const SizedBox(height: _sectionGap),
                        ],
                        const _ResellerActionStrip(),
                        const SizedBox(height: _sectionGap),
                        const _RepeatReminderHomeCard(),
                        const SizedBox(height: _sectionGap),
                        if (!storefrontState.isLoading && !hasVisibleContent)
                          _InlineHomeState(
                            icon: HugeIcons.strokeRoundedPackageSearch01,
                            title: 'No products yet',
                            actionLabel: 'Refresh',
                            onAction: () async {
                              await _refreshStorefront();
                            },
                          )
                        else
                          AllPartHomePage(
                            flashSaleController: _flashSaleController,
                            newArrivalController: _newArrivalController,
                            storefrontState: storefrontState,
                            discoveryFocus: _discoveryFocus.name,
                          ),
                        if (storefrontState.isFetchingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshStorefront() async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    await context.read<StorefrontCubit>().preload(
      domain: activeStore?.domain ?? AppConstants.kDefaultDomain,
      siteId: activeStore?.siteId ?? AppConstants.kDefaultSiteId,
      first: AppConstants.kDefaultFirst,
      forceRefresh: true,
    );
  }

  void _openCategory(CategoriesRes data, String text) {
    final categoryId = data.id;
    if (categoryId == null) return;
    final categoriesCubit = context.read<CategoriesCubit>();
    categoriesCubit.setCategoryIndex(0, data);
    final siteId =
        data.siteId ??
        context.read<StoreContextCubit>().state.activeStore?.siteId ??
        AppConstants.kDefaultSiteId;
    categoriesCubit.fetchCategoriesAllProduct(
      siteId,
      AppConstants.kDefaultFirst,
      categoryId,
      0,
    );
    Navigator.of(context).push(
      _fadeRoute(
        SubCategoryProductsScreen(
          subCategoryId: -1,
          title: text,
          seeAll: true,
          categoryId: categoryId,
        ),
      ),
    );
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  bool _requiresOnboardingSetup() {
    final profile = _onboardingProfile;
    if (profile == null) return true;
    final resellerName = (profile['resellerName'] as String? ?? '').trim();
    final area = (profile['sellingArea'] as String? ?? '').trim();
    final payoutMethod = (profile['payoutMethod'] as String? ?? '').trim();
    final channels = ((profile['channels'] as List?) ?? const <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final preferredCategories =
        ((profile['preferredCategories'] as List?) ?? const <dynamic>[])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    return resellerName.isEmpty ||
        area.isEmpty ||
        payoutMethod.isEmpty ||
        channels.isEmpty ||
        preferredCategories.isEmpty;
  }
}

class _ResellerOnboardingSetupCard extends StatelessWidget {
  const _ResellerOnboardingSetupCard({
    required this.categoryNames,
    required this.initialProfile,
    required this.onSaved,
  });

  final List<String> categoryNames;
  final Map<String, dynamic>? initialProfile;
  final ValueChanged<Map<String, dynamic>> onSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.safe),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedUserStar01,
                  size: 18,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finish first-sale setup',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your area, payout method, selling channel, and preferred products so SellHub can guide the right reseller flow.',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _OnboardingSignalPill(label: '3 min setup'),
              _OnboardingSignalPill(label: 'Phone-first'),
              _OnboardingSignalPill(label: 'BD reseller flow'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final saved = await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => _ResellerOnboardingSheet(
                    initialProfile: initialProfile,
                    categoryNames: categoryNames,
                  ),
                );
                if (saved == null) return;
                onSaved(saved);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFF55A),
                foregroundColor: AppColor.text,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Complete setup',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResellerOnboardingSheet extends StatefulWidget {
  const _ResellerOnboardingSheet({
    required this.initialProfile,
    required this.categoryNames,
  });

  final Map<String, dynamic>? initialProfile;
  final List<String> categoryNames;

  @override
  State<_ResellerOnboardingSheet> createState() =>
      _ResellerOnboardingSheetState();
}

class _ResellerOnboardingSheetState extends State<_ResellerOnboardingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  String _payoutMethod = '';
  final Set<String> _channels = <String>{};
  final Set<String> _preferredCategories = <String>{};

  static const List<String> _channelOptions = <String>[
    'Facebook',
    'WhatsApp',
    'Messenger',
    'Neighbourhood',
  ];
  static const List<String> _payoutOptions = <String>[
    'bKash',
    'Nagad',
    'Rocket',
    'Bank transfer',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(
      text: (profile?['resellerName'] as String? ?? '').trim(),
    );
    _areaController = TextEditingController(
      text: (profile?['sellingArea'] as String? ?? '').trim(),
    );
    _payoutMethod = (profile?['payoutMethod'] as String? ?? '').trim();
    _channels.addAll(
      ((profile?['channels'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
    _preferredCategories.addAll(
      ((profile?['preferredCategories'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.safe,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start selling in 3 minutes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SellHub will use this setup to suggest better products, payout cues, and buyer flow for your reseller profile.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your reseller name',
                    hintText: 'Name used for buyer follow-up',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Primary selling area',
                    hintText: 'Dhaka, Narayanganj, Mirpur, Chattogram',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                      ? 'Area is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Payout method',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _payoutOptions
                      .map(
                        (option) => ChoiceChip(
                          label: Text(option),
                          selected: _payoutMethod == option,
                          onSelected: (_) {
                            setState(() {
                              _payoutMethod = option;
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selling channels',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _channelOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option),
                          selected: _channels.contains(option),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _channels.add(option);
                              } else {
                                _channels.remove(option);
                              }
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preferred categories',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (widget.categoryNames.isEmpty
                          ? const <String>[
                              'Fashion',
                              'Beauty',
                              'Home',
                              'Electronics',
                            ]
                          : widget.categoryNames)
                      .map(
                        (category) => FilterChip(
                          label: Text(category),
                          selected: _preferredCategories.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _preferredCategories.add(category);
                              } else {
                                _preferredCategories.remove(category);
                              }
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDFF55A),
                      foregroundColor: AppColor.text,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save reseller setup',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payoutMethod.isEmpty) return;
    if (_channels.isEmpty) return;
    if (_preferredCategories.isEmpty) return;
    final payload = <String, dynamic>{
      'resellerName': _nameController.text.trim(),
      'sellingArea': _areaController.text.trim(),
      'payoutMethod': _payoutMethod,
      'channels': _channels.toList(growable: false),
      'preferredCategories': _preferredCategories.toList(growable: false),
      'completedAt': DateTime.now().toIso8601String(),
    };
    await LocalStorage.saveResellerOnboardingProfile(payload);
    if (!mounted) return;
    Navigator.of(context).pop(payload);
  }
}

class _OnboardingSignalPill extends StatelessWidget {
  const _OnboardingSignalPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DiscoveryFocusStrip extends StatelessWidget {
  const _DiscoveryFocusStrip({
    required this.current,
    required this.onChanged,
  });

  final _HomeDiscoveryFocus current;
  final ValueChanged<_HomeDiscoveryFocus> onChanged;

  static const List<(_HomeDiscoveryFocus, String, List<List<dynamic>>)> _items = <
      (_HomeDiscoveryFocus, String, List<List<dynamic>>)>[
    (_HomeDiscoveryFocus.all, 'All', HugeIcons.strokeRoundedSparkles),
    (_HomeDiscoveryFocus.whatsapp, 'WhatsApp', HugeIcons.strokeRoundedWhatsapp),
    (_HomeDiscoveryFocus.facebook, 'Facebook', HugeIcons.strokeRoundedFacebook02),
    (_HomeDiscoveryFocus.cod, 'COD', HugeIcons.strokeRoundedDeliveryTruck01),
    (_HomeDiscoveryFocus.lowRisk, 'Low risk', HugeIcons.strokeRoundedShield01),
    (_HomeDiscoveryFocus.goodMargin, 'Good margin', HugeIcons.strokeRoundedWallet02),
    (_HomeDiscoveryFocus.repeat, 'Repeat buyers', HugeIcons.strokeRoundedReload),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s selling mode',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick one lens and keep the feed focused.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DiscoveryFocusChip(
                      label: item.$2,
                      icon: item.$3,
                      selected: current == item.$1,
                      onTap: () => onChanged(item.$1),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryFocusChip extends StatelessWidget {
  const _DiscoveryFocusChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColor.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColor.primary : AppColor.safe,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(
              icon,
              size: 14,
              color: selected ? AppColor.primary : AppColor.neutral2,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppColor.primary : AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeOperatorSummaryCard extends StatelessWidget {
  const _HomeOperatorSummaryCard({
    required this.focus,
    required this.storefrontState,
    this.supplierName,
  });

  final _HomeDiscoveryFocus focus;
  final StorefrontState storefrontState;
  final String? supplierName;

  Future<_HomeDashboardMetrics> _loadDashboardMetrics(
    FavouriteState favourites,
  ) async {
    final siteId = storefrontState.siteDetails?.id ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    final customerId = await LocalStorage.getCustomerID() ?? 0;
    final repo = di.sl<ProfileRepository>();
    final reminders = await LocalStorage.getRepeatSellReminders();

    final orders = siteId > 0 && customerId > 0
        ? await repo.fetchOrderHistory(siteId, customerId)
        : const <OrderHistoryResModelProfile>[];
    final batches = siteId > 0 && userId > 0
        ? await repo.fetchPayoutBatches(userId: userId, siteId: siteId)
        : const <PayoutBatchEntry>[];

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final activeOrders = orders.where((order) {
      final status = order.status ?? 0;
      return status < 10 && status != 7 && status != 8 && status != 9;
    }).length;

    final confirmedToday = orders
        .where((order) {
          final status = order.status ?? 0;
          final updatedAt = order.updatedAt ?? order.createdAt;
          return status >= 2 &&
              updatedAt != null &&
              !updatedAt.isBefore(dayStart) &&
              updatedAt.isBefore(dayEnd);
        })
        .map((order) => '${order.customerPhone ?? ''}:${order.customerName ?? ''}')
        .where((value) => value.trim() != ':')
        .toSet()
        .length;

    final expectedBatchPayout = batches
        .where(
          (batch) => switch (batch.status.trim().toLowerCase()) {
            'processing' || 'scheduled' || 'released' => true,
            _ => false,
          },
        )
        .fold<double>(0, (sum, batch) => sum + batch.netAmount);

    final expectedDeliveredPayout = orders
        .where((order) => (order.status ?? 0) >= 10 && order.isSettle != true)
        .fold<double>(0, (sum, order) => sum + (order.profit ?? 0));

    final topSavedProduct = favourites.items.isEmpty
        ? 'None yet'
        : ((favourites.items.first.title ?? '').trim().isNotEmpty
              ? favourites.items.first.title!.trim()
              : 'Saved pick');

    final duePrompts = reminders.where((item) => item.isDue).length;
    final openPrompts = reminders
        .where((item) => item.status.trim().toLowerCase() == 'open')
        .length;

    return _HomeDashboardMetrics(
      activeOrders: activeOrders,
      confirmedBuyersToday: confirmedToday,
      expectedPayout:
          expectedBatchPayout > 0 ? expectedBatchPayout : expectedDeliveredPayout,
      topSavedProduct: topSavedProduct,
      dueRepeatPrompts: duePrompts,
      openRepeatPrompts: openPrompts,
    );
  }

  String get _focusLabel {
    switch (focus) {
      case _HomeDiscoveryFocus.whatsapp:
        return 'WhatsApp quick sell';
      case _HomeDiscoveryFocus.facebook:
        return 'Facebook post-ready';
      case _HomeDiscoveryFocus.cod:
        return 'COD-safe';
      case _HomeDiscoveryFocus.lowRisk:
        return 'Lower risk';
      case _HomeDiscoveryFocus.goodMargin:
        return 'Better margin';
      case _HomeDiscoveryFocus.repeat:
        return 'Repeat buyers';
      case _HomeDiscoveryFocus.all:
        return 'All products';
    }
  }

  String get _focusNote {
    switch (focus) {
      case _HomeDiscoveryFocus.whatsapp:
        return 'Use fast-close products and quick quote replies.';
      case _HomeDiscoveryFocus.facebook:
        return 'Keep image-led products and caption-friendly picks up front.';
      case _HomeDiscoveryFocus.cod:
        return 'Prioritize safer fulfilment and easier delivery promises.';
      case _HomeDiscoveryFocus.lowRisk:
        return 'Lower-risk products reduce buyer hesitation and return pressure.';
      case _HomeDiscoveryFocus.goodMargin:
        return 'Protect profit first, then share to buyers.';
      case _HomeDiscoveryFocus.repeat:
        return 'Start with products buyers can reorder easily.';
      case _HomeDiscoveryFocus.all:
        return 'Browse broadly, then narrow to one selling angle.';
    }
  }

  int get _queueReadyCount {
    switch (focus) {
      case _HomeDiscoveryFocus.whatsapp:
        return applyProductViability(
          storefrontState.products,
          filter: ProductViabilityFilter.goodMargin,
          sort: ProductViabilitySort.highestMargin,
        ).length;
      case _HomeDiscoveryFocus.cod:
      case _HomeDiscoveryFocus.lowRisk:
        return applyProductViability(
          storefrontState.products,
          filter: ProductViabilityFilter.beginnerFriendly,
          sort: ProductViabilitySort.lowestRisk,
        ).length;
      case _HomeDiscoveryFocus.repeat:
        return applyProductViability(
          storefrontState.products,
          filter: ProductViabilityFilter.highRepeatPotential,
          sort: ProductViabilitySort.highRepeatPotential,
        ).length;
      case _HomeDiscoveryFocus.facebook:
      case _HomeDiscoveryFocus.goodMargin:
      case _HomeDiscoveryFocus.all:
        return storefrontState.flashSale.isNotEmpty
            ? storefrontState.flashSale.length
            : storefrontState.products.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyCount = _queueReadyCount;
    final quickOrderCount = storefrontState.products.take(12).length;
    final freshCount = storefrontState.newArrival.length;
    final categoryCount = storefrontState.allCategory.length;
    final activeSupplier = (supplierName?.isNotEmpty ?? false)
        ? supplierName!
        : 'Active source';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.safe2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s reseller desk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$readyCount ready now',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$activeSupplier operator queue. $_focusNote',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Quick order',
                  value: '$quickOrderCount items',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Fresh drops',
                  value: '$freshCount new',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Browse',
                  value: '$categoryCount groups',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<FavouriteCubit, FavouriteState>(
            builder: (context, favourites) {
              return FutureBuilder<_HomeDashboardMetrics>(
                future: _loadDashboardMetrics(favourites),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const _DashboardMetricsSkeleton();
                  }
                  final metrics =
                      snapshot.data ?? const _HomeDashboardMetrics.empty();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s dashboard',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryMetricTile(
                              label: 'Active orders',
                              value: '${metrics.activeOrders}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricTile(
                              label: 'Confirmed today',
                              value: '${metrics.confirmedBuyersToday}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricTile(
                              label: 'Expected payout',
                              value: '৳ ${metrics.expectedPayout.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _SummaryMetricTile(
                              label: 'Top saved product',
                              value: metrics.topSavedProduct,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricTile(
                              label: 'Repeat prompts',
                              value: metrics.dueRepeatPrompts > 0
                                  ? '${metrics.dueRepeatPrompts} due'
                                  : '${metrics.openRepeatPrompts} open',
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(label: 'Focus', value: _focusLabel),
              _SummaryPill(
                label: 'Supplier',
                value: (supplierName?.isNotEmpty ?? false)
                    ? supplierName!
                    : 'Active source',
              ),
              const _SummaryPill(label: 'Next', value: 'Start order'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _PrimaryQueueAction(
                  title: 'Start order',
                  subtitle: 'Open your sell list and move straight to buyer setup',
                  onTap: () => AppRouter.goToSellingList(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniQueueAction(
                  title: 'Orders',
                  onTap: () => AppRouter.goToOrders(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniQueueAction(
                  title: 'Buyers',
                  onTap: () => AppRouter.goToBuyerBook(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResellerActionStrip extends StatelessWidget {
  const _ResellerActionStrip();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChipCard(
            icon: HugeIcons.strokeRoundedShoppingBag01,
            title: 'Start order',
            onTap: () => AppRouter.goToSellingList(context),
          ),
          const SizedBox(width: 10),
          _ActionChipCard(
            icon: HugeIcons.strokeRoundedInvoice03,
            title: 'Orders',
            onTap: () => AppRouter.goToOrders(context),
          ),
          const SizedBox(width: 10),
          _ActionChipCard(
            icon: HugeIcons.strokeRoundedUserGroup,
            title: 'Buyers',
            onTap: () => AppRouter.goToBuyerBook(context),
          ),
          const SizedBox(width: 10),
          _ActionChipCard(
            icon: HugeIcons.strokeRoundedWallet02,
            title: 'Payouts',
            onTap: () => AppRouter.goToPayouts(context),
          ),
          const SizedBox(width: 10),
          _ActionChipCard(
            icon: HugeIcons.strokeRoundedFavourite,
            title: 'Saved',
            onTap: () => AppRouter.goToSaved(context),
          ),
        ],
      ),
    );
  }
}

class _RepeatReminderHomeCard extends StatelessWidget {
  const _RepeatReminderHomeCard();

  Future<List<RepeatSellReminder>> _loadReminders() async {
    final reminders = await LocalStorage.getRepeatSellReminders();
    reminders.sort(
      (a, b) => (a.scheduledFor ?? DateTime(2100)).compareTo(
        b.scheduledFor ?? DateTime(2100),
      ),
    );
    return reminders;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RepeatSellReminder>>(
      future: _loadReminders(),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? const <RepeatSellReminder>[];
        final dueCount = reminders.where((item) => item.isDue).length;
        final nextReminder = reminders.isEmpty ? null : reminders.first;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neighborhood follow-up',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reminders.isEmpty
                    ? 'Add reminders from Buyer Book to keep repeat selling active in your local area.'
                    : 'Use Buyer Book reminders to reopen buyers and sell again without starting from zero.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryPill(label: 'Due now', value: '$dueCount'),
                  _SummaryPill(label: 'Queued', value: '${reminders.length}'),
                  _SummaryPill(
                    label: 'Next',
                    value: nextReminder == null
                        ? 'None'
                        : nextReminder.buyerName,
                  ),
                ],
              ),
              if (nextReminder != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${nextReminder.productTitle} • ${nextReminder.district}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 9 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardMetrics {
  const _HomeDashboardMetrics({
    required this.activeOrders,
    required this.confirmedBuyersToday,
    required this.expectedPayout,
    required this.topSavedProduct,
    required this.dueRepeatPrompts,
    required this.openRepeatPrompts,
  });

  const _HomeDashboardMetrics.empty()
    : activeOrders = 0,
      confirmedBuyersToday = 0,
      expectedPayout = 0,
      topSavedProduct = 'None yet',
      dueRepeatPrompts = 0,
      openRepeatPrompts = 0;

  final int activeOrders;
  final int confirmedBuyersToday;
  final double expectedPayout;
  final String topSavedProduct;
  final int dueRepeatPrompts;
  final int openRepeatPrompts;
}

class _DashboardMetricsSkeleton extends StatelessWidget {
  const _DashboardMetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppSkeleton(height: 14, width: 122, radius: 8),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 66, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: AppSkeleton(height: 66, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: AppSkeleton(height: 66, radius: 14)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(flex: 2, child: AppSkeleton(height: 66, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: AppSkeleton(height: 66, radius: 14)),
          ],
        ),
      ],
    );
  }
}

class _PrimaryQueueAction extends StatelessWidget {
  const _PrimaryQueueAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniQueueAction extends StatelessWidget {
  const _MiniQueueAction({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

class _ActionChipCard extends StatelessWidget {
  const _ActionChipCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          children: [
            AppHugeIcon(icon, size: 18, color: AppColor.primary),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _TwoRowCategoryRail extends StatelessWidget {
  const _TwoRowCategoryRail({required this.categories, required this.onTap});

  final List<CategoriesRes> categories;
  final void Function(CategoriesRes category, String title) onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories
            .take(12)
            .map(
              (category) => _HomeCategoryTile(
                category: category,
                onTap: onTap,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _HomeCategoryTile extends StatelessWidget {
  const _HomeCategoryTile({required this.category, required this.onTap});

  final CategoriesRes category;
  final void Function(CategoriesRes category, String title) onTap;

  @override
  Widget build(BuildContext context) {
    final title = (category.translation?.trim().isNotEmpty ?? false)
        ? category.translation!.trim()
        : (category.title ?? '--').trim();
    final imageUrl = category.cover ?? category.image ?? '';
    final initial = title.isNotEmpty
        ? String.fromCharCode(title.runes.first).toUpperCase()
        : '';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => onTap(category, title),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 78,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.safe),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: AppNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          backgroundColor: AppColor.safe1,
                        ),
                      )
                    : _CategoryFallback(initial: initial),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchHeaderDelegate({required this.child});

  static const double _extent = 72;

  final Widget child;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? AppColor.safe : Colors.transparent,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _InlineHomeState extends StatelessWidget {
  const _InlineHomeState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, color: AppColor.alert, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => onAction!.call(),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.safe1,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColor.neutral2,
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeleton(
          height: 58,
          radius: 18,
          margin: EdgeInsets.only(bottom: 14),
        ),
        AppSkeleton(
          height: 180,
          radius: 22,
          margin: EdgeInsets.only(bottom: 18),
        ),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: AppSkeleton(height: 100, radius: 18)),
          ],
        ),
        SizedBox(height: 18),
        AppSkeleton(height: 22, width: 150, radius: 999),
      ],
    );
  }
}
