<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="112" height="112" alt="Aura Music logo" />
</p>

<h1 align="center">Aura Music</h1>

<p align="center">
  An open-source Android music player with synced lyrics, offline playback, and a library that lives on your device.
</p>

<p align="center">
  <strong><a href="https://github.com/ShubhamGharat07/Aura-Music/releases/latest/download/app-arm64-v8a-release.apk">Download APK (Android ARM64)</a></strong>
  · <a href="https://github.com/ShubhamGharat07/Aura-Music/releases/latest">Latest release notes</a>
  · <a href="https://github.com/ShubhamGharat07/Aura-Music/releases">All releases</a>
</p>

## Features

- **Discovery** with Top Picks, charts, language filters, and search across songs, albums, artists, playlists, and podcasts.
- **Playback** with background and lock-screen controls, queue management, synced lyrics when available, an equalizer, and a sleep timer.
- **On-device library** with liked songs, custom playlists, listening history, and offline playback for tracks you are permitted to download.
- **Personalization** with layouts for phones and tablets, dynamic colors, and optional app lock.

## Install and update

- **First install.** Download the signed APK on an ARM64 Android device and open it. Android may ask you to allow installation from your browser or file manager.
- **Updates.** In v2.0.1 or later, use **Settings → Updates → Check for updates**. The app checks the downloaded APK’s size and SHA-256 hash before opening Android’s installer.
- **Upgrading from before v2.0.1.** The Android package ID changed in v2.0.1. The current APK installs separately, and your existing library stays with the old installation.

## Privacy and media rights

Aura Music requires no account and includes no analytics or crash-reporting SDK. Your library is stored in an encrypted on-device database. Features such as search, playback, lyrics, and update checks make network requests.

Aura Music is independently developed. Third-party media remains subject to provider terms and rights-holder permissions. Only access or download media where you have permission. [Privacy, media rights, and reporting](DISCLAIMER.md)

The source code is available under the MIT License. [License](LICENSE)

<details>
<summary><strong>Build and contribute</strong></summary>

Use Flutter **3.47.7**, JDK 17, and Android SDK Platform 37. Run these commands from the repository root with an Android device or emulator connected.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

For issues and contributions, include reproduction steps or a summary of your change and the checks you ran. [Issues](https://github.com/ShubhamGharat07/Aura-Music/issues) · [Release workflow](.github/workflows/release.yml)

</details>
