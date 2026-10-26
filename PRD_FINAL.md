# PRD v2.0 (FINAL) — "Aura Music" (working title)

> Flutter music streaming client · Liquid Glass UI · Clean Architecture + BLoC · Offline-first · Privacy-first
> **Phone + Tablet + Foldable + Landscape** adaptive · **Zero `setState`** · Platform: Android first
> Reference app (features only, no code copied): Vivi-Music

---

## 0. What Changed vs v1.0

| # | Change |
|---|---|
| 1 | **Adaptive/responsive system added** (Section 7): 4 window size classes, adaptive navigation (bottom bar → rail → rail + panels), two-pane layouts, per-screen tablet specs, orientation + foldable handling |
| 2 | **`setState` is banned** (Section 4): BLoC/Cubit for app state, `flutter_hooks` for ephemeral UI state, `ValueNotifier` for high-frequency streams. CI fails the build on `setState(` |
| 3 | **Code-quality contract** (Section 5): file size, naming, layering rules, review checklist, lint config |
| 4 | **Package decisions locked** (Section 2 + Decision Log) |
| 5 | **Liquid-glass approach corrected**: own `GlassSurface` is the base. `liquid_glass_renderer` is **experimental** (its README says do not add blindly to production for all devices), so it is optional, high-tier-only, removable |
| 6 | **Responsive testing matrix** (Section 12): goldens + overflow tests at 8 sizes |
| 7 | Project structure updated (`core/responsive`, `core/hooks`, `scripts/check_code_rules`) |
| 8 | API source list finalised (see `API_LIST.md`) |

### Decision Log (locked)
| Topic | Decision | Reason |
|---|---|---|
| State mgmt | `flutter_bloc` (+ `bloc_concurrency`) | Required, testable, event-driven |
| Ephemeral UI state | `flutter_hooks` | Removes `StatefulWidget` + `setState` while still allowing controllers/animations |
| High-frequency state (position, drag) | `ValueNotifier` + `ValueListenableBuilder` / `ValueListenable` streams | Avoids rebuilding whole screens 10×/s |
| Adaptive layout | **Own** `AdaptiveShell` + `WindowSizeClass` (no `flutter_adaptive_scaffold`) | Fewer dependencies, full control, no abandoned-package risk |
| Scaling | `flutter_screenutil` with **design size per window class** + max content width clamp | Required; avoids "giant UI" on tablets |
| Glass | Own `GlassSurface` (BackdropFilter + fake glass) base; `liquid_glass_renderer` optional hero-only (High tier) | Performance + stability |
| Router | `go_router` + `StatefulShellRoute` | Keeps per-tab stacks, works for rail and bar |
| DB | `drift` + SQLCipher | Encrypted, reactive streams |
| Audio | `just_audio` + `audio_service` | Gapless, EQ, background |
| Streams | `youtube_explode_dart` primary, fallbacks per `API_LIST.md` | |
| Lyrics | LRCLIB | Free, synced |
| Updates | GitHub Releases | Free |

---

## 1. Product Overview

### 1.1 Vision
A premium, ad-free, privacy-first music player with a modern, professional Liquid Glass look (never cartoonish) that feels identical in quality on a 5.5" phone, a foldable and a 12" tablet, and never stutters.

### 1.2 Goals
| # | Goal | Measure |
|---|------|---------|
| G1 | Feature parity with Vivi-Music | Section 3 checklist 100% |
| G2 | Smooth | p95 frame time < 12 ms @60 Hz, < 6 ms @120 Hz (profile mode), on phone **and** tablet reference devices |
| G3 | Fully adaptive | Every screen verified at 8 sizes (Section 12), **0 overflow errors**, no stretched phone UI on tablets |
| G4 | Privacy | 0 analytics/trackers, all data local |
| G5 | Offline | Library, downloads, cached tracks usable with no network |
| G6 | Code quality | Domain coverage ≥ 90%, overall ≥ 80%, `flutter analyze` = 0, **0 `setState`** |

### 1.3 Non-Goals (v1)
No own backend/accounts/cloud sync · no iOS build · no Android Auto/Chromecast · no video · no IAP · no desktop/web build (layout code stays desktop-ready).

### 1.4 Legal & Reality Check
1. Streaming source is unofficial (YouTube extraction violates ToS). Sideload distribution only. Play Store would reject.
2. Unofficial APIs break; every source sits behind a repository with a fallback chain.
3. Vivi-Music/Convx/Harmony are GPL. We take **ideas only**, no code.
4. "Zero jank" = measurable budget (Section 10), not a promise. Blur is rationed.
5. Verify package versions on pub.dev when writing `pubspec.yaml`.

---

## 2. Tech Stack

