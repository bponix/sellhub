import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/profile/screens/widget/header_reseller_login.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';

import '../../../core/constants/app_color.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';

const List<String> list = <String>['Bkash', 'Nagad', 'Rocket', 'Bank'];
typedef MenuEntry = DropdownMenuEntry<String>;

class ResellerScreen extends StatefulWidget {
  const ResellerScreen({
    super.key,
    required TextEditingController nameController,
    required TextEditingController paymentNoController,
    required this.formkey,
  }) : _nameController = nameController,
       _paymentNoController = paymentNoController;

  final TextEditingController _nameController;
  final TextEditingController _paymentNoController;
  final GlobalKey<FormState> formkey;

  @override
  State<ResellerScreen> createState() => _ResellerScreenState();
}

class _ResellerScreenState extends State<ResellerScreen> {
  static final List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    list.map<MenuEntry>(
      (String name) => MenuEntry(value: name, label: name, enabled: false),
    ),
  );
  String dropdownValue = list.first;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formkey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResellerBecome_header(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: _ResellerQuickRow(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: CustomTextFormField(
                  controller: widget._nameController,
                  hintText: 'Enter your shop name',
                  labelText: 'Shop Name',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: DropdownMenu<String>(
                  width: double.infinity,
                  initialSelection: list.first,
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    fillColor: AppColor.safe1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColor.safe),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColor.safe),
                    ),
                  ),
                  onSelected: (String? value) {
                    setState(() {
                      dropdownValue = value!;
                    });
                  },
                  dropdownMenuEntries: menuEntries,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _ResellerInlineLead(
                  icon: HugeIcons.strokeRoundedWallet02,
                  title: 'Payout details',
                  subtitle:
                      'Use the number where you want to receive reseller payments.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomTextFormField(
                  controller: widget._paymentNoController,
                  hintText: 'Enter payment no',
                  labelText: 'Payment NO',
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    buttonName: 'Request for reselling',
                    onTap: () async {
                      if (widget.formkey.currentState!.validate()) {
                        final cubit = context.read<ProfileCubit>();
                        final userId = await LocalStorage.getUserID() ?? 0;
                        final result = await cubit.makeResellerRequest(
                          userId,
                          userId,
                          widget._nameController.text.trim(),
                          'dxfcx',
                          widget._paymentNoController.text.trim(),
                        );
                        if (result) {
                          CustomToast.info('Successfully Make Reseller');
                        } else {
                          CustomToast.error('Failed to Create Reseller');
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResellerQuickRow extends StatelessWidget {
  const _ResellerQuickRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ResellerHintTile(
            icon: HugeIcons.strokeRoundedPackage,
            title: 'Bulk access',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ResellerHintTile(
            icon: HugeIcons.strokeRoundedWallet02,
            title: 'Payout ready',
          ),
        ),
      ],
    );
  }
}

class _ResellerHintTile extends StatelessWidget {
  const _ResellerHintTile({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppHugeIcon(icon, size: 16, color: AppColor.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColor.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResellerInlineLead extends StatelessWidget {
  const _ResellerInlineLead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppHugeIcon(icon, size: 15, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
