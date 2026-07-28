---
name: flutter-feature
description: Use this skill whenever creating, modifying or extending a Flutter feature. This skill defines the mandatory architecture, file structure and coding style for the entire project.
---

# Flutter Feature Architecture

This project follows a strict architecture.

These rules are mandatory.

---

# Feature Structure

Every feature lives in

lib/project_files/features/<feature_name>/

A feature with a screen and data behind it has three layers.

```
feature_name/
│
├── ui/
├── domain/
└── data/
```

Add a layer when something belongs in it, never to fill the shape.

- `splash/` owns no data, so it has `ui/` alone.
- `converter_shared/` owns no screen, so it has no page, view or bloc — its `ui/` is mappers and shared widgets.

---

# UI Layer

```
ui/
    feature_name_page.dart          dependency injection and BlocProvider only
    feature_name_view.dart          the screen

    bloc/
        feature_name_bloc.dart
        feature_name_event.dart
        feature_name_state.dart

    mappers/
        <domain_type>_ui.dart       String someKey(BuildContext) per domain value

    widgets/
        feature_name_body.dart      state + callbacks, nothing else
        feature_name_actions.dart   the bottom slot
        feature_name_callbacks.dart the action bundle
        …one file per extracted widget
```

Rules

- feature_name_page.dart is responsible ONLY for dependency injection and BlocProvider.
- feature_name_view.dart contains the actual screen.
- `mappers/` is not optional. No domain type carries user-facing copy, so everything a widget renders about a domain value is mapped here.
- A widget with more than one caller becomes its own file in `ui/widgets/`. A widget with exactly one caller stays private in that file as `_Name` — a file per single-use widget buys nothing and costs an import.
- Widgets inside widgets/ MUST never depend on their parent screen.

---

# Bloc

Business logic belongs ONLY inside Bloc.

Never place business logic inside Widgets.

Bloc MUST be split into

```
feature_name_bloc.dart
feature_name_event.dart
feature_name_state.dart
```

Every `on<Event>` registration passes an explicit `bloc_concurrency` transformer. Three are used, and each has one job.

- `restartable()` — the `<Feature>Started` event, which subscribes to a long-lived stream; a second start must not leave two subscriptions behind.
- `droppable()` — anything that opens a system dialog or a store sheet, or starts a run or a save; the OS shows one dialog, so extra taps must not queue up behind it.
- `sequential()` — everything else, because these handlers await a real file delete and the last tap has to be the one that wins.

`concurrent()` is used nowhere: no handler here is safe to interleave.

---

# Domain Layer

The domain layer contains interfaces and the models they pass.

```
domain/
    feature_repo.dart
    feature_storage.dart
    models/
```

Repositories inside domain MUST always be interfaces, declared as

```dart
abstract interface class MediaConverterRepo {}
```

`abstract interface class`, not `abstract class`: these exist to be implemented and never extended.

Models carry the rules that belong to them — `prunedFor`, `fromExtension`, `effectiveQuality` — so no bloc re-derives them.

The domain layer MUST NOT contain implementation details.

---

# Data Layer

Repository implementations belong ONLY here.

Name the implementation after what makes it different.

- One implementation with nothing to distinguish it takes `_impl`: `language_repo_impl.dart`, `usage_quota_repo_impl.dart`.
- Two or more take the technology or platform behind them, grouped in a folder of their own: `data/ffmpeg/ffmpeg_media_converter_repo.dart`, `data/file_access/io_media_file_repo.dart`, `data/engine/dart_pdf_converter_repo.dart`, `data/prefs_quota_storage.dart` — each with its refusing sibling `unsupported_*_repo.dart` beside it.
- A sibling that genuinely works in a reduced way is named for what it does rather than `unsupported_`: `free_only_subscription_repo.dart` serves a build with no store, and answers every call with a benign value instead of throwing.

If UseCases are required, they also belong here, in a folder of their own.

```
data/use_cases/login_use_case.dart
```

UseCases depend on the `domain/` interface, never on an implementation — that is what lets a test hand them a fake. Which implementation sits behind the interface is decided once, on the platform boundary in `data/platform/`.

Bloc MUST communicate ONLY with UseCases.

Flow

```
Bloc
    ↓
UseCase
    ↓
Repository Interface
    ↓
Repository Implementation
```

---

# Widget Structure

Every screen should be divided into small classes.

Avoid large build() methods.

A `build` returns one composition. When a branch needs an `if` or a `switch` over state, it becomes a named widget or a private method returning one, rather than a deeper tree.

---

# Screen Architecture

Every screen MUST follow this structure.

```
FeaturePage            dependency injection and BlocProvider only
    ↓
FeatureView            BlocListener, BlocBuilder, callbacks — no layout maths
    ↓
AppScreenLayout        lib/core/widgets — positioning only, slots via constructor
    ├── header:  AppScreenHeader(title:, subtitle:)
    ├── body:    FeatureBody(state:, callbacks:)
    └── bottom:  FeatureActions(state:, onConvertPressed:)
```

`AppScreenLayout` builds no content: every slot arrives through the constructor.

Correct example

```
AppScreenLayout(
    header: AppScreenHeader(...),
    body: FeatureBody(...),
    bottom: FeatureActions(...),
)
```

Incorrect

```
AppScreenLayout()

...

Widget build(...) {
    return Column(
        children: [
            Header(),
            Body(),
            Bottom(),
        ],
    );
}
```

