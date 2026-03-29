import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sellhub/core/constants/app_color.dart';

class CustomToast {
  static void success(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppColor.green,
      textColor: Colors.white,
    );
  }

  static void info(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppColor.green,
      textColor: Colors.white,
    ); //gravity: ToastGravity.TOP
  }

  static void error(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
