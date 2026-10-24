# Deploy

Release the app, or distribute a test build. `apps/pico/fastlane/README.md` documents every lane, option, artifact name and environment variable.

## Input

$ARGUMENTS -- what to ship, e.g. "staging to Firebase", "1.4.0 to the stores"

## Test build (Firebase App Distribution)

```bash
cd apps/pico && bundle install
bundle exec fastlane android distribute_firebase flavor:staging   # split_per_abi:true abi:arm64-v8a for one ABI
bundle exec fastlane ios distribute_firebase flavor:staging
bundle exec fastlane distribute_all flavor:staging                # both
```

Needs `FIREBASE_ANDROID_APP_ID_<FLAVOR>` / `FIREBASE_IOS_APP_ID_<FLAVOR>` and, for iOS, match access.

## Store release

1. Set `version:` in `apps/pico/pubspec.yaml` (`1.4.0+<build>`).
2. `melos run changelog -- --version 1.4.0 --tag-pattern 'mobile/v*'` writes the `CHANGELOG.md` entry from the commits since the last release tag; review and commit it.
3. Tag and push: `git tag mobile/v1.4.0 && git push origin mobile/v1.4.0`. `.github/workflows/release-mobile.yml` builds the `production` flavor and uploads Android to the Play **internal** track and iOS to **TestFlight**; the build number is the workflow run number. Promote to production in the store consoles.
   Secrets: `GOOGLE_PLAY_JSON_KEY_BASE64`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `APPLE_ID`, `TEAM_ID`, `ITC_TEAM_ID`, `APP_IDENTIFIER`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`, optional `SLACK_WEBHOOK_URL`.
4. By hand:
   ```bash
   bundle exec fastlane android deploy_play_store flavor:production track:internal
   bundle exec fastlane ios deploy_testflight flavor:production
   bundle exec fastlane ios deploy_app_store flavor:production submit:true auto_release:true
   bundle exec fastlane deploy_all flavor:production   # Play Store + TestFlight
   ```

## What every lane does for you

`before_all` runs `build-prepare --flavor <flavor> --mode release`, so the production flavor ships the noop twins of the debug tooling and Marionette. After the build `--check-leaks` fails if a debug-only package still resolves, and `--restore` puts the dependencies back, also when the lane fails. Do not run `melos run build-prepare:production` before an internal (development, staging) build.

## When it fails

- `--check-leaks` failed: a debug package is still a dependency of the app outside the mapped swap. Find it with `dart pub deps` in `apps/pico` and add its pair to `build_prepare.yaml`.
- The workspace is left swapped (a killed lane): `dart run monorepo_toolkit build-prepare --restore`.
- iOS signing: `bundle exec fastlane match appstore --readonly` with `MATCH_PASSWORD` set.
