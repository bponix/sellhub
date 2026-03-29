import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sellhub/core/constants/app_color.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword; // obscureText logic er jonno
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 15.sp,
        color: AppColor.text,
        fontWeight: FontWeight.w600,
      ),

      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: AppColor.neutral1),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          color: AppColor.neutral2,
          fontWeight: FontWeight.w700,
        ),

        prefixIcon: widget.prefixIcon != null
            ? Container(
                margin: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  widget.prefixIcon,
                  size: 18.sp,
                  color: AppColor.primary,
                ),
              )
            : null,

        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20.sp,
                  color: AppColor.neutral2,
                ),
              )
            : null,

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: _buildBorder(AppColor.safe),
        enabledBorder: _buildBorder(AppColor.safe),
        focusedBorder: _buildBorder(AppColor.primary),
        errorBorder: _buildBorder(AppColor.alert),
        focusedErrorBorder: _buildBorder(AppColor.alert),
      ),

      validator:
          widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '${widget.labelText} is required';
            }
            return null;
          },
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}
