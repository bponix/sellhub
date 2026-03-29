import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/custom_button.dart';
import 'package:sellhub/core/widget/custom_text_field.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _key = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          _buildHeader(),
          SizedBox(height: 14.h),
          Row(
            children: const [
              Expanded(
                child: _SecurityHintTile(
                  icon: HugeIcons.strokeRoundedShield01,
                  title: 'Private',
                  subtitle: 'Update securely',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SecurityHintTile(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  title: 'Strong',
                  subtitle: 'Use a fresh password',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InlineLead(
                  icon: HugeIcons.strokeRoundedLock,
                  title: 'Credentials',
                  subtitle: 'Confirm your old password before saving the new one.',
                ),
                SizedBox(height: 16.h),
                CustomTextFormField(
                  labelText: 'Old Password',
                  hintText: 'Enter your old password',
                  controller: _oldPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 15.h),
                CustomTextFormField(
                  labelText: 'New Password',
                  hintText: 'Create a strong password',
                  controller: _newPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 15.h),
                CustomTextFormField(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-type your new password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != _newPasswordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    buttonName: 'Save New Password',
                    onTap: () async {
                      if (_key.currentState!.validate()) {
                        final cubit = context.read<ProfileCubit>();
                        final userId = await LocalStorage.getUserID() ?? 0;
                        final oldPassword = _oldPasswordController.text.trim();
                        final newPassword = _newPasswordController.text.trim();
                        final result = await cubit.passwordChange(
                          userId,
                          oldPassword,
                          newPassword,
                        );
                        _oldPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                        if (result) {
                          CustomToast.info('Password Change Successfully');
                        } else {
                          CustomToast.error('Failed to Password change');
                        }
                      }
                    },
                    iconData: Icons.shield_rounded,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: AppHugeIcon(
              HugeIcons.strokeRoundedShield01,
              size: 20.r,
              color: AppColor.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security update',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Use a unique password so your account, orders, and profile stay protected.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.neutral2,
                    height: 1.4,
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

class _SecurityHintTile extends StatelessWidget {
  const _SecurityHintTile({
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppHugeIcon(icon, size: 16.r, color: AppColor.primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
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

class _InlineLead extends StatelessWidget {
  const _InlineLead({
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
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: AppHugeIcon(icon, size: 15.r, color: AppColor.primary),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColor.text,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral2,
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
