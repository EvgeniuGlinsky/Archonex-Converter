---
name: flutter-feature
description: Use this skill whenever creating, modifying or extending a Flutter feature. This skill defines the mandatory architecture, file structure and coding style for the entire project.
---

# Flutter Feature Architecture

This project follows a strict architecture.

These rules are mandatory.

---

# Feature Structure

Every feature MUST be created inside

lib/project_files/features/<feature_name>/

Every feature MUST contain exactly three layers.

```
feature_name/
│
├── ui/
├── domain/
└── data/
```

---

# UI Layer

The UI folder MUST contain

```
ui/

feature_name_page.dart
feature_name_view.dart

bloc/
    feature_name_bloc.dart
    feature_name_event.dart
    feature_name_state.dart

widgets/
```

Rules

- feature_name_page.dart is responsible ONLY for dependency injection and BlocProvider.
- feature_name_view.dart contains the actual screen.
- Every reusable widget MUST be extracted into ui/widgets.
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

Whenever concurrent events are possible,
use bloc_concurrency transformers.

Examples

- droppable()
- restartable()
- sequential()
- concurrent()

Choose the correct transformer instead of using the default behaviour.

---

# Domain Layer

The domain layer contains interfaces.

Repositories inside domain MUST always be interfaces.

Example

```
abstract class UserRepository {}
```

Naming

```
feature_repo.dart
```

The domain layer MUST NOT contain implementation details.

---

# Data Layer

Repository implementations belong ONLY here.

Naming

```
feature_repo_impl.dart
```

If UseCases are required, they also belong here.

Example

```
login_use_case.dart
```

UseCases communicate with repository implementations.

Bloc MUST communicate ONLY with UseCases.

Never access repository implementations directly from Bloc.

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

Maximum recommended widget nesting is 3–5 levels.

Extract widgets whenever nesting becomes deeper.

---

# Screen Architecture

Every screen MUST follow this structure.

```
FeaturePage
    ↓
FeatureView
    ↓
FeatureLayout
        ↓
Header
        ↓
Body
        ↓
Bottom
```

FeatureLayout is responsible ONLY for positioning.

FeatureLayout MUST NOT create widgets.

FeatureLayout receives widgets through its constructor.

Correct example

```
FeatureLayout(
    header: Header(),
    body: Body(),
    bottom: Bottom(),
)
```

Incorrect

```
FeatureLayout()

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

Layout classes are responsible ONLY for alignment, spacing and positioning.

---

# Constants

Avoid magic numbers.

Avoid hardcoded values.

Every reusable value MUST be extracted.

Examples

- spacing
- dimensions
- radius
- colors
- durations
- paddings
- font sizes

Prefer static const members.

Example

```
class _Sizes {
    static const double pagePadding = 16;
    static const double buttonRadius = 12;
}
```

Widgets should use those constants instead of raw numbers.

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
Repository Implementation
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