| Concern | Package | Notes |
|---|---|---|
| State (app/business) | `flutter_bloc`, `bloc`, `bloc_concurrency`, `equatable` | `restartable()` for search, `droppable()` for taps, `sequential()` for queue ops |
| State (ephemeral UI) | `flutter_hooks` | `useState`, `useAnimationController`, `useScrollController`, `useTextEditingController`, `useFocusNode` |
| Architecture | Clean Architecture (data / domain / presentation) | |
| DI | `get_it`, `injectable` (+generator) | |
| Errors | `fpdart` (`Either<Failure, T>`) | |
| Models | `freezed`, `json_serializable`, `build_runner` | Sealed events/states |
| Networking | `dio` | retry + timeouts interceptors |
| Routing | `go_router` | |
| Responsive scaling | `flutter_screenutil` | + own `core/responsive` (Section 7) |
| Audio | `just_audio`, `audio_service`, `audio_session` | |
| Sources | `youtube_explode_dart`, `ytmusicapi_dart` / `dart_ytmusic_api`, own InnerTube client, optional `saavn_play` | See `API_LIST.md` |
| Lyrics | LRCLIB via `dio` | |
| DB | `drift`, `sqlcipher_flutter_libs` | |
| Secure storage | `flutter_secure_storage` | DB key, tokens |
| Prefs | `shared_preferences` | Wrapped by `SettingsRepository` (never read in widgets) |
| Downloads | `background_downloader` | |
| Images | `cached_network_image`, `flutter_cache_manager` | |
| Colour | `palette_generator` (isolate) | |
| Glass | Own `GlassSurface`; optional `liquid_glass_renderer` (experimental, High tier only) | |
| Animation | `flutter_animate`, implicit animations first | |
| Icons | `phosphor_flutter` | |
| Fonts | Inter bundled | offline |
| Network state | `connectivity_plus` | |
| OTA | GitHub API + `background_downloader` + `open_filex` + `crypto` | |
| App lock | `local_auth` | |
| Device | `device_info_plus`, `package_info_plus`, `permission_handler`, `share_plus` | |
| Lint | `very_good_analysis` + CI rule script (Section 5) | |
| Test | `flutter_test`, `bloc_test`, `mocktail`, `alchemist`, `integration_test` | |
| CI | GitHub Actions | |

---

## 3. Features (Vivi parity + improvements)

P0 = MVP · P1 = v1.0 · P2 = later

| ID | Feature | Vivi | Pri |
|---|---|---|---|
| F01 | Ad-free streaming (YT / YT Music) with fallback chain | ✔ | P0 |
| F02 | Search (songs/albums/artists/playlists) + suggestions | ✔ | P0 |
| F03 | Background playback, notification + lock-screen controls | ✔ | P0 |
| F04 | Full player: seek, next/prev, shuffle, repeat, like | ✔ | P0 |
| F05 | Queue (reorder, remove, play next, add) | ✔ | P0 |
| F06 | Dynamic colour from album art | ✔ | P0 |
| F07 | Liquid Glass UI + micro-animations | ✔ | P0 |
| F08 | Library: liked, playlists, history | ✔ | P0 |
| F09 | Artist / Album / Playlist pages | ✔ | P0 |
| F10 | **Adaptive layouts: phone, tablet, foldable, landscape** | – | P0 |
| F11 | Synced lyrics (line) | ✔ | P1 |
| F12 | Downloads for offline | ✔ | P1 |
| F13 | Smart cache with LRU eviction | ✔ | P1 |
| F14 | Equalizer + loudness | ✔ | P1 |
| F15 | OTA updater | ✔ | P1 |
| F16 | Zero telemetry (CI-enforced) | ✔ | P0 |
| F17 | Sleep timer | – | P1 |
| F18 | Encrypted backup/restore | – | P1 |
| F19 | Crossfade / gapless / speed | – | P1 |
| F20 | App lock (biometric) | – | P1 |
| F21 | Word-by-word lyrics | ✔ | P2 |
| F22 | Animated canvas backdrop | ✔ | P2 |
| F23 | Import playlist by link | – | P2 |
| F24 | Home widget | – | P2 |
| F25 | Last.fm scrobbling (opt-in) | ✔ | P2 |

---

## 4. State Management Contract (NO `setState`)

### 4.1 Rules
1. **`setState` is forbidden everywhere.** CI script greps `lib/` and fails on `setState(`.
2. **`StatefulWidget` is forbidden** in `lib/` except a short allow-list (none planned). Use `HookWidget` / `HookConsumer`-style hooks instead.
3. State classification:

| Kind of state | Where it lives | Example |
|---|---|---|
| App/business state | **BLoC / Cubit** | search results, queue, library, downloads, update status, settings |
| Ephemeral UI state | **`flutter_hooks`** inside the widget | text controller, focus, scroll controller, animation controller, "is search field focused", expanded/collapsed toggle |
| High-frequency (≥10 Hz) | **`ValueNotifier`/`ValueListenable`** owned by a service/BLoC, consumed with `ValueListenableBuilder` | playback position, buffered position, drag progress |
| Persisted settings | `SettingsCubit` ← `SettingsRepository` (shared_preferences) | theme, glass quality |

4. **BLoC rules**
   - Events and states are `freezed` sealed classes. No mutable fields.
   - One BLoC per screen concern; global BLoCs only: `PlayerBloc`, `ThemeCubit`, `SettingsCubit`, `ConnectivityCubit`, `DownloadsBloc`, `UpdateBloc`, `LibraryBloc`.
   - Always use `BlocSelector` / `buildWhen` / `context.select`, never rebuild a whole screen for one field.
   - Event transformers: `restartable()` (search, suggestions), `droppable()` (play/pause taps, like), `sequential()` (queue mutations, downloads queue).
   - BLoCs depend on **UseCases only**, never on repositories, Dio, Drift or plugins directly.
   - No `BuildContext` inside BLoC. Navigation and snackbars triggered via `BlocListener` in presentation.
   - One-time effects (toast, navigate) use a dedicated `effect` stream or `listenWhen` on a state field that is cleared by an event. Never store a `BuildContext` or a callback in state.
