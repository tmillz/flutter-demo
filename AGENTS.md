# Agent Instructions — tmillz/website

Personal portfolio and blog built with Flutter + Firebase. This file captures every design and architecture decision made in the project so that agents work consistently with existing conventions.

---

## Project Overview

A cross-platform Flutter application serving three purposes:
1. **Blog feed** — admin-authored posts with text, embedded YouTube videos, and uploaded images; public emoji-reaction system.
2. **Games** — two Flame-engine games (Ping / T-Rex) accessible via the navigation drawer.
3. **Web deployment** — hosted on Firebase Hosting (`tmillz.firebaseapp.com`) with a single-page-app rewrite rule.

**Supported platforms:** Web (primary), Android, Windows. iOS/macOS are intentionally not configured.

---

## Architecture Decisions

### State Management — ValueNotifier only, no framework
- `ThemeService` exposes a single `ValueNotifier<ThemeMode>` consumed by a `ValueListenableBuilder` at the root widget.
- Game state (score, game-over flag) uses `ValueNotifier<T>` on the `FlameGame` class.
- Firestore data is consumed via `StreamBuilder`; no caching layer.
- **Decision:** No Provider / Riverpod / Bloc. The app is small enough that a lightweight approach avoids unnecessary indirection.

### Routing — GoRouter with email-based admin guard
- All routes are declared in `lib/app_router.dart` using GoRouter v17.
- `/new-post` has a `redirect` callback that checks `FirebaseAuth.instance.currentUser?.email == 'YOUR_EMAIL@gmail.com'`; non-admins are redirected to `/`.
- Games are reachable at `/ping` and `/trex`.

### Firebase — emulator-first development
- `main.dart` connects to local emulators whenever `kDebugMode` is true **or** the Dart compile-time constant `USE_EMULATORS=true` is set.
- Emulator ports: Auth `9099`, Firestore `8080`, Storage `9199`.
- Emulator connection is wrapped in `try/catch`; failures fall back to production silently (never crash).
- Flutter web is built with `--dart-define=USE_EMULATORS=true` for the screenshot script so it hits local emulators.

### Firebase config — CI stub pattern
- Production keys live in `lib/firebase_options.dart` (gitignored or protected).
- `lib/firebase_options_ci.dart` contains placeholder values and is copied over `firebase_options.dart` in every CI job before `flutter analyze` / `flutter test` run. This keeps secrets out of workflow logs while allowing static analysis.

### Security rules — admin-only writes
- Firestore: public reads everywhere; writes to `posts/` require `isAdmin()` (email match); `reactions/` allows any authenticated user to create, only owner or admin can delete, updates are denied entirely.
- Storage: `posts/{allPaths=**}` — public read, write requires authenticated admin email.

### Theme — Material 3, two modes, secure persistence
- Light seed: `Colors.cyan` / Dark seed: `Colors.blueGrey`.
- `ThemeService.cycleMode()` toggles between `ThemeMode.light` and `ThemeMode.dark`; no system-follow mode.
- Preference is persisted with `FlutterSecureStorage` as the string `'light'` or `'dark'`.
- `shared_preferences` was removed to avoid analyzer issues; `flutter_secure_storage` is the only local-storage mechanism.

### Fonts — Orbitron for brand/games, Inter for secondary UI
- `GoogleFonts.orbitron` is used in the drawer header and ping-game score display.
- `GoogleFonts.inter` is used in the drawer subtitle.
- No custom font assets; everything is loaded dynamically via the `google_fonts` package.

### Responsive layout — single breakpoint at 600 px
- `HomeScreen` checks `MediaQuery.of(context).size.width < 600` and applies horizontal padding `6.0` (narrow) or `12.0` (wide).
- No adaptive scaffold or layout-builder beyond this single check.

### Platform-specific imports — conditional stub pattern
- `lib/src/register_web_plugins_stub.dart` (no-op) and `lib/src/register_web_plugins_web.dart` (registers `YoutubePlayerIframePlugin`) are selected at compile time via `if (dart.library.html)` imports in `main.dart`.
- `YoutubePlayerIframePlugin` **must** be registered before any `YoutubePlayerController` is created; this is done at the very top of `main()`.

### YouTube embedding
- `youtube_player_iframe` v6 is used for embedded video.
- On web the iframe WebView platform is registered via the conditional import above.
- `PostCard` builds a `YoutubePlayerScaffold` when `post.embedUrl` is non-null.

### Image uploads
- Images are stored at `posts/{userId}/{filename}` in Firebase Storage.
- Public read access is allowed by storage rules; writes require authenticated admin.

---

## Game Architecture

