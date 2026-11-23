import 'package:flutter/material.dart';

/// Shared [Hero] wrapper for artwork transitions.
///
/// Uses a centred arc instead of a straight line, which makes a card grow into
/// a page header along a natural path rather than sliding under the finger.
/// The tag must be unique among the widgets built on the current screen; call
/// sites that can render the same entity twice (e.g. two playlist rails) use a
/// distinct tag or skip the hero.
final class AuraHero extends StatelessWidget {
  /// Creates an artwork hero.
  const AuraHero({super.key, required this.tag, required this.child});

  /// Unique hero tag (matches the destination's tag).
  final Object tag;

  /// Artwork subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !(MediaQuery.maybeDisableAnimationsOf(context) ?? false),
    child: Hero(
      tag: tag,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      flightShuttleBuilder: (_, _, direction, from, to) {
        // Reuse the card's cached bitmap in both directions.
        final card = direction == HeroFlightDirection.push ? from : to;
        return (card.widget as Hero).child;
      },
      child: child,
    ),
  );
}
