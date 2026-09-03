import 'package:flutter/material.dart';

/// Responsive Phone Frame that wraps the application.
/// On desktop and wide screens (>430px), renders a centered mobile phone frame with rounded corners and shadow.
/// On narrow mobile screens (<=430px), fills the full viewport seamlessly.
class ResponsivePhoneFrame extends StatelessWidget {
  final Widget child;

  const ResponsivePhoneFrame({super.key, required this.child});

  static const double maxMobileWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isDesktopOrTablet = screenWidth > maxMobileWidth;

        if (!isDesktopOrTablet) {
          // Native mobile screen: render full width & height
          return child;
        }

        final bool hasVerticalMargin = screenHeight > 840;

        // Desktop / Tablet web: render centered mobile phone mockup
        return Container(
          color: const Color(0xFFE2E8F0), // Clean neutral slate backdrop
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: maxMobileWidth,
            ),
            margin: hasVerticalMargin
                ? const EdgeInsets.symmetric(vertical: 20)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(hasVerticalMargin ? 28 : 0),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(
                  maxMobileWidth,
                  hasVerticalMargin ? screenHeight - 40 : screenHeight,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
