import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/debouncer.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_cubit.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_state.dart';
import 'package:sellhub/features/cart/screens/payment_screen.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
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

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _voucherController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    final storefront = context.read<StorefrontCubit>().state;
    context.read<CheckoutCubit>().fetchPaymentMethod(
      StoreScope.siteIdFromState(storefront),
    );
    context.read<CheckoutCubit>().fetchDeliveryPlace(
      storefront.siteDetails?.createdById ??
          storefront.siteDetails?.createdBy?.id ??
          0,
    );
    _loadCustomerContext();
    _phoneController.addListener(_onPhoneChanged);
  }

  Future<void> _loadCustomerContext() async {
    final userId = await LocalStorage.getUserID();
    if (userId == null || userId <= 0 || !mounted) return;
    await context.read<CheckoutCubit>().hydrateCustomerContext(
      userId: userId,
      siteId: StoreScope.activeSiteId(context),
    );
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _voucherController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    _debouncer.run(() async {
      if (_phoneController.text.length != 11) return;
      final fullPhone = _phoneController.text.startsWith('88')
          ? _phoneController.text.trim()
          : '88${_phoneController.text.trim()}';

      try {
        final user = await context.read<AuthCubit>().checkUser(fullPhone);
        if (!mounted || user == null) return;
        setState(() {
          _nameController.text = user.name;
          _addressController.text = user.address;
        });
        Fluttertoast.showToast(
          msg: 'User details found!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Checkout',
        subtitle: 'Shipping and offers',
        icon: HugeIcons.strokeRoundedShoppingBasket01,
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
              final saveAmount = widget.isCart
                  ? (cartState.totalCompareAmount - cartState.totalAmount)
                        .toInt()
                  : widget.savePrice ?? 0;
              final voucherDiscount =
                  checkoutState.voucher?.discount.round() ?? 0;
              final payableAmount = (payAmount - voucherDiscount).clamp(
                0,
                1 << 31,
              );
              final itemCount = widget.isCart ? cartState.totalItems : 1;

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CheckoutHero(
                              itemCount: itemCount,
                              payableAmount: payableAmount,
                              voucherDiscount: voucherDiscount,
                            ),
                            SizedBox(height: 14.h),
                            _CheckoutBagHeader(
                              itemCount: itemCount,
                              totalAmount: payableAmount,
                            ),
                            SizedBox(height: 14.h),
                            const _CheckoutStepHeader(
                              title: 'Step 1 of 2',
                              subtitle: 'Shipping and offers',
                              currentStep: 0,
                            ),
                            if (checkoutState.error != null) ...[
                              SizedBox(height: 12.h),
                                _InlineStatusCard(
                                  title: checkoutState.error!.title,
                                  subtitle: 'Check the form and try again.',
                                  tone: _StatusTone.error,
                                ),
                            ],
                            SizedBox(height: 16.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedUserCircle,
                              'Shipping Address',
                            ),
                            SizedBox(height: 12.h),
                            _buildInputCard([
                              _InfoStrip(
                                icon: HugeIcons.strokeRoundedPackageMoving,
                                title: 'Delivery contact',
                                subtitle: 'Phone, name, address',
                              ),
                              SizedBox(height: 12.h),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: '017xxxxxxxx',
                                icon: HugeIcons.strokeRoundedSmartPhone01,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 12.h),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your name',
                                icon: HugeIcons.strokeRoundedUser,
                              ),
                              SizedBox(height: 12.h),
                              _buildTextField(
                                controller: _addressController,
                                label: 'Full Address',
                                hint: 'House, street, area',
                                icon: HugeIcons.strokeRoundedMapsLocation01,
                                maxLines: 3,
                              ),
                              if (checkoutState.savedShippingAddresses.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                _buildSavedAddressPicker(
                                  checkoutState.savedShippingAddresses,
                                  checkoutState.selectedShippingAddressId,
                                ),
                              ],
                              if (checkoutState.customerId > 0) ...[
                                SizedBox(height: 10.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final success = await context
                                          .read<CheckoutCubit>()
                                          .saveShippingAddress(
                                            customerId: checkoutState.customerId,
                                            address: _addressController.text.trim(),
                                          );
                                      if (!mounted) return;
                                      if (success) {
                                        CustomToast.info('Address saved');
                                      }
                                    },
                                    icon: const AppHugeIcon(
                                      HugeIcons.strokeRoundedBookmarkAdd01,
                                      size: 16,
                                      color: AppColor.primary,
                                      semanticLabel: 'Save address',
                                    ),
                                    label: const Text('Save address'),
                                  ),
                                ),
                              ],
                            ]),
                            SizedBox(height: 18.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedCoupon01,
                              'Promo & Voucher',
                            ),
                            SizedBox(height: 12.h),
                            _buildInputCard([
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _voucherController,
                                      label: 'Voucher Code',
                                      hint: 'Enter promo code',
                                      icon: HugeIcons.strokeRoundedCoupon01,
                                      required: false,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  SizedBox(
                                    height: 48.h,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _applyVoucher(checkoutState, cartState),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColor.safe),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                    child: const Text('Apply'),
                                  ),
                                ),
                              ],
                              ),
                              if (checkoutState.voucher != null) ...[
                                SizedBox(height: 10.h),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColor.safe1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColor.safe),
                                  ),
                                    child: Row(
                                      children: [
                                      const AppHugeIcon(
                                        HugeIcons.strokeRoundedCoupon01,
                                        size: 16,
                                        color: AppColor.green,
                                        backgroundColor: AppColor.safe1,
                                        borderColor: AppColor.safe,
                                        borderRadius: 12,
                                        padding: EdgeInsets.all(6),
                                        semanticLabel: 'Voucher applied',
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          checkoutState.voucher!.message,
                                          style: const TextStyle(
                                            color: AppColor.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _voucherController.clear();
                                          context.read<CheckoutCubit>().clearVoucher();
                                        },
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ]),
                            SizedBox(height: 18.h),
                            _buildSectionTitle(
                              HugeIcons.strokeRoundedInvoice03,
                              'Summary',
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColor.safe),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Items',
                                          value: '$itemCount',
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Savings',
                                          value: '৳ ${convertToBengaliNumber(saveAmount)}',
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _SummaryMetric(
                                          label: 'Voucher',
                                          value: voucherDiscount > 0
                                              ? '-৳ ${convertToBengaliNumber(voucherDiscount)}'
                                              : '0',
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  _buildSummaryRow(
                                    'Subtotal',
                                    '৳ ${convertToBengaliNumber(compareAmount)}',
                                    isOldPrice: true,
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildSummaryRow(
                                    'Payable',
                                    '৳ ${convertToBengaliNumber(payableAmount)}',
                                    isTotal: true,
                                  ),
                                  if (voucherDiscount > 0) ...[
                                    SizedBox(height: 12.h),
                                    _buildSummaryRow(
                                      'Voucher Discount',
                                      '- ৳ ${convertToBengaliNumber(voucherDiscount)}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _CheckoutBottomBar(
                      amount: payableAmount,
                      savings: saveAmount,
                      loading: checkoutState.isLoading,
                      onContinue: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        context.read<AnalyticsService>().logCheckoutStarted(
                          siteId: StoreScope.activeSiteId(context),
                          fromCart: widget.isCart,
                          totalItems: itemCount,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              phone: int.tryParse(_phoneController.text.trim()) ?? 0,
                              name: _nameController.text.trim(),
                              address: _addressController.text.trim(),
                              isCart: widget.isCart,
                              comparePrice: widget.comparePrice,
                              payPrice: widget.payPrice,
                              savePrice: widget.savePrice,
                              title: widget.title ?? '',
                              id: widget.id,
                            ),
                          ),
                        );
                      },
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

  Widget _buildSectionTitle(List<List<dynamic>> icon, String title) {
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
          child: AppHugeIcon(icon, color: AppColor.primary, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checkout section',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.neutral2,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<List<dynamic>> icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColor.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.safe),
            ),
            child: AppHugeIcon(icon, size: 16.sp, color: AppColor.primary),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        labelStyle: TextStyle(
          color: AppColor.neutral2,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: AppColor.neutral1,
          fontSize: 13.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: maxLines > 1 ? 16.h : 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColor.safe),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppColor.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
      validator: required
          ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildSummaryRow(
    String title,
    String amount, {
    bool isTotal = false,
    bool isOldPrice = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: isTotal ? Colors.black : Colors.grey.shade600,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColor.primary : Colors.black87,
            decoration: isOldPrice ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddressPicker(
    List<StoreCustomerAddressModel> addresses,
    int? selectedId,
  ) {
    if (_addressController.text.trim().isEmpty && addresses.isNotEmpty) {
      _addressController.text = addresses.first.address;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Addresses',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Tap one to fill the delivery address quickly',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: AppColor.neutral2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: addresses.map((address) {
            final selected = selectedId == address.id;
            return InkWell(
              onTap: () {
                context.read<CheckoutCubit>().selectShippingAddress(address);
                _addressController.text = address.address;
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 220.w,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColor.safe1 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColor.primary : AppColor.safe,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected ? AppColor.primary : AppColor.safe1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppHugeIcon(
                        selected
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : HugeIcons.strokeRoundedMapsLocation01,
                        size: 15,
                        color: selected ? Colors.white : AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address.address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.text,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _applyVoucher(
    CheckoutState checkoutState,
    CartState cartState,
  ) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      CustomToast.error('Enter a voucher code');
      return;
    }
    final userId = await LocalStorage.getUserID();
    final products = widget.isCart
        ? cartState.items
              .map(
                (item) => <String, dynamic>{
                  'id': item.product.id,
                  'price': item.product.price,
                  'quantity': item.quantity,
                  'title': item.product.title,
                },
              )
              .toList()
        : <Map<String, dynamic>>[
            <String, dynamic>{
              'id': widget.id,
              'price': widget.payPrice,
              'quantity': 1,
              'title': widget.title,
            },
          ];
    final total = widget.isCart
        ? cartState.totalAmount.toDouble()
        : (widget.payPrice ?? 0).toDouble();
    final quantity = widget.isCart
        ? cartState.items.fold<double>(0, (sum, item) => sum + item.quantity)
        : 1.0;
    await checkoutCubit.applyVoucher(
      siteId: siteId,
      code: code,
      quantity: quantity,
      total: total,
      delivery: checkoutState.deliveryCharge,
      products: products,
      userId: userId,
    );
    if (!mounted) return;
    final message = checkoutCubit.state.voucher?.message;
    if (message?.isNotEmpty == true) {
      CustomToast.info(message!);
    }
  }
}

class _CheckoutStepHeader extends StatelessWidget {
  const _CheckoutStepHeader({
    required this.title,
    required this.subtitle,
    required this.currentStep,
  });

  final String title;
  final String subtitle;
  final int currentStep;

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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Checkout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StepPill(
                  title: 'Address',
                  active: currentStep == 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepPill(
                  title: 'Payment',
                  active: currentStep == 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutHero extends StatelessWidget {
  const _CheckoutHero({
    required this.itemCount,
    required this.payableAmount,
    required this.voucherDiscount,
  });

  final int itemCount;
  final int payableAmount;
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
              HugeIcons.strokeRoundedShoppingBasket01,
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
                  'Checkout overview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$itemCount items  •  ৳ ${convertToBengaliNumber(payableAmount)}',
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
              voucherDiscount > 0 ? 'Voucher on' : 'Ready',
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

class _CheckoutBagHeader extends StatelessWidget {
  const _CheckoutBagHeader({
    required this.itemCount,
    required this.totalAmount,
  });

  final int itemCount;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedShoppingBag02,
              color: AppColor.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Shopping Bag ($itemCount items)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
          ),
          Text(
            '৳ ${convertToBengaliNumber(totalAmount)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColor.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.amount,
    required this.savings,
    required this.loading,
    required this.onContinue,
  });

  final int amount;
  final int savings;
  final bool loading;
  final VoidCallback onContinue;

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
                  'Payable',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳ ${convertToBengaliNumber(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (savings > 0)
                  Text(
                    'Save ৳ ${convertToBengaliNumber(savings)}',
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
              height: 52.h,
              child: ElevatedButton(
                onPressed: loading ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDFF55A),
                  foregroundColor: AppColor.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.text,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Flexible(
                            child: Text(
                              'Continue to payment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          AppHugeIcon(
                            HugeIcons.strokeRoundedArrowRight02,
                            size: 16,
                            color: AppColor.text,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.title, required this.active});

  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColor.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? Colors.white : AppColor.neutral2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _StatusTone { error }

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.alertLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.alert.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHugeIcon(
            HugeIcons.strokeRoundedAlert02,
            color: AppColor.alert,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.alert,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
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

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHugeIcon(icon, size: 18, color: AppColor.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
        ],
      ),
    );
  }
}