5. Streams from Drift (`watch...`) are subscribed inside BLoC with `emit.forEach` / `emit.onEach` so they cancel automatically.
6. Heavy work (parsing > 50 KB, palette, LRC parse, backup) via `compute`/`Isolate.run`, never in BLoC main isolate path.

### 4.2 Why hooks are allowed
`AnimationController` needs a `TickerProvider`. Hooks (`useAnimationController`) provide this without `StatefulWidget` and without writing `setState`. Hooks are used **only** for UI-local state. Anything that another widget, screen, test or use case might care about goes in a BLoC.

### 4.3 CI enforcement (`scripts/check_code_rules.sh`)
Fails build if any of these match in `lib/`:
- `setState(`
- `extends State<` / `extends StatefulWidget` (outside allow-list file)
- `Navigator.of(context)` outside `core/router` (use `go_router`)
- `package:dio/` or `package:drift/` imports inside `presentation/` or `domain/`
- `print(` (use logger in debug only)
- Any file > 300 lines (warn) / > 400 lines (fail)
Also fails on tracker packages in `pubspec.lock` (firebase_*, sentry, mixpanel, amplitude, appsflyer, facebook_*).

---

## 5. Architecture & Code Quality

### 5.1 Layers
```
Presentation (Pages, Widgets, BLoC/Cubit)  -> Domain only
Domain (Entities, UseCases, Repo interfaces, Failures)  -> nothing (pure Dart)
Data (Repo impls, DataSources, DTOs, Mappers, Drift, API clients) -> Domain
```
Flow: `UI event → BLoC → UseCase → Repository(interface) → Impl → [Local | Remote] → Mapper → Entity → State → UI`

### 5.2 SOLID mapping
| | Applied as |
|---|---|
| S | One UseCase = one action. One BLoC per concern. Widgets only render |
| O | New source = new `StreamSource` implementation registered in DI. No existing code changes |
| L | All `StreamSource`/`LyricsSource` implementations are interchangeable |
| I | Small repo interfaces (`StreamRepository`, `LyricsRepository`, `LibraryRepository`…) |
| D | BLoCs → UseCases (abstractions), impls injected via `get_it` |

### 5.3 Code standards
- Null-safe, `final` by default, `const` constructors wherever possible, immutable models.
- Naming: `snake_case.dart` files, `UpperCamelCase` types, events end with a past-tense verb (`QueryChanged`), states are nouns.
- Max function ~40 lines, max widget `build` ~80 lines → extract widgets (as **classes**, not helper methods returning widgets).
- No logic in `build()`; no `Future`/`Stream` creation in `build()`.
- No `dynamic` outside the data layer's JSON parsing.
- Public APIs documented with `///`.
- No magic numbers: use tokens (`AppSpacing`, `AppRadius`, `AppDurations`).
- Strings in ARB (`l10n`), never hard-coded in widgets.
- Error handling: data layer catches → maps to `Failure`; BLoC maps `Failure` → state; UI maps state → message.
- Commits: Conventional Commits (`feat(player): …`). One feature = one branch = one PR.

### 5.4 Pull-request checklist (every feature)
- [ ] No `setState`, no `StatefulWidget`
- [ ] Layer rules respected (CI script green)
- [ ] Tests written (unit, bloc, widget, golden) and green
- [ ] Responsive: checked at all 8 sizes (Section 12)
- [ ] Profile-mode jank check passed
- [ ] Offline behaviour verified
- [ ] Previous features' tests all still green

---

## 6. Navigation & Information Architecture

### 6.1 Navigation per window class (see Section 7 for class definitions)
| Class | Navigation | Player |
|---|---|---|
| **Compact** (phone portrait) | Floating glass **bottom bar**, 4 tabs | Mini player above bar → expands to full-screen Now Playing |
| **Medium** (large phone landscape, small tablet portrait, foldable inner) | **Navigation rail** (left, glass, icons + labels on selected) | Mini player docked at bottom of content area; Now Playing opens as full-screen or large sheet |
| **Expanded** (tablet landscape, 840 dp+) | **Extended rail** (icons + labels) or compact rail if width < 1000 | **Persistent bottom player bar** + optional **right-side panel** (Queue / Lyrics / Now Playing) |
| **Large** (≥1200 dp) | Extended rail, content max width 1200 dp centered or 3-pane | Same as expanded, panel always visible |

Tabs (all classes): **Home · Search · Library · Settings**.

Bottom bar (compact): height 64, bottom margin 12, side margin 16, radius 32, σ 24; hides on Now Playing, Queue, Lyrics and Settings sub-screens (180 ms slide).
Rail (medium+): width 80 (compact rail) / 240 (extended), glass fill, selected item = accent pill.

