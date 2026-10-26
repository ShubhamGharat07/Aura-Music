#!/usr/bin/env bash
# PRD 9.1 tracker gate. Fails if any analytics/tracker SDK is locked.
# Run: bash scripts/check_no_trackers.sh
set -euo pipefail

trackers='firebase_analytics|firebase_crashlytics|sentry|mixpanel|amplitude|appsflyer|facebook_app_events|adjust|clevertap|posthog'
if [ ! -f pubspec.lock ]; then
  echo 'pubspec.lock missing, skipping tracker check.'
  exit 0
fi
if grep -Ei "$trackers" pubspec.lock; then
  echo 'TRACKER GATE FAILED: analytics/tracker package in pubspec.lock.'
  exit 1
fi
echo 'Tracker gate passed (no analytics SDKs).'
