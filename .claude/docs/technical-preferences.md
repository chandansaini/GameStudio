# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.3
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Rendering**: Forward+ (default), Mobile (optional), Compatibility (web/low-end)
- **Physics**: Godot Physics (default)

## Naming Conventions

- **Classes**: PascalCase (e.g. `PlayerController`)
- **Variables**: snake_case (e.g. `move_speed`)
- **Signals/Events**: snake_case past tense (e.g. `health_changed`)
- **Files**: snake_case matching class (e.g. `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g. `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g. `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60fps (mobile primary target)
- **Frame Budget**: 16.6ms
- **Draw Calls**: [TO BE CONFIGURED]
- **Memory Ceiling**: [TO BE CONFIGURED]

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

- **No singletons for game state** — use autoloads with explicit interfaces so systems remain independently testable
- **No hardcoded gameplay values** — all monster stats, class stats, floor tables, and tuning values must live in data resources (not in GDScript literals)

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