### 6.2 Screen map
```
Splash -> [first run] Onboarding -> AdaptiveShell
AdaptiveShell
 |- Home -> Album | Artist | Playlist | Now Playing
 |- Search -> Results -> Album/Artist/Playlist/Now Playing
 |- Library -> Liked | Playlists -> Playlist | Downloads | History
 |- Settings -> Appearance | Audio & EQ | Storage | Privacy & Security | Updates | About
Now Playing -> Queue | Lyrics      (expanded: shown as side panel tabs)
Overlays: Song options · Add to playlist · Sleep timer · Create playlist · Update dialog · Mini player
```
Implementation: `go_router` `StatefulShellRoute.indexedStack`; `AdaptiveShell` reads `WindowSizeClass` and renders bar or rail around the same `navigationShell`. Each tab keeps its own stack and scroll position on rotation/resizing.

---

## 7. Adaptive & Responsive System

### 7.1 Window size classes (Material 3 aligned, width in dp of the **available constraints**, not the physical screen)
| Class | Width | Typical devices |
|---|---|---|
| **Compact** | < 600 | Phones portrait, split-screen halves |
| **Medium** | 600 – 839 | Small tablets portrait, foldables unfolded, big phones landscape |
| **Expanded** | 840 – 1199 | Tablets landscape, 10" portrait |
| **Large** | ≥ 1200 | Large tablets/Chromebook-size windows |

Also a **height class**: *compact height* < 480 dp (phone landscape) → switches Now Playing to two-column, hides bottom bar in favour of rail.

`core/responsive/window_size_class.dart` exposes `WindowSizeClass.of(context)` computed from `LayoutBuilder` constraints (works inside panes and in split-screen/foldable/resizable windows). **Never** decide layout from `Platform` or device name.

### 7.2 Responsive toolkit (`core/responsive/`)
| Piece | Purpose |
|---|---|
| `Breakpoints` | constants 600 / 840 / 1200, height 480 |
| `WindowSizeClass` | enum + `of(context)` + extension `isCompact`, `isMedium`, `isExpandedUp` |
| `AdaptiveShell` | bar vs rail vs rail+panel, mini player/bar placement |
| `AdaptiveLayout` | `compact / medium / expanded / large` builder slots, falls back to nearest smaller slot |
| `AdaptiveGrid` | computes column count from available width and a target card width (e.g. media card 150 dp → 2 cols @360, 4 @700, 6 @1000) |
| `MaxContentWidth` | centers and clamps content (default 1200; reading text 720) |
| `TwoPane` | master-detail with draggable-free fixed ratios (35/65 or 40/60) |
| `ResponsiveInsets` | side padding: 16 / 24 / 32 / 40 by class; safe-area + gesture-inset aware |

### 7.3 `flutter_screenutil` strategy (to avoid giant tablets)
- `ScreenUtilInit` receives **design size per class**: compact **393×852**, medium **744×1133**, expanded/large **1194×834** (re-initialised when the class changes).
- `.w/.h/.r/.sp` used for spacing, radii, icon sizes and fonts.
- **Clamp rule:** text scale from ScreenUtil is clamped to 0.9–1.25× and respects the system font scale up to 1.3. Touch targets never below 48 dp.
- Album art, grids and panels use **constraints + `AdaptiveGrid`**, not raw `.w`, so images don't balloon on tablets.
- Content wrapped in `MaxContentWidth` on Expanded/Large.

### 7.4 Orientation, foldables, resizing
- Layout reacts to constraints, so rotation, split-screen, freeform windows and foldable posture changes work with no extra code.
- On fold/unfold or rotation: **no state loss** (BLoC state, scroll positions via shell route, playing track unaffected, animation resumes).
- Display cutouts and system bars respected via `SafeArea`; glass bars extend behind gesture area with padding.
- Support Android 12+ large-screen guidelines: `resizeableActivity` true, no fixed orientation lock, min-size 360×300.

### 7.5 Shared component adaptive behaviour
| Component | Compact | Medium | Expanded / Large |
|---|---|---|---|
| Side padding | 16 | 24 | 32 / 40 |
| `MediaCard` grid | 2–3 cols | 3–5 | 5–8 |
| `SongTile` | art 52, 1 line meta | art 56 | art 56, extra columns (album, duration) |
| Horizontal carousels | card 140 | 160 | 180, show arrow buttons on hover/focus |
| Sheets (options, add to playlist) | bottom sheet, full width | bottom sheet max 560 centered | **centered dialog / side popover** max 480 |
| Dialogs | width 90% | 480 | 480 |
| Search field | full width | max 640 | max 720, left-aligned in content |
| Text | Inter, ScreenUtil design 393 | design 744 | design 1194 |
| Focus/keyboard | – | visible focus ring on all controls, arrow-key navigation for lists (tablet with keyboard) |

---

## 8. Design System — "Liquid Glass, Professional"

### 8.1 Principles
Content first · calm not flashy · depth via layering (art blur → glass → content) · one accent at a time from album art · no cartoon shapes.

### 8.2 Tokens
**Colour (dark-first)**: `bg #0A0C10` · `bgElevated #10131A` · glass fill white 8% (strong 14%) · glass border white 16% with top-left highlight gradient · text `#F4F6FA / #A5AEBB / #6B7482` · `accentDefault #8FA8FF` · `accentDynamic` from palette clamped to S 45–75%, L 55–70% · semantic `#4ADE80 / #FBBF24 / #F87171`.
**Type (Inter bundled)**: Display 32/700 · Title 22/600 · Subtitle 17/600 · Body 15/400 · Caption 13/500 · Overline 11/600.
**Spacing**: 4-pt grid. **Radius**: chip 12 · card 20 · sheet 32 · art 20 (player 28) · pill 999.
**Motion**: 120/220/360 ms, `easeOutCubic`, spring only for player drag.
**Icons**: Phosphor regular, 24 dp. **Touch target** ≥ 48 dp.

