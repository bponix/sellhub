import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_state.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SellHubTopAppBar(
        title: 'Addresses',
        icon: HugeIcons.strokeRoundedMapsLocation01,
        showBackButton: true,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final shipping = state.shippingAddresses;
          final billing = state.billingAddresses;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                          HugeIcons.strokeRoundedMapsLocation01,
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
                              'Address book',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColor.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Manage separate delivery and billing addresses for checkout.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColor.neutral2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (state.addressActionInFlight)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: AppColor.text,
                    unselectedLabelColor: AppColor.neutral2,
                    tabs: [
                      Tab(text: 'Shipping (${shipping.length})'),
                      Tab(text: 'Billing (${billing.length})'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AddressListTab(
                      addresses: shipping,
                      emptyTitle: 'No shipping address yet',
                      emptySubtitle:
                          'Add a delivery address to speed up checkout.',
                      onAdd: () => _openAddressEditor(
                        context,
                        type: _AddressType.shipping,
                      ),
                      onRemove: (address) => _removeAddress(
                        context,
                        type: _AddressType.shipping,
                        address: address,
                      ),
                    ),
                    _AddressListTab(
                      addresses: billing,
                      emptyTitle: 'No billing address yet',
                      emptySubtitle:
                          'Add a billing address for invoice and payment records.',
                      onAdd: () => _openAddressEditor(
                        context,
                        type: _AddressType.billing,
                      ),
                      onRemove: (address) => _removeAddress(
                        context,
                        type: _AddressType.billing,
                        address: address,
                      ),
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

  Future<void> _openAddressEditor(
    BuildContext context, {
    required _AddressType type,
  }) async {
    final result = await showModalBottomSheet<_AddressDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddressEditorSheet(type: type),
    );
    if (result == null || !context.mounted) return;
    final siteId = context.read<StorefrontCubit>().state.siteDetails?.id ?? 0;
    final address = StoreCustomerAddressModel(
      id: DateTime.now().millisecondsSinceEpoch,
      address: result.address,
      formattedAddress: result.formattedAddress,
      latitude: 0,
      longitude: 0,
    );
    final cubit = context.read<ProfileCubit>();
    final success = type == _AddressType.shipping
        ? await cubit.addShippingAddress(siteId: siteId, address: address)
        : await cubit.addBillingAddress(siteId: siteId, address: address);
    if (!context.mounted) return;
    if (success) {
      CustomToast.success('Address saved');
    } else {
      CustomToast.error('Unable to save address');
    }
  }

  Future<void> _removeAddress(
    BuildContext context, {
    required _AddressType type,
    required StoreCustomerAddressModel address,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove address'),
          content: Text(
            'Remove this ${type == _AddressType.shipping ? 'shipping' : 'billing'} address?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final siteId = context.read<StorefrontCubit>().state.siteDetails?.id ?? 0;
    final cubit = context.read<ProfileCubit>();
    final success = type == _AddressType.shipping
        ? await cubit.removeShippingAddress(siteId: siteId, address: address)
        : await cubit.removeBillingAddress(siteId: siteId, address: address);
    if (!context.mounted) return;
    if (success) {
      CustomToast.info('Address removed');
    } else {
      CustomToast.error('Unable to remove address');
    }
  }
}

enum _AddressType { shipping, billing }

class _AddressListTab extends StatelessWidget {
  const _AddressListTab({
    required this.addresses,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onAdd,
    required this.onRemove,
  });

  final List<StoreCustomerAddressModel> addresses;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onAdd;
  final ValueChanged<StoreCustomerAddressModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const AppHugeIcon(
              HugeIcons.strokeRoundedAdd01,
              size: 16,
              color: Colors.white,
            ),
            label: const Text('Add address'),
          ),
        ),
        const SizedBox(height: 14),
        if (addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              children: [
                const AppHugeIcon(
                  HugeIcons.strokeRoundedMapsLocation01,
                  size: 32,
                  color: AppColor.neutral2,
                ),
                const SizedBox(height: 12),
                Text(
                  emptyTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...addresses.map(
            (address) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColor.safe),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const AppHugeIcon(
                      HugeIcons.strokeRoundedMapsLocation01,
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
                          address.formattedAddress.trim().isNotEmpty
                              ? address.formattedAddress.trim()
                              : address.address.trim(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (address.address.trim().isNotEmpty &&
                            address.address.trim() !=
                                address.formattedAddress.trim()) ...[
                          const SizedBox(height: 4),
                          Text(
                            address.address.trim(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColor.neutral2,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(address),
                    icon: const AppHugeIcon(
                      HugeIcons.strokeRoundedDelete02,
                      size: 18,
                      color: AppColor.alert,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AddressDraft {
  const _AddressDraft({required this.address, required this.formattedAddress});

  final String address;
  final String formattedAddress;
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({required this.type});

  final _AddressType type;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.type == _AddressType.shipping
        ? 'Add shipping address'
        : 'Add billing address';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep the first line short and the details line complete for checkout.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Short label',
                hintText: 'Home, Office, Apartment 4B',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a short address label';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Full address',
                hintText: 'House, road, area, city, delivery notes',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the full address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(
                    _AddressDraft(
                      address: _detailsController.text.trim(),
                      formattedAddress: _labelController.text.trim(),
                    ),
                  );
                },
                child: const Text('Save address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
