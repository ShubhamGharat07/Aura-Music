import 'package:flutter/widgets.dart';

/// Master-detail two-pane with fixed ratios (PRD 7.2, e.g. 35/65).

/// Two-pane master-detail. [masterFlex]/[detailFlex] set the ratio.
final class TwoPane extends StatelessWidget {
  /// Creates a two-pane layout.
  const TwoPane({
    super.key,
    required this.master,
    required this.detail,
    this.masterFlex = 35,
    this.detailFlex = 65,
    this.spacing = 24,
  });

  /// Left / master pane.
  final Widget master;

  /// Right / detail pane.
  final Widget detail;

  /// Flex weights.
  final int masterFlex;

  /// Flex weights.
  final int detailFlex;

  /// Gap between panes.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: masterFlex, child: master),
        SizedBox(width: spacing),
        Expanded(flex: detailFlex, child: detail),
      ],
    );
  }
}
