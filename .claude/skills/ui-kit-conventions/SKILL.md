---
name: ui-kit-conventions
description: Use when building or editing Flutter widgets, pages, themes, or any UI code in this monorepo — including choosing colors, text styles, spacing, or assets.
---

# UI Kit Conventions

## Overview

All UI reads design tokens through the app UI kit's `BuildContext` extensions, never raw `Theme.of(context)` or hardcoded values. The UI kit follows atomic design (`atoms/`, `molecules/`, `organisms/`, `templates/`).

## Core pattern

```dart
// ❌ Never
color: Theme.of(context).colorScheme.primary,
padding: const EdgeInsets.all(16),
style: const TextStyle(fontSize: 14),

// ✅ Always — typed context extensions from the UI kit
color: context.colors.primary,
padding: EdgeInsets.all(context.spacing.md),
style: context.typography.bodyMedium,
```

Available extensions: `context.colors`, `context.typography`, `context.spacing`, `context.radius`, `context.shadow`, `context.assets`, plus `*OrNull` variants and `context.isDarkMode` / `context.isLightMode`.

## Rules

1. **Class-based widgets only.** Never extract UI into methods returning `Widget` (`Widget _buildHeader()`); create a widget class. Method widgets rebuild with the parent and defeat const/element reuse.
2. New reusable components go in the UI kit package under the correct atomic level; feature-specific composition stays in the feature's `presentation/` layer.
3. Assets via the generated type-safe asset classes (`context.assets` / the app asset package) — no raw asset path strings.
4. User-facing strings go through the slang/l10n setup (`AppLocale`, per-feature translations) — avoid hardcoding literals in widgets and cubits/blocs/notifiers.
5. Theme changes happen in the UI kit foundations (`colors`, `typography`, `spacing`, `radius`, `shadows` token files + `ThemeExtension`s) — never inline overrides scattered in features.
6. Preview new UI kit components in the Widgetbook app so the catalog stays complete.
7. Code entry uses the kit's `PicoOtpInput` (one-time codes: SMS autofill through the one-time-code hint, long-press paste, a semantic label) or `PicoPinInput` (PIN). Never build a code field from separate `TextField`s. The auth feature's phone OTP pages (when phone sign-in is on) are the reference.

## Common mistakes

| Mistake | Fix |
|---|---|
| `Theme.of(context).textTheme.bodyMedium` | `context.typography.bodyMedium` |
| `Widget _buildRow(BuildContext c)` helper methods | Extract a widget class |
| `EdgeInsets.all(12)` magic numbers | `context.spacing.*` tokens |
| `Image.asset('assets/images/logo.png')` | Generated asset constants |
| New button styled inline in a feature | Add/extend the UI kit atom and reuse |
| A row of `TextField`s for an OTP | `PicoOtpInput` |
