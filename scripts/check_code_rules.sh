#!/usr/bin/env bash
# PRD 4.3 code-rules gate. Fails the build on banned patterns.
# Run: bash scripts/check_code_rules.sh
set -euo pipefail

fail=0
flag() { echo "RULE VIOLATION: $1"; fail=1; }

# Generated sources (drift, freezed, json) are excluded from all rules.
GEN_EXCLUDES=(--exclude='*.g.dart' --exclude='*.freezed.dart' --exclude='*.drift.dart' --exclude='*.mocks.dart')

# 1. setState is forbidden everywhere in lib/.
if grep -rn 'setState(' lib/ --include='*.dart' "${GEN_EXCLUDES[@]}"; then
  flag 'setState( found in lib/ (use BLoC/flutter_hooks/ValueNotifier)'
fi

# 2. StatefulWidget is forbidden (no allow-list yet).
if grep -rn 'extends StatefulWidget\|extends State<' lib/ --include='*.dart' "${GEN_EXCLUDES[@]}"; then
  flag 'StatefulWidget found in lib/ (use StatelessWidget/HookWidget)'
fi

# 3. Navigator.of outside core/router.
if grep -rn 'Navigator\.of(context)' lib/ --include='*.dart' "${GEN_EXCLUDES[@]}" | grep -v 'lib/core/router/'; then
  flag 'Navigator.of(context) outside lib/core/router/ (use go_router)'
fi

# 4. dio/drift imports inside presentation/ or domain/.
if grep -rn 'package:dio/\|package:drift/' lib/ --include='*.dart' "${GEN_EXCLUDES[@]}" | grep -E 'presentation/|domain/'; then
  flag 'dio/drift import inside presentation/ or domain/ (data layer only)'
fi

# 5. print() (use Logger).
if grep -rn '(^|[^a-zA-Z_])print(' lib/ --include='*.dart' "${GEN_EXCLUDES[@]}"; then
  flag 'print( found in lib/ (use Logger)'
fi

# 6. File size: warn > 300 lines, fail > 400 lines.
# Allow-list: data-dense constants that cannot be split without hurting
# readability (each entry must carry a justification).
is_large_allowed() {
  case "$1" in
    lib/core/utils/des_ecb.dart) return 0 ;; # DES permutation/S-box tables
    *) return 1 ;;
  esac
}

while IFS= read -r f; do
  if is_large_allowed "$f"; then
    echo "WARNING: $f is allow-listed for size ($(wc -l < "$f") lines)"
    continue
  fi
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 400 ]; then
    flag "$f has $lines lines (> 400)"
  elif [ "$lines" -gt 300 ]; then
    echo "WARNING: $f has $lines lines (> 300)"
  fi
done < <(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.drift.dart' ! -name '*.mocks.dart')

if [ "$fail" -ne 0 ]; then
  echo 'Code rules FAILED.'
  exit 1
fi
echo 'Code rules passed.'
