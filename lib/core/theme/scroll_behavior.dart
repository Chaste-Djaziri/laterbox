import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Customized scroll behavior for desktop, web, and mobile that enables smooth
/// momentum scrolling, drag-to-scroll on trackpads and mice, and smooth physics.
class LaterBoxScrollBehavior extends MaterialScrollBehavior {
  const LaterBoxScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
