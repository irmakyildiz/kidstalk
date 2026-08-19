import 'package:flutter/material.dart';

/// Helper utility for responsive font scaling, padding, and layout breakpoints.
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1050;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1050;

  /// Returns a responsive font size based on screen width.
  static double fontSize(BuildContext context, double baseSize) {
    final double width = MediaQuery.of(context).size.width;
    double scale = 1.0;
    if (width < 400) {
      scale = 0.78;
    } else if (width < 650) {
      scale = 0.85;
    } else if (width < 950) {
      scale = 0.92;
    }

    final double minSize = baseSize * 0.72;
    return (baseSize * scale).clamp(minSize, baseSize);
  }

  /// Returns responsive EdgeInsets padding.
  static EdgeInsets padding(
    BuildContext context, {
    double desktop = 24.0,
    double tablet = 16.0,
    double mobile = 12.0,
  }) {
    final double width = MediaQuery.of(context).size.width;
    if (width < 650) {
      return EdgeInsets.all(mobile);
    } else if (width < 1050) {
      return EdgeInsets.all(tablet);
    }
    return EdgeInsets.all(desktop);
  }
}
