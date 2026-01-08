import 'package:flutter/material.dart';

class HeroText extends StatelessWidget {
  final String tag;
  final Widget child;

  const HeroText({super.key, required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      // Material wrapper prevents text layout jank during flight
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromCtx, toCtx) {
        final toHero = toCtx.widget as Hero;
        return FadeTransition(
          opacity: animation.drive(Tween(begin: 0.6, end: 1.0)),
          child: toHero.child,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
