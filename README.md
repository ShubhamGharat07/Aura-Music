<p align="center">
  <img src="assets/icons/Auramusiclogo.png" width="160" alt="Aura Music logo" />
</p>

<h1 align="center">Aura Music</h1>

<p align="center">
  <strong>A privacy-first Flutter music player with offline downloads, synced lyrics, and an adaptive glass UI.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img alt="Android" src="https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white" />
  <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-8A2BE2?style=flat-square" />
  <img alt="Status: MVP" src="https://img.shields.io/badge/Status-MVP-FF6F91?style=flat-square" />
</p>

<p align="center">
  <a href="https://github.com/ShubhamGharat07/Aura-Music/releases">
    <img src="https://img.shields.io/badge/Download_APK-Releases-1DB954?style=for-the-badge&logo=android&logoColor=white" alt="Download APK from GitHub Releases" />
  </a>
</p>

> **APK status:** no APK has been published yet. The button above opens the
> [Releases page](https://github.com/ShubhamGharat07/Aura-Music/releases), where
> the first signed build will appear. You can also [build it locally](#build-apk).

Aura Music is an independent Flutter music player for Android. It browses an
unofficial JioSaavn-based catalog, plays audio in the background, keeps a local
library and playlists, downloads music for offline listening, shows lyrics, and
adapts its glass-styled interface from phone to tablet layouts.

It does not require an account and does not include an analytics or
crash-reporting SDK. Library data lives on the device in an encrypted database.
Aura Music is **not affiliated with JioSaavn, Spotify, Apple Music, YouTube, or
any other streaming provider**; see the [disclaimer](DISCLAIMER.md).

## At a glance

| | |
|---|---|
| **Platform** | Android (primary); iOS runner exists but is not production-ready |
| **Version** | `1.0.0+1` |
| **Architecture** | Feature-first Clean Architecture + BLoC/Cubit |
| **Catalog** | Unofficial JioSaavn-based source |
| **Local storage** | Drift + SQLite3 Multiple Ciphers (SQLCipher 4) |
| **License** | [MIT](LICENSE) |

## Features

| Area | What is implemented |
|---|---|
| **Home & discovery** | Quick Picks, Continue Listening, Trending, New Releases, moods/genres, popular artists and albums, playlists, catalog language filters, and offline fallback |
| **Search** | 300 ms debounced search, suggestions, recent searches, grouped results, and filter chips |
| **Playback** | Background playback, media notification and lock-screen controls, queue reorder/remove/clear, shuffle and repeat, play next/append, session restore, playback speed, skip silence, and sleep timer |
| **Library** | Liked songs, listening history, playlist create/edit/delete, and album/artist collections derived from liked songs |
| **Offline downloads** | App-private downloads with a queue, progress/completion notifications, cancel/remove, and Range-based transfer code |
| **Lyrics** | LRCLIB primary with Unison fallback; LRC/TTML parsing |
| **Party mode** | Experimental BLE host/guest queue sync. It does **not** stream audio between devices |
| **Privacy & security** | Encrypted local database, key in platform secure storage, app lock, Android screenshot blocking, Android backup/device-transfer disabled, and no analytics SDK |
| **UI & theming** | Dark glass surfaces, AMOLED option, dynamic accent colors, responsive bottom bar/rail, max-width layouts, and a library master/detail view |
| **Localization** | Partial ARB-based localization; the UI is currently English-first |

## Screenshots

Actual app screenshots are **not checked in yet**. The
[`docs/screenshots/`](docs/screenshots/README.md) folder is prepared for them,
with capture and naming instructions. Once screenshots are added, this section
will show the Home, Search, Player, Library, Downloads, and Settings screens.

## Tech stack

| Layer | Tools and packages |
|---|---|
| **UI** | Flutter, Material 3, `flutter_screenutil`, `palette_generator` |
| **State & architecture** | `flutter_bloc`, `bloc`, `bloc_concurrency`, `equatable`, `flutter_hooks`; feature-first Clean Architecture |
| **DI, routing, errors** | `get_it`, `go_router`, `fpdart` |
| **Local data** | Drift, SQLite3 Multiple Ciphers (`sqlite3mc`), `shared_preferences`, `flutter_secure_storage` |
| **Networking** | Dio, `connectivity_plus`, `cached_network_image` |
| **Audio** | `just_audio`, `audio_service`, `audio_session` |
| **Security & device** | `local_auth`, `permission_handler`, `device_info_plus`, `package_info_plus`, `flutter_local_notifications` |
| **Nearby sessions** | `flutter_blue_plus`, `flutter_ble_peripheral` |
| **Tooling** | `flutter_lints`, `bloc_test`, `mocktail`, `build_runner`, `drift_dev`, `flutter_launcher_icons` |

## Project structure

```text
lib/
  main.dart              # entry point
  bootstrap.dart         # initialization and dependency setup
  app.dart               # app shell and theme wiring
  core/                  # routing, DI, theme, responsive UI, services, errors
  features/              # feature-first Clean Architecture modules
    album/ artist/ catalog/ downloads/ home/ library/ lyrics/
    party/ player/ playlist/ search/ security/ settings/ stream_resolver/
  database/              # Drift schema, DAOs, encrypted database opener
  l10n/                  # ARB catalog and generated localizations

assets/
  icons/                 # Aura Music logo and adaptive foreground
docs/
  screenshots/           # README screenshot drop zone and guide
scripts/                 # local code-rule and tracker checks
test/                    # unit and widget tests
integration_test/        # integration test scaffold
```

Each feature follows the same broad shape where applicable:
`data/` for providers and repositories, `domain/` for entities and use cases,
and `presentation/` for BLoC/Cubit state and widgets.

## Getting started

### Prerequisites

- Flutter stable with Dart `3.10+`
- Android SDK and JDK 17 for Android builds
- A connected Android device or emulator

### Run locally

```bash
git clone https://github.com/ShubhamGharat07/Aura-Music.git
cd Aura-Music

flutter pub get
flutter gen-l10n
flutter analyze lib test
flutter run
```

`flutter gen-l10n` is only needed after editing files under `lib/l10n/`.

## Build APK

```bash
# Universal APK
flutter build apk --release

# Smaller per-ABI APKs
flutter build apk --release --split-per-abi
```

The APK is written to:

```text
build/app/outputs/flutter-apk/
```

> **Before distributing a build:** configure a real release keystore and
> replace the placeholder application ID `com.example.aura_music`. The current
> `release` build type still uses the debug signing configuration.

## Roadmap

These are future improvements, not shipped features:

- [ ] Publish the first signed APK through GitHub Releases
- [ ] Configure release signing and replace placeholder app/package IDs
- [ ] Stabilize download pause, resume, and retry
- [ ] Add equalizer / DSP controls
- [ ] Add backup and restore
- [ ] Expand localization beyond the current partial ARB coverage
- [ ] Finish and verify the iOS configuration
- [ ] Improve BLE discovery reliability in party mode
- [ ] Add real screenshots and store-ready visual assets
- [ ] Expand widget and integration test coverage

<details>
<summary><strong>Known limitations</strong></summary>

- No APK release has been published yet.
- Release builds use debug signing, and the application ID is still
  `com.example.aura_music`.
- Download pause/resume/retry is not reliable yet.
- Party mode is experimental and hardware-dependent; it syncs a queue over BLE
  but does not stream audio.
- The iOS runner is present but unverified and missing some production
  configuration.
- Localization is partial.
- Some widget tests are still being stabilized; `flutter analyze` is clean.
- The catalog uses an unofficial third-party source and can break if that
  source changes.

</details>

## Contributing

1. Fork the repository and create a focused branch.
2. Keep the existing architecture: feature-first `data` / `domain` /
   `presentation`, BLoC/Cubit or `flutter_hooks`, and `go_router` navigation.
3. Do not add analytics/tracker SDKs or commit signing keys, keystores, or
   other secrets.
4. Run the local checks before opening a pull request:

```bash
flutter analyze lib test
flutter test
bash scripts/check_code_rules.sh
bash scripts/check_no_trackers.sh
```

5. Open a pull request describing the problem, the change, and any verification
   you ran. Keep unrelated refactors out of the same PR.

## Privacy and disclaimer

Aura Music is an unofficial project and is not affiliated with any streaming
service or rights holder. You are responsible for having the appropriate rights
to the media you access. The app contacts third-party catalog, artwork, stream,
and lyrics providers to function, and those services may change or become
unavailable. Read the full [DISCLAIMER.md](DISCLAIMER.md) before using or
redistributing the project.

## License

Released under the [MIT License](LICENSE).

## Links

| Resource | Link |
|---|---|
| Repository | [ShubhamGharat07/Aura-Music](https://github.com/ShubhamGharat07/Aura-Music) |
| Releases / APK | [GitHub Releases](https://github.com/ShubhamGharat07/Aura-Music/releases) |
| Issues | [GitHub Issues](https://github.com/ShubhamGharat07/Aura-Music/issues) |
| Screenshot guide | [docs/screenshots](docs/screenshots/README.md) |
| Disclaimer | [DISCLAIMER.md](DISCLAIMER.md) |
