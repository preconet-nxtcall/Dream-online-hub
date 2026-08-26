import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Adaptive Layout Switcher Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.mobile &&
      MediaQuery.of(context).size.width < AppBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive Helper Extensions on BuildContext
extension ResponsiveExtension on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < AppBreakpoints.mobile;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= AppBreakpoints.mobile &&
      MediaQuery.of(this).size.width < AppBreakpoints.tablet;
  bool get isDesktop => MediaQuery.of(this).size.width >= AppBreakpoints.tablet;

  /// Returns a responsive value based on current device screen width
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}
