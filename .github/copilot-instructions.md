# GitHub Copilot Instructions

This is a Flutter monorepo managed with Dart workspace + Melos.

## Key Conventions

- Use `dart format` for formatting (adds trailing newlines)
- Conventional commit messages (`feat:`, `fix:`, `refactor:`)
- Package imports only (no relative imports in `lib/`)
- API packages (`_api`) are pure Dart and depend only on `shared/dependencies_core`
- Never modify generated files (`*.g.dart`, `*.module.dart`, `*.gr.dart`); `*.module.dart` is committed, regenerate with `melos run build`

## Architecture

- **API/Impl split**: Contracts in `_api`, implementations in `_impl`
- **Dual-GetIt DI**: Global scope (SDKs, infra) + local scope per feature
- **Feature manifest + lazy SDK**: a const `FeatureManifest` in `FeatureSDKRegistry`, the SDK lazy behind an `_api` port
- **Two-phase init**: Pre-launch (blocking DI/routing) + post-launch (analytics, flags)
- **build_prepare**: Swaps debug tooling for its noop twin by build flavor (e.g. app_debugger -> app_debugger_noop). Only the production flavor (any flavor not in `internal_flavors`) gets the noops; internal release builds keep the tools. Monitoring is never swapped

## DI Pattern

```dart
// Infrastructure: microPackage pattern
@InjectableInit.microPackage()
void init() {}

// Features: a const manifest (routes) + a lazy SDK, in the global module
FeatureSDKRegistry.instance.register(const MyManifest());
gh.lazySingleton<MySDK>(MySDKImpl.new);
// Declare the module under `archipelago: di_modules:` in the feature's
// pubspec.yaml, then: dart run monorepo_toolkit generate host-registry
```

## Commands

```bash
dart pub get                    # Resolve workspace
melos run build                # Code generation
melos run analyze              # Static analysis
melos run test                 # Tests with coverage
melos run build-prepare:production # Production flavor: swap debug tooling to noop
```

Task guides (skills) are in `.claude/skills/<name>/SKILL.md`, indexed in `AGENTS.md`. For complete documentation, see `CLAUDE.md` in the workspace root.