### 8.3 Components (`core/ui/`)
`GlassSurface`, `GlassNavBar`, `GlassRail`, `GlassSheet`, `GlassDialog`, `GlassButton`, `GlassChip`, `MiniPlayer`, `PlayerBar` (expanded), `SongTile`, `MediaCard`, `SectionHeader`, `SkeletonBox`, `StateView`, `SeekBar`, `AdaptiveGrid`.

### 8.4 Liquid Glass implementation rules (performance critical)
1. **Max 3 blurred surfaces visible at once** (compact: bar + mini player + sheet; expanded: rail + player bar + panel).
2. σ range 16–32, never above 40.
3. **No `BackdropFilter` inside scrolling list items.** Lists use *fake glass* (translucent fill + border + gradient).
4. Every glass surface in a `RepaintBoundary`; background behind it must not animate continuously.
5. **Large panels on tablets (side panel, rail) use fake glass on Mid/Low tiers**, blur only on High tier, because blur cost scales with area.
6. `liquid_glass_renderer` (refraction shader) is **experimental per its own README**: used only for nav active-tab highlight + player control cluster, **High tier only**, behind a feature flag so it can be removed without touching other code. Moving glass shapes re-render every frame, so they never animate position inside lists.
7. **Device tiers** (`DeviceTierService`: device info + 2-second frame-time probe on first run, re-probed after OS update): High = blur + refraction + animated backdrop · Mid = blur only · Low = no blur, translucent gradient surfaces. User override in Settings → Appearance.
8. Player background = downscaled blurred bitmap, computed once per track in an isolate and cached. Not a live blur.
9. Impeller on; verify via `--profile`.

### 8.5 Dynamic colour pipeline
Art → 64×64 in isolate → palette → clamp → cache by URL in DB → `ThemeCubit` → 400 ms colour tween. Never on UI thread.

### 8.6 Accessibility
Contrast ≥ 4.5:1 over glass (scrim). Semantics labels on icon buttons. System font scale up to 1.3. Reduce-motion disables parallax/backdrop animation. Focus indicators and keyboard navigation on tablets.

---

## 9. Security & Privacy

| # | Requirement | Implementation |
|---|---|---|
| 9.1 | No telemetry | No analytics/crash SDKs; CI tracker gate |
| 9.2 | Encrypted DB | Drift + SQLCipher; random 256-bit key in Keystore via `flutter_secure_storage` |
| 9.3 | Secure prefs | Secrets only in secure storage |
| 9.4 | Transport | HTTPS only, network security config; pin the GitHub update host; unofficial hosts rely on TLS + response validation |
| 9.5 | Update integrity | SHA-256 verify before install; same signing key |
| 9.6 | Hardening | `--obfuscate --split-debug-info`, R8 shrink, no debug logs in release |
| 9.7 | App lock | `local_auth`, timeout setting, `FLAG_SECURE` toggle |
| 9.8 | Permissions | `INTERNET`, foreground service (media playback), `POST_NOTIFICATIONS`, `REQUEST_INSTALL_PACKAGES` (updater only) |
| 9.9 | Downloads | App-private dir; encrypted-at-rest is P2 |
| 9.10 | Input safety | Sanitise queries, typed models, size caps, timeouts 10 s / 20 s |
| 9.11 | Backup | AES-GCM with user passphrase |
| 9.12 | Supply chain | Renovate/Dependabot, review each new package |
| 9.13 | Android backup | `allowBackup=false` |

---

## 10. Performance Plan ("0 Jank", phone + tablet)

### 10.1 Budgets
| Metric | Target |
|---|---|
| Frame (build+raster) | < 8 ms @60 Hz, < 4 ms @120 Hz typical; p95 < 12 / 6 ms |
| Cold start → Home | < 1.5 s mid-range phone, < 1.8 s tablet |
| Tap → audio | < 1.2 s online, < 300 ms downloaded |
| Dropped frames in 60 s scroll | < 1% |
| Memory idle playing | < 250 MB phone, < 350 MB tablet |
| APK (arm64) | < 35 MB |
| Rotation / resize | no frame > 32 ms, no state lost |

### 10.2 Rules
- Heavy work off main isolate (`compute`/`Isolate.run`).
- `const` everywhere; no work in `build()`.
- Widgets split into small classes so rebuilds are surgical (`BlocSelector`, `ValueListenableBuilder`).
- `SliverList` / `SliverGrid` with builders, `prototypeItem` or `itemExtent` where fixed; pagination (20–30).
- Images: `memCacheWidth/Height` = display size × DPR (tablet art is larger, cache keys per size bucket); fade-in 120 ms; disk cap 200 MB default.
- Position/progress via `ValueListenable`, not main BLoC state.
- Lyrics: only current ± 3 lines animate.
- No `Opacity` in animations (use `FadeTransition`/`AnimatedOpacity`); avoid `saveLayer`.
- Adaptive layout switching uses `AnimatedSwitcher` with identical keys for persistent children so players/lists aren't rebuilt on class change.
- Audit in DevTools profile mode after every feature, on **one phone and one tablet** (or tablet emulator with 120 Hz profile).
- Optional CI: `integration_test` + `traceAction` for Home scroll and player open.

