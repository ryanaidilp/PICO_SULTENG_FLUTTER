# `.well-known/` — Digital Asset Links & Universal Links

This directory holds the two files that let a **web** origin vouch for your
**app**. They must be served, unmodified except for real values, at:

- `https://<your-domain>/.well-known/assetlinks.json` (Android)
- `https://<your-domain>/.well-known/apple-app-site-association` (iOS —
  serve without a `.json` extension and without a redirect; Apple and
  Google both fetch these over plain HTTPS, no auth, no query params)

They cover the primary app generated at `apps/pico` (if
this workspace grows additional apps via the `app_scaffold` brick, each new
app gets its own `.well-known/` inside its own app directory, following the
same conventions documented here).

Each file covers **two unrelated features**, distinguished by `relation`
(Android) or top-level key (iOS):

| Feature | Android relation | iOS key |
|---|---|---|
| Deep links / App Links | `delegate_permission/common.handle_all_urls` | `applinks` |
| Passkeys (WebAuthn) / Credential autofill | `delegate_permission/common.get_login_creds` | `webcredentials` |

If this project doesn't use the `auth_sdk` passkey path, you can delete the
`get_login_creds` statements from `assetlinks.json` and the `webcredentials`
block from `apple-app-site-association` — everything else keeps working.

## What needs a real value

### `TEAM_ID` (both files, `applinks` and `webcredentials`)

Your **Apple Developer Team ID** (10-character alphanumeric, e.g.
`ABCDE12345`), found in App Store Connect → Membership, or via
`xcrun altool --list-providers -u <apple-id>`. There is no generator-side
way to derive this — it's assigned by Apple per developer account.

### `RELEASE_SHA256_FINGERPRINT_PLACEHOLDER` (`assetlinks.json`)

The SHA-256 fingerprint of the certificate that signs your **release**
build. Only the project owner has this certificate, so it is never
generated automatically. Get it with:

```sh
keytool -list -v -keystore <path-to-your-release-keystore> \
  -alias <your-key-alias> -storepass <store-password> -keypass <key-password>
```

Look for the `SHA256:` line and copy the colon-separated hex value verbatim
into the `sha256_cert_fingerprints` array (keep the debug entry alongside
it — both certs need to validate while you still test debug/dev builds
against the production package name).

**Play App Signing caveat**: if this app is enrolled in Google Play App
Signing (the default for new Play Console apps), the certificate that ends
up on user devices is Google's **App Signing key**, not your local upload
keystore. Get the right fingerprint from Play Console → *Setup* → *App
signing* → *App signing key certificate*, not from your own `keytool -list`
output — they differ.

### `DEBUG_SHA256_FINGERPRINT_PLACEHOLDER` (`assetlinks.json`)

**Already filled in for you**, if `keytool` was available when this project
was generated — the post-generation hook computed it from the committed
`apps/pico/android/keystore/debug.keystore` (see below)
and substituted it into every `.dev` / `.stg` / base entry. If you still see
the literal placeholder text, `keytool` wasn't found at generation time;
run:

```sh
keytool -list -v -keystore apps/pico/android/keystore/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

and paste the `SHA256:` value in by hand (or just regenerate the project —
`keytool` just needs to be on `PATH`, e.g. from any JDK/Android Studio
install).

## The debug keystore

`apps/pico/android/keystore/debug.keystore` is committed
to this repository on purpose. It is a **debug** keystore — it signs
nothing distributable to end users — so unlike a release keystore, sharing
it is standard practice, not a secret leak. Its whole purpose is to make
every developer, every CI runner, and this `assetlinks.json` agree on the
same debug certificate, instead of each machine silently getting its own
random one from AGP's implicit `~/.android/debug.keystore` fallback (which
is what broke this before).

- Store password: `android`
- Key alias: `androiddebugkey`
- Key password: `android`

Regenerating this project into an existing output directory will **not**
overwrite an already-committed `debug.keystore` — the hook checks for it
first and reuses it as-is.

## The `android:apk-key-hash:` encoding (backend WebAuthn origin allow-list)

If a backend enforces `WEBAUTHN_RP_ORIGINS` (or similar) for native-app
callers, it typically wants the *same* certificate encoded differently:
`android:apk-key-hash:<base64url, no padding>` of the raw SHA-256 digest
bytes — not the colon-separated hex string above. Convert with:

```sh
keytool -exportcert -alias androiddebugkey \
  -keystore apps/pico/android/keystore/debug.keystore \
  -storepass android | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '='
```

The result is the value that goes after `android:apk-key-hash:` — do the
same for your release certificate when adding the release origin.

## Verifying publication

Once deployed, confirm the files are actually reachable and well-formed:

```sh
# Android — Google's own Digital Asset Links checker
curl "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://<your-domain>&relation=delegate_permission/common.handle_all_urls"

# iOS — fetch directly; must be served as application/json (or no
# Content-Type restriction issue) with no redirects, from the *apex* domain
# referenced by your associated domains entitlement
curl -I "https://<your-domain>/.well-known/apple-app-site-association"
curl "https://<your-domain>/.well-known/apple-app-site-association"
```

Also double-check the `associatedDomains` entitlement in Xcode
(`applinks:<your-domain>` and, for passkeys, `webcredentials:<your-domain>`)
and the Android Manifest's `autoVerify="true"` intent filter reference the
same domain these files are published under.