A feature writes a layout of its own only where the shared one does not fit. `SplashLayout` is the single case, because splash has no header and no bottom.

Layout classes are responsible ONLY for alignment, spacing and positioning.

---

# Constants

Avoid magic numbers.

Avoid hardcoded values.

A value two files share lives in `lib/core/constants/app_*.dart`.

```dart
class AppSpacing {
    const AppSpacing._();

    static const double lg = 16;
}
```

A value only one widget uses is a private `static const` above that widget's fields, named for what it is.

```dart
static const double _gap = AppSpacing.lg;
static const double _iconSize = 28;
```

Widgets use those names instead of raw numbers — spacing, dimensions, radius, colors, durations, paddings, font sizes.

---

# Clean Code

Always write maintainable code.

Requirements

- Single Responsibility Principle
- Small methods
- Small widgets
- Meaningful naming
- No duplicated logic
- No dead code
- No unnecessary comments
- Prefer composition over inheritance

Extract code instead of making huge methods.

---

# Dependency Direction

Dependencies always point downward.

```
UI
    ↓
Bloc
    ↓
UseCase
    ↓
Repository Interface
    ↓
data/platform/<feature>_platform.dart      conditional export picks one
    ↓
real implementation    |    unsupported_ sibling
```

Never violate this direction.

---

# Goal

Generated code should be:

- modular
- reusable
- testable
- readable
- scalable
- predictable

Architecture consistency is more important than writing the fewest lines of code.

---

# Settled conventions

Each of these already holds across the codebase. Match it rather than inventing a second way.

This file owns the shapes — where a file goes, what it is called, what it declares. `CLAUDE.md` owns the rules whose violation nothing catches at build time: failures, conversion jobs, bloc state, the platform boundary, tests, doc comments. A rule belongs in one of the two, never both.

## Use cases

- **Add one**: one use case per file in `data/use_cases/`, plus the result type it needs (`PickedImages`) — a single public method named `call`, a `const` constructor taking `domain/` interfaces (named required parameters once there are several), and no state. It returns a domain model, a `Stream`, a `Future` or a job handle, never an `Either` or `Result` wrapper: a partial outcome gets a named model, and a failure is thrown as a `ConversionFailure`.
- **Use it**: a convert use case repeats the picker's guards on purpose, so the engine contract holds however the call was assembled. A repository that outlives a screen publishes changes as a `ValueListenable`, and a `watch*UseCase` adapts it to the `Stream` the bloc lives on.

## Domain models

- **Add one**: `final class X extends Equatable` with a `const` constructor, every field `final` and `props` last — or an enum with fields where the model is a closed set. `copyWith` goes only on the models the UI mutates; how it clears a nullable field is in `CLAUDE.md`, because a state class answers to the same rule.
- **Use it**: the rules live on the model — `prunedFor(target)`, `effectiveQuality`, `supportsQuality`, `fromExtension`, an `auto` value carrying `followsPreset` — so no bloc re-derives them and no two blocs derive them differently.

## Key–value storage

- **Add one**: `abstract interface class <X>Storage` in the feature's `domain/` root and `prefs_<x>_storage.dart` implementing it — one typed key per field named `'namespace.field'`, a `DateTime` stored as a `_millis` int, and `read()` returning `null` on a first run. `SharedPreferencesAsync` is built lazily behind an optional positional override, because the object is constructed while the app root is still building and a test needs a way in.
- **Use it**: clocks, periods and expiry are the repository's rules, which is what lets them be tested without a platform plugin; storage only reads and writes. A failed read or write is caught and answered from memory, so a broken store costs the user their next launch rather than this one.

## Screen callbacks

- **Add one**: `ui/widgets/<feature>_callbacks.dart` — `@immutable`, a `const` constructor, only `VoidCallback` and `ValueChanged<T>` fields where `T` is a domain type or the index the row needs, importing `foundation.dart` and domain models and nothing else. Fourteen separate parameters would make every widget signature a wall of arguments; one bundle keeps the widgets receiving nothing but functions.
- **Use it**: the view builds it in a private `_callbacks(context)` whose entries are one-line `_add(context, Event())` calls, apart from a navigation that is not an event. `context.read<Repo>()` appears only in `<feature>_page.dart` and `context.read<Bloc>()` only in `<feature>_view.dart`; nothing under `ui/widgets/` imports `flutter_bloc` or `go_router`.

## Routing

- **Add one**: one `AppRoute` enum entry carrying `path`, with `routeName => name` as the single source of truth, and one `GoRoute` in `app_router.dart`; a child of a category route takes a relative path and nests under it.
- **Use it**: navigate with `goNamed`, or `pushNamed` for a detour that has to come back — the paywall is pushed so returning lands on the batch already set up. Routes take no arguments: a screen reads what it needs from an app-wide repository.

## Engine arguments

- **Add one**: codec table (an enum whose fields hold each encoder's own quality scale) → target spec (`static Spec? of(Format)`, `null` for a format that can be read but never written) → builder (a `const X._()` static holder returning `List<String>` and throwing `ArgumentError` for a format with no encoder). The PDF engine has two of the three, because it has no codecs.
- **Use it**: per-format facts stay data in the spec table so the builder grows no limb per format, and a list rather than a string sidesteps quoting paths with spaces in them. The builder and the pure parsers beside it are unit-tested without an engine; the repository that spawns the process is not tested at all, because there is nothing in it but the spawn.
