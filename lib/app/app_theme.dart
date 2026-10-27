import 'package:flutter/material.dart';

import 'constants/app_colors.dart';

class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.teal,
    scaffoldBackgroundColor: AppColors.background,
  );
}