---

## 11. Project Structure

```
aura_music/
├── android/
├── assets/ { fonts/ icons/ images/ l10n/ }
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart
│   ├── app.dart                          # MaterialApp.router, ScreenUtilInit per class, global BlocProviders
│   ├── core/
│   │   ├── constants/  di/  error/  network/(interceptors/)  usecase/  utils/
│   │   ├── router/     app_router.dart, routes.dart
│   │   ├── responsive/ breakpoints.dart, window_size_class.dart, adaptive_shell.dart,
│   │   │               adaptive_layout.dart, adaptive_grid.dart, max_content_width.dart,
│   │   │               two_pane.dart, responsive_insets.dart
│   │   ├── hooks/      use_debounced_value.dart, use_glass_tier.dart, use_reduced_motion.dart
│   │   ├── theme/      app_theme.dart, colors.dart, typography.dart, tokens.dart
│   │   ├── ui/         glass_surface.dart, glass_nav_bar.dart, glass_rail.dart, glass_sheet.dart, glass_dialog.dart,
│   │   │               song_tile.dart, media_card.dart, mini_player.dart, player_bar.dart, seek_bar.dart, state_view.dart ...
│   │   └── services/   device_tier_service.dart, connectivity_service.dart, permission_service.dart, secure_key_service.dart
│   ├── database/       app_database.dart, tables/, daos/, migrations/
│   ├── features/
│   │   ├── splash_onboarding/ home/ search/ player/ lyrics/ album/ artist/ playlist/
│   │   ├── library/ downloads/ settings/ update/ security/ stream_resolver/
│   │   └── <each> = data/{datasources,models,repositories} · domain/{entities,repositories,usecases} · presentation/{bloc,pages,widgets}
│   └── l10n/
├── test/   (mirrors lib/)  helpers/ (mocks.dart, pump_app.dart, window_sizes.dart, fixtures/)  goldens/
├── integration_test/
├── scripts/  check_code_rules.sh, check_no_trackers.sh
├── .github/workflows/  ci.yml, release.yml
├── analysis_options.yaml
└── pubspec.yaml
```
Each page has a thin `*_page.dart` (provides BLoC, reads window class) and per-class layout widgets, e.g. `home_compact_view.dart`, `home_wide_view.dart`, so layouts never become one 600-line `if/else`.

---

## 12. Testing Strategy

**Rule:** a feature isn't finished until its tests pass **and** the whole previous suite still passes.

| Layer | Tools | Covers |
|---|---|---|
| Domain | `flutter_test`, `mocktail` | every UseCase, each failure |
| Data | `mocktail`, in-memory Drift, dio mock | repo impls, mappers, fallback chain order, DAOs, migrations |
| BLoC | `bloc_test` | every event → exact state sequence, retries, concurrency transformers (debounce/restartable) |
| Widget | `flutter_test` | each screen: loading / empty / error / success / offline |
| **Responsive** | `flutter_test` + `alchemist` | every screen at the size matrix below |
| Golden | `alchemist` | components + screens, dark theme, glass tiers High and Low |
| Integration | `integration_test` | journeys J1–J7 |
| Performance | DevTools / `traceAction` | budgets in 10.1 |
| Static rules | `scripts/check_code_rules.sh` | no `setState`, layer imports, file size, trackers |

### 12.1 Responsive test matrix (logical px)
| # | Size | Represents |
|---|---|---|
| 1 | 360 × 640 | Small phone |
| 2 | 393 × 852 | Reference phone |
| 3 | 412 × 915 | Large phone |
| 4 | 852 × 393 | Phone landscape (compact height) |
| 5 | 600 × 960 | Small tablet / foldable portrait |
| 6 | 744 × 1133 | 8–9" tablet portrait |
| 7 | 1194 × 834 | 11" tablet landscape |
| 8 | 1600 × 900 | Large tablet / freeform window |
Each screen is also run at text scale 1.0 and 1.3. Test asserts **no `RenderFlex overflow`**, navigation shows correct form (bar/rail/panel), and golden matches.

### 12.2 Journeys
J1 Search → play · J2 Like + playlist → restart → persists · J3 Download → airplane mode → play · J4 Background play + notification controls · J5 Sleep timer · J6 Update check → download → verify (mock) · **J7 Rotate / resize / fold mid-playback → no state loss, no audio gap**.

### 12.3 Per-feature gate
1. Unit + BLoC + widget + responsive + golden tests written (≥ 80% on touched code)
2. `flutter analyze` = 0, code-rules script green (**0 `setState`**)
3. Profile-mode jank check on phone and tablet
4. Offline behaviour verified
5. Full regression suite green → merge → next feature

---

## 13. Database Schema (Drift, encrypted)
`songs`, `albums`, `artists`, `playlists`, `playlist_songs(playlistId, songId, position)`, `liked_songs`, `history(songId, playedAt, playedMs)`, `downloads(songId, filePath, sizeBytes, status, progress)`, `lyrics_cache`, `color_cache`, `search_history`, `queue_state`.
Indexes on `history.playedAt` and `playlist_songs(playlistId, position)`. Transactions for multi-row writes. Tested migrations.

