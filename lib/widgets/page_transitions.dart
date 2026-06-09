import 'package:flutter/material.dart';

/// Soft fade + scale route, used for non-Hero pushes (sheets, previews) so the
/// whole app shares one gentle motion language.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required this.page})
      : super(
          opaque: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );

  final Widget page;
}
