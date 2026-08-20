import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/screens/checkout_screen.dart';
import 'package:sellhub/features/cart/screens/widget/reseller_price_sheet.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.isNewScreen = false});

  final bool? isNewScreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isNewScreen == true
          ? const SellHubTopAppBar(
              title: 'Selling List',
              subtitle: 'Share, quote, then order',
              icon: HugeIcons.strokeRoundedShoppingCart01,
              showBackButton: true,
            )
          : null,
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          final supplierGroups = _groupCartItems(cartState.items);
          final totalAmount = cartState.totalAmount.toInt();
          final totalSellAmount = cartState.totalSellAmount.toInt();
          final totalProfitAmount = cartState.totalProfitAmount.toInt();
          final totalCompareAmount = cartState.totalCompareAmount.toInt();
          final savedAmount = (totalCompareAmount - totalAmount).clamp(
            0,
            1 << 31,
          );
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    _CartHeaderCard(
                      itemCount: cartState.totalItems,
                      totalAmount: totalAmount,
                      totalSellAmount: totalSellAmount,
                      totalProfitAmount: totalProfitAmount,
                      onClear: () => context.read<CartCubit>().clearCart(),
                      onShare: () => _shareCart(context, cartState),
                      onPrepareQuote: () => _openCartCheckout(context),
                    ),
                    const SizedBox(height: 12),
                    const _PendingBuyerCartCard(),
                    const SizedBox(height: 12),
                    const _QuickSellFlowCard(),
                    const SizedBox(height: 12),
                    _SectionLabel(
                      icon: HugeIcons.strokeRoundedPackageMoving,
                      eyebrow: 'Supplier',
                      title: 'Supplier groups',
                    ),
                    const SizedBox(height: 16),
                    ...supplierGroups.map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CartSupplierSection(group: group),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: const Border(top: BorderSide(color: AppColor.safe)),
                ),
                child: FutureBuilder<BuyerBookProfile?>(
                  future: LocalStorage.getPendingBuyer(),
                  builder: (context, snapshot) {
                    final hasPendingBuyer = snapshot.data != null;
                    return Column(
                      children: <Widget>[
                        _SummaryRow(
                          label: 'Base',
                          value: '৳ ${convertToBengaliNumber(totalAmount)}',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Total',
                          value: '৳ ${convertToBengaliNumber(totalSellAmount)}',
                          bold: true,
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Profit',
                          value:
                              '৳ ${convertToBengaliNumber(totalProfitAmount)}',
                        ),
                        if (savedAmount > 0) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'You save',
                            value: '৳ ${convertToBengaliNumber(savedAmount)}',
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDFF55A),
                              foregroundColor: AppColor.text,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _openCartCheckout(context),
                            child: Text(
                              hasPendingBuyer
                                  ? 'Start quote for buyer'
                                  : 'Start quote',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasPendingBuyer
                              ? 'Buyer is ready. Address and final supplier order come next.'
                              : 'Buyer, address, and final supplier order come next.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColor.neutral2,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: isNewScreen == false
                              ? kBottomNavigationBarHeight +
                                    MediaQuery.of(context).padding.bottom +
                                    12
                              : 0,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const AppHugeIcon(
                          HugeIcons.strokeRoundedShoppingCart01,
                          size: 44,
                          color: AppColor.primary,
                        ),
                        Positioned(
                          top: 18,
                          right: 20,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColor.safe),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '0',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<BuyerBookProfile?>(
                    future: LocalStorage.getPendingBuyer(),
                    builder: (context, snapshot) {
                      final pendingBuyer = snapshot.data;
                      return Column(
                        children: [
                          Text(
                            pendingBuyer == null
                                ? 'Your selling list is empty'
                                : 'Buyer is ready for products',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pendingBuyer == null
                                ? 'Add products from any supplier. Set your sell price first, then finish the buyer order.'
                                : 'Add products now, then quote and finish the buyer order.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _EmptyCartHint(
                                  icon: HugeIcons.strokeRoundedShoppingBag02,
                                  title: pendingBuyer == null
                                      ? 'Browse'
                                      : 'Find',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _EmptyCartHint(
                                  icon: pendingBuyer == null
                                      ? HugeIcons.strokeRoundedFavourite
                                      : HugeIcons.strokeRoundedInvoice03,
                                  title: pendingBuyer == null
                                      ? 'Save'
                                      : 'Quote',
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: _EmptyCartHint(
                                  icon: HugeIcons.strokeRoundedDeliveryTruck02,
                                  title: 'Order',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const _PendingBuyerEmptyStateCard(),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: AppColor.safe)),
          ),
          child: FutureBuilder<BuyerBookProfile?>(
            future: LocalStorage.getPendingBuyer(),
            builder: (context, snapshot) {
              final pendingBuyer = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDFF55A),
                        foregroundColor: AppColor.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<StoreShellCubit>().setIndex(0);
                        if (isNewScreen == true) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: Text(
                        pendingBuyer == null
                            ? 'Find products'
                            : 'Find products for buyer',
                      ),
                    ),
                  ),
                  if (pendingBuyer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pick products now. ${pendingBuyer.name} will stay ready in checkout.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _shareCart(BuildContext context, CartState cartState) async {
    final store = context.read<StoreContextCubit>().state.activeStore;
    if (store == null || cartState.items.isEmpty) return;
    final text = SellHubShareLinkBuilder.buildCartShareText(
      store: store,
      items: cartState.items,
    );
    await Share.share(text, subject: 'Shared selling list');
  }
}

void _openCartCheckout(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CheckoutScreen(isCart: true)),
  );
}

class _PendingBuyerCartCard extends StatelessWidget {
  const _PendingBuyerCartCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuyerBookProfile?>(
      future: LocalStorage.getPendingBuyer(),
      builder: (context, snapshot) {
        final buyer = snapshot.data;
        if (buyer == null) return const SizedBox.shrink();
        final leadProduct = buyer.preferredProducts.isNotEmpty
            ? buyer.preferredProducts.first
            : null;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.safe),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedUser,
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
                      'Buyer ready to order',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${buyer.name} • ${buyer.phone}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leadProduct == null
                          ? 'Add products now. Buyer auto-fills in checkout.'
                          : 'Start with $leadProduct',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PendingBuyerPill(label: buyer.district),
                        _PendingBuyerPill(
                          label: buyer.isRepeatBuyer ? 'Repeat buyer' : 'Buyer',
                        ),
                        _PendingBuyerPill(label: buyer.sourceTag),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openCartCheckout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.text,
                          side: const BorderSide(color: AppColor.safe),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const AppHugeIcon(
                          HugeIcons.strokeRoundedInvoice03,
                          size: 16,
                          color: AppColor.text,
                        ),
                        label: const Text('Start order with buyer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingBuyerEmptyStateCard extends StatelessWidget {
  const _PendingBuyerEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuyerBookProfile?>(
      future: LocalStorage.getPendingBuyer(),
      builder: (context, snapshot) {
        final buyer = snapshot.data;
        if (buyer == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyer stays ready',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${buyer.name} • ${buyer.phone}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${buyer.name} is queued from Buyer Book. Add products now, then the buyer will auto-fill in checkout.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PendingBuyerPill(label: buyer.district),
                  _PendingBuyerPill(
                    label: buyer.isRepeatBuyer ? 'Repeat buyer' : 'Buyer',
                  ),
                  _PendingBuyerPill(label: buyer.sourceTag),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingBuyerPill extends StatelessWidget {
  const _PendingBuyerPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim().isEmpty ? 'Unknown' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        trimmed,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickSellFlowCard extends StatelessWidget {
  const _QuickSellFlowCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuyerBookProfile?>(
      future: LocalStorage.getPendingBuyer(),
      builder: (context, snapshot) {
        final hasPendingBuyer = snapshot.data != null;
        return Container(
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
                hasPendingBuyer
                    ? 'Buyer-ready flow'
                    : 'Quote-first selling flow',
                style: const TextStyle(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPendingBuyer
                    ? 'Pick products for the buyer, quote next, then finish the supplier order.'
                    : 'Price each item for the buyer, share the list, then finish the supplier order after confirmation.',
                style: const TextStyle(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickSellStep(
                      title: hasPendingBuyer ? 'Find' : 'Share',
                      subtitle: hasPendingBuyer
                          ? 'Pick products now'
                          : 'Post to WhatsApp or FB',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _QuickSellStep(
                      title: 'Quote',
                      subtitle: 'Lock buyer price first',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _QuickSellStep(
                      title: 'Order',
                      subtitle: 'Place supplier order',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickSellStep extends StatelessWidget {
  const _QuickSellStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

List<_CartSupplierGroup> _groupCartItems(List<CartItem> items) {
  final grouped = <int, List<CartItem>>{};
  for (final item in items) {
    final siteId = item.product.siteId ?? 0;
    grouped.putIfAbsent(siteId, () => <CartItem>[]).add(item);
  }
  final entries = grouped.entries.toList(growable: false)
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries
      .asMap()
      .entries
      .map((entry) {
        final itemList = entry.value.value;
        final baseAmount = itemList.fold<int>(
          0,
          (sum, item) =>
              sum + ((item.product.price ?? 0).round() * item.quantity),
        );
        return _CartSupplierGroup(
          supplierName: 'Anonymous supply source ${entry.key + 1}',
          items: itemList,
          baseAmount: baseAmount,
        );
      })
      .toList(growable: false);
}

class _CartSupplierGroup {
  const _CartSupplierGroup({
    required this.supplierName,
    required this.items,
    required this.baseAmount,
  });

  final String supplierName;
  final List<CartItem> items;
  final int baseAmount;
}

class _CartSupplierSection extends StatelessWidget {
  const _CartSupplierSection({required this.group});

  final _CartSupplierGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.safe),
          ),
          child: Row(
            children: [
              const AppHugeIcon(
                HugeIcons.strokeRoundedStore04,
                size: 18,
                color: AppColor.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.supplierName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.items.length} item${group.items.length > 1 ? 's' : ''} • Base ৳ ${convertToBengaliNumber(group.baseAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...group.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _EmptyCartHint extends StatelessWidget {
  const _EmptyCartHint({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          AppHugeIcon(icon, size: 18, color: AppColor.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColor.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartHeaderCard extends StatelessWidget {
  const _CartHeaderCard({
    required this.itemCount,
    required this.totalAmount,
    required this.totalSellAmount,
    required this.totalProfitAmount,
    required this.onClear,
    required this.onShare,
    required this.onPrepareQuote,
  });

  final int itemCount;
  final int totalAmount;
  final int totalSellAmount;
  final int totalProfitAmount;
  final VoidCallback onClear;
  final VoidCallback onShare;
  final VoidCallback onPrepareQuote;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuyerBookProfile?>(
      future: LocalStorage.getPendingBuyer(),
      builder: (context, snapshot) {
        final hasPendingBuyer = snapshot.data != null;
        final primaryButton = FilledButton.icon(
          onPressed: hasPendingBuyer ? onPrepareQuote : onShare,
          style: FilledButton.styleFrom(
            backgroundColor: hasPendingBuyer
                ? const Color(0xFFDFF55A)
                : AppColor.primary,
            foregroundColor: hasPendingBuyer ? AppColor.text : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: AppHugeIcon(
            hasPendingBuyer
                ? HugeIcons.strokeRoundedInvoice03
                : HugeIcons.strokeRoundedShare08,
            size: 16,
            color: hasPendingBuyer ? AppColor.text : Colors.white,
          ),
          label: Text(hasPendingBuyer ? 'Start quote' : 'Share list'),
        );
        final secondaryButton = OutlinedButton.icon(
          onPressed: hasPendingBuyer ? onShare : onPrepareQuote,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.text,
            side: const BorderSide(color: AppColor.safe),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: AppHugeIcon(
            hasPendingBuyer
                ? HugeIcons.strokeRoundedShare08
                : HugeIcons.strokeRoundedInvoice03,
            size: 16,
            color: AppColor.text,
          ),
          label: Text(hasPendingBuyer ? 'Share list' : 'Start quote'),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _InlineSectionLead(
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      eyebrow: 'Selling list',
                      title: 'Quote summary',
                    ),
                  ),
                  TextButton(onPressed: onClear, child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasPendingBuyer
                    ? 'Buyer is ready. Quote first, then confirm in checkout.'
                    : 'Buyer pricing stays here so you can quote before checkout.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CartMetric(label: 'Items', value: '$itemCount'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CartMetric(
                      label: 'Base',
                      value: '৳ ${convertToBengaliNumber(totalAmount)}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CartMetric(
                      label: 'Total',
                      value: '৳ ${convertToBengaliNumber(totalSellAmount)}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CartMetric(
                      label: 'Profit',
                      value: '৳ ${convertToBengaliNumber(totalProfitAmount)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: primaryButton),
                  const SizedBox(width: 10),
                  Expanded(child: secondaryButton),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartMetric extends StatelessWidget {
  const _CartMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final unitPrice = item.product.price?.toInt() ?? 0;
    final sellPrice = item.sellPrice;
    final lineTotal = unitPrice * item.quantity;
    final lineSellTotal = sellPrice * item.quantity;
    final lineProfit = (sellPrice - unitPrice) * item.quantity;
    final viability = ProductViabilityEngine.build(item.product);
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AppNetworkImage(
                imageUrl:
                    item.product.thumbnail ??
                    item.product.images.firstOrNull?.image,
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
              children: <Widget>[
                Text(
                  item.product.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.safe1,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Supplier item',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColor.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viability.supplierName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Base ৳ ${convertToBengaliNumber(item.product.price?.toInt() ?? 0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _QuantityPill(item: item),
                    _MiniActionChip(
                      label: 'Set price',
                      icon: HugeIcons.strokeRoundedInvoice03,
                      onTap: () async {
                        final newPrice = await showResellerPriceSheet(
                          context,
                          product: item.product,
                          initialPrice: item.sellPrice,
                        );
                        if (newPrice == null || !context.mounted) return;
                        await context.read<CartCubit>().updateSellPrice(
                          item,
                          newPrice,
                        );
                      },
                    ),
                    _MiniActionChip(
                      label: 'Share item',
                      icon: HugeIcons.strokeRoundedShare08,
                      onTap: activeStore == null
                          ? null
                          : () async {
                              await Share.share(
                                SellHubShareLinkBuilder.buildProductShareText(
                                  store: activeStore,
                                  product: item.product,
                                  sellPrice: item.sellPrice,
                                ),
                                subject: item.product.title ?? 'Shared item',
                              );
                            },
                    ),
                    _MiniActionChip(
                      label: 'Remove',
                      icon: HugeIcons.strokeRoundedDelete02,
                      onTap: () =>
                          context.read<CartCubit>().removeFromCart(item),
                      isAlert: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sell ৳ ${convertToBengaliNumber(sellPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Text(
                              'Range ৳${convertToBengaliNumber(item.minSellPrice)}-${convertToBengaliNumber(item.maxSellPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColor.neutral2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Base ৳ ${convertToBengaliNumber(lineTotal)} • Total ৳ ${convertToBengaliNumber(lineSellTotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColor.neutral2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profit ৳ ${convertToBengaliNumber(lineProfit)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColor.text,
                        ),
                      ),
                    ],
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

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => context.read<CartCubit>().updateQuantity(
              item,
              item.quantity - 1,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: AppHugeIcon(
                HugeIcons.strokeRoundedMinusSign,
                size: 16,
                color: AppColor.text,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () => context.read<CartCubit>().updateQuantity(
              item,
              item.quantity + 1,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: AppHugeIcon(
                HugeIcons.strokeRoundedPlusSign,
                size: 16,
                color: AppColor.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isAlert = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final foreground = isAlert ? AppColor.alert : AppColor.text;
    final background = isAlert ? AppColor.alertLight : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isAlert ? AppColor.alertLight : AppColor.safe,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _InlineSectionLead(icon: icon, eyebrow: eyebrow, title: title);
  }
}

class _InlineSectionLead extends StatelessWidget {
  const _InlineSectionLead({
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: const Color(0xFF1F2937),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