---

## 14. Screens — Detailed Specs (with phone + tablet behaviour)

Legend: **C** = Compact, **M** = Medium, **E** = Expanded/Large. **Btn** = tappable controls excluding list items. Every screen has loading (skeleton), empty, error (retry) and offline states.

### S01 Splash
Init DB/DI/restore queue; centred vector mark with soft pulse; ≤ 800 ms, no fake delay. Same on all classes. Btn 0. `AppStartCubit`.

### S02 Onboarding (first run, skippable)
3 pages: Stream ad-free · Download & listen offline · Your data stays on your device. **C:** full-screen pager. **M/E:** centred card max 560 over gradient. Btn: Next, Skip, Get started, Allow notifications (optional).

### S03 Home
Sections (each loads independently): Quick picks (grid) · Continue listening · Trending · New releases · Moods & genres (chips) · Because you listened to X · Your playlists. Top: greeting + History button.
- **C:** quick picks 2 cols; carousels 140 dp cards.
- **M:** quick picks 3–4 cols; carousels 160.
- **E:** quick picks 4 cols + "Trending" and "New releases" as grids/carousels with arrow buttons; max content width 1200; optional right column "Recently played".
Btn: History, ~8 chips, "See all" ×4. Pull-to-refresh. Offline: network sections replaced by banner + Downloads/Liked/History. `HomeBloc` (Started, Refreshed).

### S04 Search
Large glass field; idle = recent searches + browse grid; typing = suggestions (debounce 300 ms, `restartable`).
- **C:** full-screen list.
- **M:** field max 640; browse grid 3 cols.
- **E:** two-pane: left suggestions/recent (35%), right live preview of top results (65%).
Btn: clear text, clear history, per-recent ✕, per-suggestion fill. `SearchBloc`.

### S05 Search Results
Filter chips: All · Songs · Albums · Artists · Playlists. All = Top result + sections; Songs = paginated list.
- **C:** vertical sections.
- **M:** songs 1 column, albums grid 3 cols.
- **E:** Top result card left + songs list right; albums/artists grids 5–6 cols; songs list shows album + duration columns.
Tap song = play and queue results.

### S06 Now Playing
Background = blurred art + scrim + accent gradient. Controls: Collapse, More, Like, Shuffle, Prev, Play/Pause, Next, Repeat, Lyrics, Queue, Download (11). Gestures: drag down collapse, swipe art = next/prev, double-tap art = like.
- **C portrait:** vertical stack (art ~80% width → title/artist/like → seek → controls → bottom row).
- **C landscape / compact height:** two columns, art left, info + controls right.
- **M:** centred column max 520, art up to 420.
- **E/Large:** not a separate route. **Docked layout**: left = art + info + controls (max 480), right = tabbed panel **Lyrics | Queue | Related**. Persistent `PlayerBar` shows when panel is closed.
`PlayerBloc` + position `ValueListenable` + `LikeCubit` + `DownloadsBloc`. Errors: stream fail → toast + auto-skip after 1.5 s.

### S07 Queue
Header (count, Clear, Shuffle), pinned now-playing tile, reorderable "Up next" (drag handle, swipe to remove).
- **C/M:** full page / sheet.
- **E:** right-side panel tab (width 360–420). Drag-and-drop reorder works with mouse/touch.

### S08 Lyrics
Auto-scroll lines, current line emphasised (colour, not `Opacity`), tap line = seek. Controls: Back, Offset −/+, Font −/+, Sync toggle. Sources: LRCLIB → cache → "not found" + manual search.
- **C:** full-screen.
- **M:** full-screen, text max width 640 centred.
- **E:** right-side panel tab; font scales one step larger.

### S09 Album
Art, title, artist, year · N songs · duration. Actions: Play, Shuffle, Download all, Save, More.
- **C:** header then track list.
- **M/E:** **two-pane**: header/art/actions pinned left (35%), track list right with number, title, artist, duration columns.

### S10 Artist
Hero image (parallax, off when reduce-motion), Shuffle, Follow, More; sections: Top songs, Albums, Singles, Playlists, Similar artists, About.
- **C:** hero full width, sections vertical.
- **M:** hero 40% height; top songs 2 columns.
- **E:** hero left (35%) pinned, sections scroll right; albums grid 5 cols.

### S11 Playlist
Cover (2×2 mosaic for local), name, description, actions Play/Shuffle/Download/Edit/More; reorder + swipe-remove for local. Edit: rename, description, delete (confirm).
- **C:** stacked. **M/E:** two-pane like Album.

### S12 Library
Four shortcut tiles (Liked, Downloads, History, Create playlist), chips Playlists · Albums · Artists, grid/list toggle, sort.
- **C:** tiles 2×2, list/grid 2 cols.
- **M:** tiles 4 in a row, grid 3–4 cols.
- **E:** **master-detail**: left list (collections), right selected collection detail.

### S13 Downloads
Storage bar, In progress (pause/resume/cancel), Downloaded list, actions: Pause/Resume all, Delete all (confirm), Play, Shuffle. Max 3 concurrent, auto-resume on connectivity, failed → Retry.
- **C:** one list. **E:** two columns: In progress (left), Downloaded (right).

