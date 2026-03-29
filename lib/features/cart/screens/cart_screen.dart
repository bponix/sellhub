import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/screens/checkout_screen.dart';
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
              title: 'My Cart',
              subtitle: 'Review your bag',
              icon: HugeIcons.strokeRoundedShoppingCart01,
              showBackButton: true,
            )
          : null,
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          final totalAmount = cartState.totalAmount.toInt();
          final totalCompareAmount = cartState.totalCompareAmount.toInt();
          final savedAmount = (totalCompareAmount - totalAmount).clamp(0, 1 << 31);
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    _CartHeaderCard(
                      itemCount: cartState.totalItems,
                      totalAmount: totalAmount,
                      onClear: () => context.read<CartCubit>().clearCart(),
                      onShare: () => _shareCart(context, cartState),
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel(
                      icon: HugeIcons.strokeRoundedPackageMoving,
                      eyebrow: 'Bag items',
                      title: 'Review items',
                    ),
                    const SizedBox(height: 16),
                    ...cartState.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartItemCard(item: item),
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
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.safe1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColor.safe),
                      ),
                      child: const Row(
                        children: <Widget>[
                          AppHugeIcon(
                            HugeIcons.strokeRoundedCoupon01,
                            size: 18,
                            color: AppColor.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Promo and delivery options come next.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.neutral2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '৳ ${convertToBengaliNumber(totalAmount)}',
                    ),
                    if (savedAmount > 0) ...[
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'You save',
                        value: '৳ ${convertToBengaliNumber(savedAmount)}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    const _SummaryRow(
                      label: 'Delivery',
                      value: 'Selected in checkout',
                    ),
                    const SizedBox(height: 12),
                    const _DashedDivider(),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Estimated total',
                      value: '৳ ${convertToBengaliNumber(totalAmount)}',
                      bold: true,
                    ),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CheckoutScreen(isCart: true),
                            ),
                          );
                        },
                        child: const Text('Go to checkout'),
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
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add a few products and come back when you are ready to place an order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Expanded(
                          child: _EmptyCartHint(
                            icon: HugeIcons.strokeRoundedShoppingBag02,
                            title: 'Browse',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _EmptyCartHint(
                            icon: HugeIcons.strokeRoundedFavourite,
                            title: 'Save',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _EmptyCartHint(
                            icon: HugeIcons.strokeRoundedDeliveryTruck02,
                            title: 'Checkout',
                          ),
                        ),
                      ],
                    ),
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
          child: SizedBox(
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
              child: const Text('Browse products'),
            ),
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
    await Share.share(text, subject: 'Shared cart');
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
    required this.onClear,
    required this.onShare,
  });

  final int itemCount;
  final int totalAmount;
  final VoidCallback onClear;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
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
              const _InlineSectionLead(
                icon: HugeIcons.strokeRoundedShoppingCart01,
                eyebrow: 'Cart summary',
                title: 'Cart overview',
              ),
              const Spacer(),
              IconButton(
                onPressed: onShare,
                tooltip: 'Share cart',
                icon: const AppHugeIcon(
                  HugeIcons.strokeRoundedShare08,
                  size: 18,
                  color: AppColor.primary,
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear cart')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CartMetric(
                  label: 'Items',
                  value: '$itemCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CartMetric(
                  label: 'Subtotal',
                  value: '৳ ${convertToBengaliNumber(totalAmount)}',
                ),
              ),
            ],
          ),
        ],
      ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final unitPrice = item.product.price?.toInt() ?? 0;
    final lineTotal = unitPrice * (item.quantity as int);
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
                        'Ready to ship',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColor.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '৳ ${convertToBengaliNumber(item.product.price?.toInt() ?? 0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          InkWell(
                            onTap: () => context
                                .read<CartCubit>()
                                .updateQuantity(item, item.quantity - 1),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => context
                                .read<CartCubit>()
                                .updateQuantity(item, item.quantity + 1),
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
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳ ${convertToBengaliNumber(lineTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () =>
                              context.read<CartCubit>().removeFromCart(item),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.alertLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppHugeIcon(
                                  HugeIcons.strokeRoundedDelete02,
                                  size: 15,
                                  color: AppColor.alert,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: AppColor.alert,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    return _InlineSectionLead(
      icon: icon,
      eyebrow: eyebrow,
      title: title,
    );
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

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(width: 4, height: 1, color: Colors.grey.shade400),
          ),
        );
      },
    );
  }
}
