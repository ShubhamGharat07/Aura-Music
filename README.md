<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="176" height="176" alt="Aura Music logo" />
</p>

<h1 align="center">Aura Music</h1>

<p align="center">
  An open-source music player for Android. Explore music and podcasts, follow along with synced lyrics, and keep your library on your device.
</p>

<p align="center">
  <a href="https://github.com/ShubhamGharat07/Aura-Music/releases/latest/download/app-arm64-v8a-release.apk">
    <img src="https://img.shields.io/badge/Download_APK-Android_ARM64-6946D4?style=for-the-badge&amp;logo=android&amp;logoColor=white&amp;labelColor=261D3B" alt="Download the signed Android ARM64 APK" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/ShubhamGharat07/Aura-Music/releases/latest">Latest release notes and assets</a>
  · <a href="https://github.com/ShubhamGharat07/Aura-Music/releases">Version history</a>
</p>

## Features

- **Music discovery.** Browse Top Picks, charts, new and trending albums, moods, curated playlists, and podcasts. Filter discovery by language.
- **Search.** Find songs, albums, artists, playlists, and podcasts with suggestions, recent searches, and result filters.
- **Playback.** Listen in the background with media notification and lock-screen controls. Play a track next, reorder the queue, shuffle or repeat, and return to your previous playback session.
- **Lyrics and audio controls.** Follow synced lyrics when available, adjust playback speed, skip silence, tune the five-band equalizer, or set a sleep timer.
- **Library and offline listening.** Like songs, create playlists, and revisit your listening history. Save permitted tracks for offline playback and manage their progress in Downloads.
- **Appearance.** Use a glass interface that adapts to phones and tablets, with artwork-based accent colors and an AMOLED black option.
- **Party Mode (experimental).** Host or join a nearby Bluetooth session where a guest device follows the host’s queue and playback position. Each device plays audio independently.

## Install and update

Download the signed APK above on an ARM64 Android device and open it. If prompted, allow Android to install the file from your browser or file manager.

On **v2.0.1 or later**, open **Settings → Updates → Check for updates**. The app shows release notes, supports background downloads with progress notifications, and lets you control automatic checks and update alerts.

The Android package ID changed in v2.0.1. If you’re upgrading from an older build, the new APK installs separately and your library stays in the old installation.

### How OTA updates are verified

1. **Release and compatibility.** The updater reads the latest stable GitHub release and matches its manifest to a compatible APK with a newer Android build number.
2. **Download integrity.** The app stores the APK privately and checks its exact file size and SHA-256 hash against the release manifest.
3. **App identity and signing.** The Android code checks that the APK’s package ID and signing certificate match the installed app and that its build number matches the offered update. Android’s installer opens for user confirmation only after these checks pass.

GitHub Actions publishes the signed ARM64 APK together with its OTA manifest. [Release workflow](.github/workflows/release.yml)

## Privacy and security

- **Local library.** Likes, playlists, and listening history are stored in an encrypted on-device database. The database key is kept in platform secure storage, and offline audio is saved in app-private storage.
- **Device controls.** Lock the app with biometrics or your device screen lock, block screenshots on Android, pause listening history, or clear local app data in Settings.
- **Network use.** Aura Music requires no account and includes no analytics or crash-reporting SDK. Search, playback, artwork, lyrics, and update checks make network requests. [Privacy and permissions](DISCLAIMER.md#privacy-and-permissions)

## Tech stack

| Area | Implementation |
| --- | --- |
| Interface | Flutter, Dart, Material 3 |
| Architecture | Feature-first Clean Architecture with `presentation`, `domain`, and `data` layers where applicable |
| State management | BLoC and Cubit with `flutter_bloc` |
| Navigation and dependency injection | `go_router` and `get_it` |
| Audio | `just_audio`, `audio_service`, and `audio_session` |
| Local data and security | Drift, SQLite3 Multiple Ciphers in SQLCipher-compatible mode, `flutter_secure_storage`, and `local_auth` |
| Android and releases | Kotlin for native installer checks, Gradle for Android builds, and GitHub Actions for CI and signed release publishing |

## Build from source

Use Flutter **3.47.7**, JDK 17, and Android SDK Platform 37. Run these commands from the repository root with an Android device or emulator connected.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Include reproduction steps when reporting a bug. For a pull request, summarize the change and the checks you ran. [GitHub issues](https://github.com/ShubhamGharat07/Aura-Music/issues)

## License and media rights

Aura Music is independently developed. Third-party media remains subject to provider terms and rights-holder permissions. Only access or download media where you have permission. [Privacy, media rights, and reporting](DISCLAIMER.md)

The source code is available under the MIT License. [License](LICENSE)