### S14 Liked Songs / S15 History
Liked: header, in-list search, Play, Shuffle, sort, swipe to unlike. History: grouped by day, Clear (confirm). Adaptive: single list C/M; wide rows with album + duration columns on E.

### S16–S22 Settings
S16 root: grouped glass cards (Appearance, Audio & EQ, Storage, Privacy & Security, Updates, Backup, About).
- **C:** push navigation list → sub-pages.
- **M/E:** **master-detail**: left list (320 dp), right selected sub-page (no navigation animation, same BLoC).
S17 **Appearance**: Glass quality (Auto/High/Mid/Low), Dynamic colour, Player background, Animated backdrop, Reduce motion, Theme (Dark/AMOLED), Accent fallback, live preview card.
S18 **Audio & EQ**: master switch, presets, 5-band sliders, loudness, crossfade 0–12 s, speed 0.5–2×, quality (Auto/High/Low), skip silence, normalize.
S19 **Storage & Cache**: bars (downloads, image, stream, free), cache limit slider 100 MB–2 GB, clear image/stream cache, manage downloads, auto-evict, Wi-Fi-only downloads.
S20 **Privacy & Security**: app lock + timeout, block screenshots (`FLAG_SECURE`), pause history, clear search history, clear all data (typed confirm), Last.fm opt-in (P2), privacy statement.
S21 **Updates**: version/build, last checked, Check now, auto-check, channel, status card (Up to date / Available / Downloading / Ready / Error).
S22 **About**: version, licenses, GitHub, report bug, credits, disclaimer.

### Overlays
| ID | Name | C/M | E |
|---|---|---|---|
| O1 | Song options | glass bottom sheet | popover/dialog 480 |
| O2 | Add to playlist | bottom sheet | dialog 480 |
| O3 | Sleep timer | bottom sheet | popover |
| O4 | Create playlist | dialog | dialog |
| O5 | Update dialog | dialog (mandatory = non-dismissable) | dialog |
| O6 | Mini player (C/M) | docked above bar/rail | replaced by `PlayerBar` (E) |

---

## 15. Global Behaviours
- **Offline:** slim glass banner; network-only items dimmed; downloaded ✓ badge; search falls back to local.
- **Playback resume:** queue + position saved every 5 s and on pause; restored paused.
- **Audio focus:** pause on interruption/unplug; duck for notifications.
- **Notifications:** media (art, prev/play/next, like), downloads, updates.
- **Toasts:** non-blocking glass snackbar, 3 s, max 1.
- **Localisation:** English first, ARB from day 1, Hindi P1.
- **Keyboard/mouse (tablet):** space = play/pause, arrows = seek/navigate lists, focus ring visible.

---

## 16. OTA Update
GitHub Releases `latest` + `update.json` asset (versionCode, sha256, size, changelog, mandatory).
Flow: check at start (≤ once / 12 h, 60 req/h unauthenticated limit) or manually → compare versionCode → Update dialog (Update now / Later / Skip this version) → `background_downloader` (resumable) → SHA-256 verify → install-permission flow → `open_filex` → "What's new" once.
Edge cases: offline, low storage (free ≥ 2× size), interrupted download, installer cancelled, mandatory update.

---

## 17. Roadmap

| Phase | Scope | Exit gate |
|---|---|---|
| **0 Foundation** | skeleton, DI, theme, **responsive toolkit + AdaptiveShell**, glass components, router, encrypted Drift, Dio, CI + code-rules script, device-tier service, **stream-resolver spike** (20 songs on a real phone) | goldens at 8 sizes for shell; CI green; 0 `setState`; spike decision recorded |
| **1 Core playback** | F01–F06, F10 for these screens | J1, J4, J7; jank budget on phone + tablet |
| **2 Library & pages** | F08, F09, Home | J2 |
| **3 Offline & polish** | F11–F14, F17, F19 | J3, J5 |
| **4 Security & updates** | F15, F18, F20, DB audit, tracker gate | J6, security checklist |
| **5 P2** | F21–F25 | per-feature gate |

---

## 18. Risks
| Risk | Mitigation |
|---|---|
| YouTube extraction breaks / needs JS solver | Phase-0 spike, fallback chain, pin working version, OTA patching |
| Blur jank on weak devices or large tablet panels | Tiers, blur budget, fake glass for large panels |
| `liquid_glass_renderer` experimental | Optional flag, High tier only, isolated behind one widget |
| Layout bugs at odd sizes | Own responsive toolkit + 8-size golden/overflow matrix in CI |
| Sideload friction / legal | Disclaimer, GitHub Releases distribution |
| SQLCipher + Drift complexity | Spike in Phase 0 with migration test |

## 19. Acceptance Criteria (v1.0)
- All P0 + P1 features done and tested
- J1–J7 green
- Every screen verified at all 8 sizes, 0 overflow, correct navigation form (bar/rail/panel)
- p95 frame budget met on reference phone and tablet
- **0 `setState`, 0 `StatefulWidget`**, layer rules green
- No tracker dependency, encrypted DB, verified updates
- Coverage: domain ≥ 90%, overall ≥ 80%; `flutter analyze` = 0
- Fully usable offline for downloads, library and settings

## 20. Open Questions
App name & logo · Hindi in v1.0? · JioSaavn in v1.0 or P2? · Light theme in v1.0 or later?
