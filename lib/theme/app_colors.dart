import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF006552);
  static const Color primaryContainer = Color(0xFF008069);
  static const Color primaryVivid = Color(0xFF00C896);

  static const Color background = Color(0xFFF4FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFE8F6FF);
  static const Color surfaceContainer = Color(0xFFDFF1FC);

  static const Color bubbleOut = Color(0xFFE7F3F0);
  static const Color bubbleIn = Color(0xFFFFFFFF);
  static const Color bubbleBorder = Color(0xFFBDC9C4);

  static const Color onBackground = Color(0xFF0C1E26);
  static const Color onSurfaceVariant = Color(0xFF3E4945);
  static const Color outline = Color(0xFF6E7A75);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color unreadBadge = Color(0xFF006552);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A388), Color(0xFF005E4C)],
  );

  static const LinearGradient vividGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E0B8), Color(0xFF008069)],
  );

  static const LinearGradient bubbleOutGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A388), Color(0xFF00785F)],
  );
}
