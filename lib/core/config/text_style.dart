import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';

class kTextStyle {
  static final kTextStyle _instance = kTextStyle._internal();
  factory kTextStyle() => _instance;
  kTextStyle._internal();

  static final TextStyle itemHead = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: Colors.black,
  );
  static final TextStyle itemSeeAll = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColor.grey,
  );
}
