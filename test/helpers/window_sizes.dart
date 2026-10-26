import 'package:flutter/widgets.dart';

/// PRD 12.1 responsive matrix (logical px).
const List<Size> kWindowSizes = [
  Size(360, 640), // small phone
  Size(393, 852), // reference phone
  Size(412, 915), // large phone
  Size(852, 393), // phone landscape (compact height)
  Size(600, 960), // small tablet / foldable portrait
  Size(744, 1133), // 8-9" tablet portrait
  Size(1194, 834), // 11" tablet landscape
  Size(1600, 900), // large tablet / freeform
];
