// Smooth page transitions for every MaterialPageRoute (navigation code is untouched — the theme
// supplies the animation). Incoming page: fade + short upward slide; outgoing page: slight fade
// and scale-back, so pushes and pops feel continuous.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MahadPageTransitionsBuilder extends PageTransitionsBuilder {
  const MahadPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.85).animate(exit),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.97).animate(exit),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

const mahadPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: MahadPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);
