# Contributing

Thanks for helping make Mugen Remake a solid option for 3D, MUGEN-style fighters.

## Before you code

1. **Read** [docs/ENGINE_OVERVIEW.md](docs/ENGINE_OVERVIEW.md) for where logic lives.
2. **Prefer data over code**: new moves and mechanics should usually land in JSON/state controllers first.
3. **Scope PRs**: one feature or fix per branch keeps review fast.

## Environment

- **Godot 4.6+** (project targets 4.6; match the `config/features` in `project.godot`).
- Open the folder as a Godot project; main scene is `ui/TitleScreen.tscn`.

## Style (GDScript)

- Match surrounding file patterns: `@onready`, typed vars where the file already uses them, early returns.
- Avoid drive-by refactors in unrelated systems.
- No new dependencies unless discussed.

## Docs

- Author-facing behavior → update `docs/Character_Guide.md`, `docs/STATE_CONTROLLERS_GUIDE.md`, or `docs/IN_GAME_GUIDE.md`.
- Architecture or module map → `docs/ENGINE_OVERVIEW.md`.

## Testing (manual)

- Boot **Title → Main Menu → Training (or Versus)** with a bundled mod.
- If touching editors: open **Character Editor** and **Stage Editor** once.
- If touching combat: quick **Training** round + **pause menu**.

Automated tests are not required for every PR today; describe what you ran in the PR text.

## License

Check the repository root for a `LICENSE` file (or repository hosting metadata). Do not assume redistribution terms if none is published.
