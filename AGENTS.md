# AI Agent Guide — Pico Flutter Monorepo

This document helps AI coding assistants (Claude Code, Cursor, GitHub Copilot, Windsurf, Cody, etc.) understand this project quickly.

## Agent-Specific Config Files

| Agent | Config File | Status |
|-------|------------|--------|
| Claude Code | `CLAUDE.md` | Full documentation |
| Cursor | `.cursorrules` | Summary + pointer to CLAUDE.md |
| GitHub Copilot | `.github/copilot-instructions.md` | Summary + pointer to CLAUDE.md |
| Windsurf | `.windsurfrules` | Create from `.cursorrules` pattern |
| Others | Read `CLAUDE.md` | Universal reference |

`CLAUDE.md` is the **single source of truth** for project documentation. All other agent config files are summaries that point to it.

## Quick Context for Any Agent

**What is this?** A Flutter monorepo with modular architecture, managed by Dart workspace + Melos.

**How is it organized?**
- `apps/` — Host apps
- `shared/` — Cross-cutting: DI, routing, config, locale, feature SDK contracts
- `infrastructure/` — Network, analytics, monitoring, feature flags, websockets (API/Impl split)
- `packages/` — UI kit, assets
- `utilities/` — Linting, logging
- `devtools/` — Build tooling

**Key patterns to know:**
1. **API/Impl split** — `_api` = contracts (pure Dart), `_impl` = vendor implementation
2. **Dual-GetIt** — Global DI (SDKs, infra) + local DI per feature
3. **Feature manifest + lazy SDK** — Each feature's global module registers a const `FeatureManifest` (routes) in `FeatureSDKRegistry` and its SDK as a lazy singleton behind an `_api` port; only boot-critical features are eager `FeatureSDK`s
4. **Two-phase init** — Pre-launch (blocking) + post-launch (non-blocking)
5. **Dependency barrels** — Import equatable, injectable, get_it, meta, flutter_bloc, auto_route and slang through `package:dependencies/<barrel>.dart` (Flutter packages) or `package:dependencies_core/<barrel>.dart` (`_api` and pure-Dart packages), never directly, and do not declare them in a pubspec
6. **build_prepare** — Swaps debug tooling for noop twins in production-flavor builds only (internal flavors keep it), and Marionette for its noop in every release or profile build (`--mode`)
7. **Marionette MCP** — Debug builds can be driven by an agent: `dart pub global activate marionette_mcp` once, `flutter run` in debug, then `connect` the `marionette` MCP server (registered in `.mcp.json`) to the VM service URI that `flutter run` prints. See "Driving the running app" in `CLAUDE.md`

**Essential commands:**
```bash
dart pub get                        # Resolve all packages
melos run build                     # Code generation (injectable, auto_route, envied)
melos run analyze                   # Static analysis
melos run test                      # Tests with coverage
melos run changelog -- --version X  # CHANGELOG.md entry from commits since the last v* tag
melos run deps:check                # Direct pins that drift or duplicate the barrels (deps:align, deps:diagnose)
melos run di:check                  # Injector regions and test harness match the pubspec declarations
melos run build-prepare:production  # Production release: swap debug tooling and Marionette to noop
```

**Don't:**
- Modify generated files (`*.g.dart`, `*.module.dart`, `*.gr.dart`, `*.config.dart`); regenerate with `melos run build`. `*.module.dart` is committed, the others are gitignored by default
- Edit the content of `archipelago:` marker regions by hand, or the files under `.archipelago/` (generation records; see the `archipelago-upgrade` skill)
- Use relative imports in `lib/` (use package imports)
- Add Flutter or vendor deps to `_api` packages (they depend on `shared/dependencies_core` only)
- Skip `dart format` after editing

**Do:**
- Read `CLAUDE.md` for full architecture documentation
- Run `dart analyze` after changes
- Follow conventional commit style
- Add `resolution: workspace` to new package pubspec.yaml files (the root workspace globs `features/**`, `infrastructure/**`, `packages/*`, ...)
- Declare DI modules under `archipelago: di_modules:` in the package's `pubspec.yaml`, run `dart run monorepo_toolkit generate host-registry`, then `melos run di:check`

## Skills

Task guides live in `.claude/skills/<name>/SKILL.md`. Claude Code loads them by their description; any other agent should read the matching file before starting the task. Bricks you generate later add their own rows here.

<!-- archipelago:agent_skills:start -->
| Skill | Use when |
|-------|----------|
| `feature-di-registration` | Creating or wiring a feature SDK, DI registration, features whose routes never appear |
| `generator-markers` | Editing files with `archipelago:` marker comments (bootstrap, initializers, injector, `build_prepare.yaml`) |
| `ui-kit-conventions` | Building widgets, pages or themes: tokens through the UI kit context extensions |
| `archipelago-upgrade` | Re-running a brick, a `Nothing was changed` stop, `archipelago upgrade`, files under `.archipelago/` |
| `ci-triage` | A CI run failed, was skipped or tested the wrong packages; changing the generated CI |
| `brand-assets` | Brand art in code: SVG icons and illustrations, python-lottie animations, festive logo/app icon/splash variants, Lottie `.json` <-> `.lottie`, wiring art into the asset package and Widgetbook (Pro) |
<!-- archipelago:agent_skills:end -->

Slash commands for Claude Code are in `.claude/commands/`.
