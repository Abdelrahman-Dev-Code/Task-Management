import 'package:flutter/material.dart';

/// أدوات التجاوب لتكييف التخطيط بسلاسة على الجوال والتابلت وسطح المكتب والويب
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 650;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 650 && width < 1080;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1080;

  static int taskGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 3;
    if (width >= 760) return 2;
    return 1;
  }
}
