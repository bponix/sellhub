import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/paymentgateway_req.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_state.dart';
import 'package:sellhub/features/cart/screens/order_complete_welcome.dart';
import 'package:sellhub/features/cart/screens/payment_gateway_webview_screen.dart';
import 'package:sellhub/features/cart/screens/widget/selectableAreaPay.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.address,
    required this.isCart,
    this.comparePrice,
    this.payPrice,
    this.savePrice,
    this.title,
    this.id,
  });

  final bool isCart;
  final int? comparePrice;
  final int? payPrice;
  final int? savePrice;
  final String? title;
  final int? id;
  final int phone;
  final String name;
  final String address;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Payment & Delivery',
        subtitle: 'Review and place order',
        icon: HugeIcons.strokeRoundedWallet01,
        showBackButton: true,
      ),
      body: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, checkoutState) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final compareAmount = widget.isCart
                  ? cartState.totalCompareAmount.toInt()
                  : widget.comparePrice ?? 0;
              final payAmount = widget.isCart
                  ? cartState.totalAmount.toInt()
                  : widget.payPrice ?? 0;
              final voucherDiscount =
                  checkoutState.voucher?.discount.round() ?? 0;
              final discountedPayAmount = max(0, payAmount - voucherDiscount);
              final totalAmount =
                  (checkoutState.deliveryCharge + discountedPayAmount).toInt();
              final saveAmount = widget.isCart
                  ? (cartState.totalCompareAmount - cartState.totalAmount)
                        .toInt()
                  : widget.savePrice ?? 0;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PaymentHero(
                            totalAmount: totalAmount,
                            deliveryCharge:
                                checkoutState.deliveryCharge.toInt(),
                            voucherDiscount: voucherDiscount,
                          ),
                          const SizedBox(height: 16),
                          const _PaymentStepHeader(),
                          const SizedBox(height: 16),
                          _SelectionSummaryCard(
                            title: 'Ready to place order',
                            subtitle: 'Shipping, area, payment.',
                            rows: [
                              _SelectionSummaryRow(
                                label: 'Shipping to',
                                value: widget.address,
                              ),
                              _SelectionSummaryRow(
                                label: 'Customer',
                                value: widget.name,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedMapsLocation01,
                                  eyebrow: 'Area selection',
                                  title: 'Delivery area',
                                ),
                                const SizedBox(height: 10),
                                SelectableListAreaPay(
                                  itemCount: checkoutState.deliveryPlace.length,
                                  selectedIndex: checkoutState.areaSelect,
                                  isSelected: (index) =>
                                      checkoutState.areaSelect == index,
                                  onTap: (index) {
                                    final data = checkoutState.deliveryPlace[index];
                                    context.read<CheckoutCubit>().setAreaSelect(
                                      index,
                                    );
                                    context.read<CheckoutCubit>().setDeliveryCharge(
                                      data.chargeMerchantDefined ?? 0.0,
                                    );
                                    context.read<CheckoutCubit>().setDeliveryWay(
                                      data.title ?? '',
                                    );
                                    context.read<CheckoutCubit>().setLogisticId(
                                      data.id ?? 0,
                                    );
                                  },
                                  titleBuilder: (index) {
                                    final data = checkoutState.deliveryPlace[index];
                                    return Text(
                                      data.title ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                  subtitleBuilder: (index) {
                                    final data = checkoutState.deliveryPlace[index];
                                    return Text(
                                      'Delivery charge: ৳${convertToBengaliNumber(data.chargeMerchantDefined?.toInt() ?? 0)}',
                                      style: TextStyle(
                                        color: checkoutState.areaSelect == index
                                            ? AppColor.text
                                            : AppColor.neutral2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedWallet01,
                                  eyebrow: 'Gateway selection',
                                  title: 'Payment method',
                                ),
                                const SizedBox(height: 10),
                                SelectableListAreaPay(
                                  itemCount: checkoutState.paymentMethod.length,
                                  selectedIndex: checkoutState.paySelect,
                                  isSelected: (index) =>
                                      checkoutState.paySelect == index,
                                  onTap: (index) {
                                    context.read<CheckoutCubit>().setPaySelect(
                                      index,
                                    );
                                    context.read<CheckoutCubit>().setGatewayText(
                                      checkoutState.paymentMethod[index].title ??
                                          '',
                                    );
                                  },
                                  titleBuilder: (index) {
                                    final data = checkoutState.paymentMethod[index];
                                    return Text(
                                      data.title ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                  subtitleBuilder: (index) {
                                    return Text(
                                      'Payment amount: ৳${convertToBengaliNumber(totalAmount)}',
                                      style: TextStyle(
                                        color: checkoutState.paySelect == index
                                            ? AppColor.text
                                            : AppColor.neutral2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                  trailingBuilder: (index) {
                                    final data = checkoutState.paymentMethod[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: AppNetworkImage(
                                        imageUrl: data.logo,
                                        height: 38,
                                        width: 58,
                                        fit: BoxFit.contain,
                                        backgroundColor: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColor.safe),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PaymentSectionLead(
                                  icon: HugeIcons.strokeRoundedInvoice03,
                                  eyebrow: 'Final breakdown',
                                  title: 'Order summary',
                                ),
                            const SizedBox(height: 10),
                            Divider(
                              color: AppColor.grey.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '৳${convertToBengaliNumber(compareAmount)}',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColor.neutral1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '৳${convertToBengaliNumber(discountedPayAmount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (voucherDiscount > 0) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Voucher discount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '-৳${convertToBengaliNumber(voucherDiscount)}',
                                    style: const TextStyle(
                                      color: AppColor.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  const Text(
                                    'Delivery charge',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '৳${convertToBengaliNumber(checkoutState.deliveryCharge.toInt())}',
                                  style: const TextStyle(
                                    color: AppColor.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery method',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColor.grey,
                                  ),
                                ),
                                Text(
                                  checkoutState.deliveryWay.isEmpty
                                      ? 'Not selected'
                                      : checkoutState.deliveryWay,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColor.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Divider(
                              color: AppColor.grey.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '৳${convertToBengaliNumber(totalAmount)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: AppColor.grey.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated delivery:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColor.grey,
                                  ),
                                ),
                                Text(
                                  '3-7 days',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColor.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColor.green.withValues(alpha: 0.2),
                              ),
                                child: Center(
                                  child: Text(
                                    'You saved ৳${convertToBengaliNumber(saveAmount)} on this order',
                                    style: const TextStyle(
                                      color: AppColor.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                  _PaymentBottomBar(
                    totalAmount: totalAmount,
                    savingAmount: saveAmount,
                    loading: checkoutState.isLoading,
                    onConfirm: () => _submitOrder(
                      context,
                      checkoutState,
                      cartState,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(
    BuildContext context,
    CheckoutState checkoutState,
    CartState cartState,
  ) async {
    try {
      if (checkoutState.isLoading) {
        return;
      }
      final checkoutCubit = context.read<CheckoutCubit>();
      final navigator = Navigator.of(context);
      final cartCubit = context.read<CartCubit>();
      final activeSiteId = StoreScope.activeSiteId(context);
      final activeSourceId = StoreScope.activeSourceId(context);
      final activeDomain = StoreScope.activeDomain(context);
      final products = widget.isCart
          ? cartState.items.map((cartItem) {
              final node = cartItem.product;
              return ProductOrderCreate(
                cost: 0,
                id: node.id,
                price: node.price?.toInt(),
                quantity: cartItem.quantity,
                resellPrice: node.maxResellPrice?.toInt(),
                thumbnail: node.thumbnail,
                title: node.title,
                variant: '',
                variantId: null,
                vat: node.vat?.toInt() ?? 0,
              );
            }).toList()
          : <ProductOrderCreate>[
              ProductOrderCreate(
                cost: 0,
                id: widget.id,
                price: widget.payPrice,
                quantity: 1,
                resellPrice: 0,
                thumbnail: '',
                title: widget.title,
                variant: '',
                variantId: null,
                vat: 0,
              ),
            ];

      final otp = Random().nextInt(900000) + 100000;
      final userId = await LocalStorage.getUserID();
      final customerId = checkoutState.customerId > 0
          ? checkoutState.customerId
          : ((await LocalStorage.getCustomerID()) ?? 0);
      final voucherDiscount = checkoutState.voucher?.discount.round() ?? 0;
      final orderSubtotal = widget.isCart
          ? cartState.totalAmount.toInt()
          : widget.payPrice ?? 0;
      final finalSubtotal = max(0, orderSubtotal - voucherDiscount);
      final finalTotal = finalSubtotal + checkoutState.deliveryCharge.toInt();

      if (widget.name.trim().isEmpty ||
          widget.address.trim().isEmpty ||
          widget.phone <= 0) {
        CustomToast.error('Customer details are incomplete');
        return;
      }
      if (checkoutState.deliveryPlace.isEmpty) {
        CustomToast.error('Delivery areas are unavailable right now');
        return;
      }
      if (checkoutState.areaSelect < 0 ||
          checkoutState.areaSelect >= checkoutState.deliveryPlace.length) {
        CustomToast.error('Select a delivery area');
        return;
      }
      if (checkoutState.paymentMethod.isEmpty) {
        CustomToast.error('Payment methods are not available right now');
        return;
      }
      if (checkoutState.paySelect < 0 ||
          checkoutState.paySelect >= checkoutState.paymentMethod.length) {
        CustomToast.error('Select a payment method');
        return;
      }

      final selectedArea = checkoutState.deliveryPlace[checkoutState.areaSelect];
      final selectedGate = checkoutState.paymentMethod[checkoutState.paySelect];

      final model = OrderCreateReq(
        userId: null,
        siteId: activeSiteId,
        address: widget.address,
        affiliateCommission: 0,
        browser: null,
        cashbackBalance: 0,
        charge: 0,
        cost: 0,
        currency: 'BDT',
        customerAddress: widget.address,
        customerId: customerId > 0 ? customerId : null,
        customerName: widget.name,
        customerNote: '',
        customerPhone: widget.phone,
        deliveryTime: null,
        discount: voucherDiscount,
        discountName: checkoutState.voucherCode.isEmpty
            ? ''
            : checkoutState.voucherCode,
        emiDuration: 0,
        emiInterest: 0,
        gatewayText: (selectedGate.title ?? '').trim(),
        grossAmount: orderSubtotal,
        image: null,
        isEmi: false,
        isRenew: false,
        latitude: 23.810332,
        logisticsCharge: (selectedArea.chargeMerchantDefined ?? 0).toInt(),
        logisticsExtraCharge: 0,
        logisticsId: selectedArea.id ?? 0,
        logisticsStoppageId: null,
        logisticsText: (selectedArea.title ?? '').trim(),
        longitude: 90.4125181,
        netAmount: finalSubtotal,
        otp: otp,
        paid: 0,
        parentSiteId: null,
        productId: products.isNotEmpty ? products.first.id : null,
        products: products,
        profit: 0,
        referCode: '6',
        resellAmount: 0,
        resellerAdvanceCollect: 0,
        resellerCommission: 0,
        rewardPoints: 0,
        shopId: null,
        sourceId: activeSourceId,
        source: activeDomain,
        staffId: null,
        subscription: null,
        subscriptionFee: null,
        total: finalTotal,
        validTill: null,
        vat: 0,
        vatAmount: 0,
        weight: 0,
      );

      if ((selectedGate.title ?? '').toLowerCase().contains('bkash')) {
        if (!context.mounted) return;
        final result = await checkoutCubit.payWithBkash(
          context,
          finalTotal.toDouble(),
        );
        if (!context.mounted) return;
        if (!result.success) {
          CustomToast.error('Payment failed');
          return;
        }
        final order = await checkoutCubit.makeOrder(
          model,
          isAuthenticated: userId != null && customerId > 0,
          userId: userId,
          customerId: customerId > 0 ? customerId : null,
        );
        if (!context.mounted) return;
        CustomToast.info('Payment successful');
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderCompleteWelcome(order: order),
          ),
        );
        return;
      }

      if ((selectedGate.title ?? '').toLowerCase().contains('cod')) {
        final order = await checkoutCubit.makeOrder(
          model,
          isAuthenticated: userId != null && customerId > 0,
          userId: userId,
          customerId: customerId > 0 ? customerId : null,
        );
        if (!context.mounted) return;
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderCompleteWelcome(order: order),
          ),
        );
        return;
      }

      final paymentRequestSuccess = await checkoutCubit.paymentGatewayRequest(
            PaymentGatewayReq(
              siteId: activeSiteId,
              gatewayId: selectedGate.id,
              amount: finalTotal,
              cancelUrl: _normalizeGatewayUrl('$activeDomain/payment-cancel'),
              currency: 'BDT',
              customerName: widget.name,
              emiDuration: 0,
              emiInterest: 0,
              failUrl: _normalizeGatewayUrl('$activeDomain/payment-fail'),
              isCardTransaction: false,
              isCodPayment: false,
              isEmi: false,
              merchantId: customerId > 0 ? customerId : 0,
              payeeSource: _normalizeGatewayUrl(activeDomain),
              productInfo: widget.title ?? 'SellHub order',
              referenceId: 'order-${DateTime.now().millisecondsSinceEpoch}',
              showRefundButton: false,
              successUrl: _normalizeGatewayUrl('$activeDomain/payment-success'),
              transactionType: selectedGate.gatewayType ?? 1,
            ),
          );
      final gatewayPayload =
          (paymentRequestSuccess.displayValue ?? '').trim().isNotEmpty
          ? paymentRequestSuccess.displayValue!.trim()
          : (paymentRequestSuccess.callBack ?? '').trim();
      if (gatewayPayload.isEmpty) {
        CustomToast.error('Gateway checkout link is unavailable');
        return;
      }
      if (!context.mounted) return;
      final gatewayResult = await navigator.push<PaymentGatewayWebViewResult>(
        MaterialPageRoute(
          builder: (_) => PaymentGatewayWebViewScreen(
            title: selectedGate.title ?? 'Secure checkout',
            initialPayload: gatewayPayload,
            successUrl: _normalizeGatewayUrl(
              paymentRequestSuccess.successUrl ?? '$activeDomain/payment-success',
            ),
            failUrl: _normalizeGatewayUrl('$activeDomain/payment-fail'),
            cancelUrl: _normalizeGatewayUrl(
              paymentRequestSuccess.cancelUrl ?? '$activeDomain/payment-cancel',
            ),
          ),
        ),
      );
      if (!context.mounted) return;
      if (gatewayResult == PaymentGatewayWebViewResult.success) {
        final order = await checkoutCubit.makeOrder(
          model,
          isAuthenticated: userId != null && customerId > 0,
          userId: userId,
          customerId: customerId > 0 ? customerId : null,
        );
        if (!context.mounted) return;
        if (widget.isCart) {
          await cartCubit.clearCart();
        }
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderCompleteWelcome(order: order),
          ),
        );
        return;
      }
      if (gatewayResult == PaymentGatewayWebViewResult.cancelled) {
        CustomToast.info('Payment was cancelled');
        return;
      }
      CustomToast.error('Payment failed');
    } catch (error) {
      CustomToast.error('Could not create order: $error');
    }
  }

  String _normalizeGatewayUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }
}

class _PaymentStepHeader extends StatelessWidget {
  const _PaymentStepHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 of 2',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Delivery and payment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose delivery area and a supported gateway.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHero extends StatelessWidget {
  const _PaymentHero({
    required this.totalAmount,
    required this.deliveryCharge,
    required this.voucherDiscount,
  });

  final int totalAmount;
  final int deliveryCharge;
  final int voucherDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedWallet01,
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
                  'Final payment',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total ৳${convertToBengaliNumber(totalAmount)}  •  Delivery ৳${convertToBengaliNumber(deliveryCharge)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              voucherDiscount > 0 ? 'Discounted' : 'Confirmed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSectionLead extends StatelessWidget {
  const _PaymentSectionLead({
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
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(
            icon,
            size: 18,
            color: AppColor.primary,
          ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.totalAmount,
    required this.savingAmount,
    required this.loading,
    required this.onConfirm,
  });

  final int totalAmount;
  final int savingAmount;
  final bool loading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColor.safe)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳${convertToBengaliNumber(totalAmount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (savingAmount > 0)
                  Text(
                    'Saved ৳${convertToBengaliNumber(savingAmount)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColor.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: loading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  const _SelectionSummaryCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<_SelectionSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }
}

class _SelectionSummaryRow extends StatelessWidget {
  const _SelectionSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColor.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