### Ping game (`lib/games/ping_game.dart`)
- Extends `FlameGame`; no mixins beyond the default.
- `_BallComponent` and `_PaddleComponent` are private inner classes — keep them that way.
- Ball starts at 45 % of screen height with a random angle ±40° from vertical.
- Initial speed 320 px/s; increases 5 % per paddle hit; clamped to 700 px/s.
- Paddle width 110 px, height 14 px, positioned 80 px from the bottom.
- Score and game-over status are `ValueNotifier`s on `PingGame` — the Flutter UI widget tree listens to them directly via `ValueListenableBuilder`.
- Paddle movement is driven by `GestureDetector.onPanUpdate` in `PingGameScreen`, not by Flame input events.
- **Score display:** Orbitron 52 px bold, `colorScheme.onSurface` at 90 % opacity, no shadows or glow — the glow was explicitly removed.

### T-Rex game (`lib/games/trex/`)
- Extends `FlameGame` with `KeyboardEvents`, `TapCallbacks`, `HasCollisionDetection`.
- All graphics come from a single sprite sheet at `assets/images/trex.png`.
- Player states: running, waiting, jumping, crashed — managed by `SpriteAnimationGroupComponent`.
- Gravity constant 0.85; initial jump velocity −16.
- Speed ramps from 600 to 2 500 px/s as score increases.
- Game over and score panels are sprite-based (no Flutter widget overlay).
- Controls: Space / Enter key, or tap. The in-game back button is a Flame component (`back_button.dart`), not a Flutter widget.

---

## Scripts

### `scripts/screenshot.sh`
Automates taking a homepage screenshot for the README. Key decisions:
- Playwright and `serve` are both installed locally with `npm install --no-save --ignore-scripts playwright serve` — no global installs, no lifecycle-script exposure.
- `npx` is never used; all CLI tools are invoked via `./node_modules/.bin/` paths.
- Firebase emulators are started with `--import=./firebase-export` so the screenshot shows realistic data.
- The script polls `localhost:8080` (up to 60 × 2 s) and `localhost:3000` (up to 30 × 1 s) before proceeding.
- Accepts `--no-commit` flag to skip the git commit step.
- `check_cmd()` assigns `$1` to a local variable before use; error messages are sent to stderr (`>&2`).

### `scripts/take_screenshot.js`
- ES module (`import` syntax); runs with Node.js using `scripts/package.json` (`"type": "module"`).
- Uses top-level `await` — no async IIFE wrapper.
- Waits 8 s after `flt-glass-pane` attaches to allow CanvasKit WASM + Firestore emulator data to fully load.
- Screenshot saved to `screenshots/home-screen.png`.

### `scripts/update_readme.py`
- Finds `<!-- screenshot-start -->` / `<!-- screenshot-end -->` HTML comment markers and replaces the content between them with an updated image reference.

---

## CI/CD

Two workflow files in `.github/workflows/`:

| Workflow            | Trigger        | Steps                                                                                           |
|---------------------|----------------|-------------------------------------------------------------------------------------------------|
| `pull-requests.yml` | PR to `main`   | checkout → setup Flutter 3.44.2 → copy CI firebase options → `flutter analyze` → `flutter test` |
| `post-merge.yml`    | Push to `main` | Same as above                                                                                   |

- Flutter version is pinned to **3.44.2 stable** in both workflows.
- Cache key is `**/pubspec.lock`.
- No deployment step in either workflow — Firebase deploy is manual.

---

## Conventions to Follow

- **No new state management frameworks.** Add `ValueNotifier` + `ValueListenableBuilder` for local UI state; use Firestore streams for remote data.
- **Admin check is email-based.** The single admin email `YOUR_EMAIL@gmail.com` is referenced in both `app_router.dart` and `firestore.rules`. Keep them in sync.
- **Never use `npx` in scripts.** Install packages with `npm install --ignore-scripts` first; run via `./node_modules/.bin/`.
- **Shell functions must assign positional parameters to local variables** (`local foo="$1"`) and print errors to stderr.
- **No glow or shadow on the ping-game score number.** The `shadows` property on the Orbitron `Text` style was deliberately removed.
- **Emulator support must stay graceful.** The `try/catch` in `main.dart` must never be removed; the app should always be able to run against production.
- **CI must never see real Firebase credentials.** Always copy `firebase_options_ci.dart` over `firebase_options.dart` in workflow steps before analysis or tests.
- **Material 3 only.** Do not add `useMaterial3: false` or legacy M2 components.
- **Responsive breakpoint is 600 px.** Do not add more breakpoints without a clear reason.
- **`take_screenshot.js` must remain an ES module.** Do not convert it back to CommonJS or wrap code in an async IIFE.
