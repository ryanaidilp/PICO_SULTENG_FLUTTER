# Fastlane Configuration

Fastlane automates building, signing, and deploying the Flutter app for both iOS and Android.

## Prerequisites

```bash
# Install Ruby dependencies
bundle install

# For iOS: configure match for code signing
# Set MATCH_GIT_URL to your certificates repo
bundle exec fastlane match adhoc
bundle exec fastlane match appstore
```

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `APP_IDENTIFIER` | Bundle ID / Package name (default: `com.banuacoders.pico.app`) |

### iOS

| Variable | Description |
|----------|-------------|
| `APPLE_ID` | Apple Developer account email |
| `TEAM_ID` | Apple Developer Team ID |
| `ITC_TEAM_ID` | App Store Connect Team ID |
| `MATCH_GIT_URL` | Git repo URL for match certificates |

### Android

| Variable | Description |
|----------|-------------|
| `GOOGLE_PLAY_JSON_KEY` | Path to Play Store service account JSON key |

### Distribution

| Variable | Description |
|----------|-------------|
| `FIREBASE_ANDROID_APP_ID_DEVELOPMENT` | Firebase App ID for Android dev builds |
| `FIREBASE_ANDROID_APP_ID_STAGING` | Firebase App ID for Android staging builds |
| `FIREBASE_ANDROID_APP_ID_PRODUCTION` | Firebase App ID for Android production builds |
| `FIREBASE_IOS_APP_ID_DEVELOPMENT` | Firebase App ID for iOS dev builds |
| `FIREBASE_IOS_APP_ID_STAGING` | Firebase App ID for iOS staging builds |
| `FIREBASE_IOS_APP_ID_PRODUCTION` | Firebase App ID for iOS production builds |
| `SLACK_WEBHOOK_URL` | Slack webhook for build notifications (optional) |

## Available Lanes

### Android

```bash
# Build APK (development flavor by default)
bundle exec fastlane android build

# Build with specific flavor
bundle exec fastlane android build flavor:staging

# Build per-ABI APKs (--split-per-abi). Produces Pico-v0.1.0-<flavor>-<abi>.apk
bundle exec fastlane android build flavor:staging split_per_abi:true

# Distribute to Firebase App Distribution
bundle exec fastlane android distribute_firebase flavor:development

# Distribute a per-ABI APK to Firebase (defaults to arm64-v8a when split_per_abi:true)
bundle exec fastlane android distribute_firebase flavor:development split_per_abi:true abi:arm64-v8a

# Deploy to Google Play Store (internal track)
bundle exec fastlane android deploy_play_store flavor:production

# Deploy to specific track
bundle exec fastlane android deploy_play_store flavor:production track:beta
```

### iOS

```bash
# Build IPA (development flavor by default)
bundle exec fastlane ios build

# Distribute to Firebase App Distribution
bundle exec fastlane ios distribute_firebase flavor:development

# Deploy to TestFlight
bundle exec fastlane ios deploy_testflight flavor:production

# Deploy to App Store
bundle exec fastlane ios deploy_app_store flavor:production submit:true auto_release:true
```

### Cross-Platform

```bash
# Distribute both platforms to Firebase
bundle exec fastlane distribute_all flavor:staging

# Deploy both platforms to stores
bundle exec fastlane deploy_all flavor:production
```

## Flavors

| Flavor | Entry Point | Use Case |
|--------|-------------|----------|
| `development` | `lib/main_development.dart` | Local development, Firebase distribution |
| `staging` | `lib/main_staging.dart` | QA testing, Firebase distribution |
| `production` | `lib/main.dart` | Store releases |

## Output Artifacts

All builds produce `{AppName}-v{version}-{flavor}.{ext}` where `AppName` is the PascalCase form of the pubspec `name:` field and `version` is `version:` with the build number stripped. Per-ABI APK builds add a `-{abi}` suffix.

| Type | Path | Renamed by |
|------|------|------------|
| APK  | `build/app/outputs/flutter-apk/Pico-v0.1.0-development.apk` | Gradle (`applicationVariants.all`) — applies to any `flutter build apk` invocation |
| APK (per-ABI) | `build/app/outputs/flutter-apk/Pico-v0.1.0-development-arm64-v8a.apk` | Fastlane `rename_apk_artifacts_per_abi` helper (post-build) — produced when `split_per_abi:true` is passed |
| AAB  | `build/app/outputs/bundle/developmentRelease/Pico-v0.1.0-development.aab` | Gradle bundle-task hook — applies to any `flutter build appbundle` invocation |
| IPA  | `build/ios/ipa/Pico-v0.1.0-development.ipa` | Fastlane (Ruby `rename_artifact` helper) — applies to Fastlane lanes only |

**iOS caveat:** Xcode/Flutter's IPA export does not expose a clean per-flavor filename hook, so the IPA rename happens in Fastlane post-build. If you run `flutter build ipa --flavor staging` directly (no Fastlane), the output is still `pico.ipa` — distribution lanes via Fastlane normalize this automatically.

**Per-ABI APKs:** Passing `split_per_abi:true` to the Android lanes adds `--split-per-abi` to `flutter build apk`. Flutter then emits one APK per ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`), and the Fastfile renames each to `{AppName}-v{version}-{flavor}-{abi}.apk`. Firebase distribution requires a single APK, so the `distribute_firebase` lane defaults to `abi:arm64-v8a` when `split_per_abi:true` — override with the `abi:` parameter to ship a different variant.

The Fastlane Ruby `rename_artifact` helper is kept as a belt-and-suspenders no-op for APK/AAB (file is already correctly named) and the only rename mechanism for IPA. All distribution lanes (Firebase, Play Store, TestFlight, App Store) point at the renamed path.

## Build Prepare Integration

Every lane runs `build-prepare --flavor <flavor>` with the build's own flavor before building. Internal flavors (`internal_flavors` in `build_prepare.yaml`: development, staging, alpha, beta) keep the debugger and the Blackbox recorder, even in release mode. The production flavor, and any flavor not in that list, gets the noop twins. After the build, `build-prepare --check-leaks` fails a production build that still resolves a debug-only package, and `build-prepare --restore` puts the dependencies back, also when the lane fails. Monitoring is never swapped.

## Code Signing (iOS)

Code signing is managed via [fastlane match](https://docs.fastlane.tools/actions/match/). Certificates and profiles are stored in a private git repository.

- **Ad Hoc**: Used for Firebase App Distribution
- **App Store**: Used for TestFlight and App Store submissions

In CI, set `MATCH_PASSWORD` for decrypting the certificates repo.
