# Engine overview

This document is a **map of the runtime** for contributors and anyone evaluating Mugen Remake as a base for a 3D, data-driven fighter.

## Design goals

- **MUGEN-like authoring**: characters and stages are folders with `character.def`, JSON state files, and optional assets—not hard-coded behavior in the engine binary.
- **3D first**: fighters are skeletal meshes; stages are 3D scenes or imported environments.
- **Dual rulesets**: traditional round/timer fighters and stock / percent–style (Smash-like) modes share one core simulation path where possible.
- **Creator-friendly**: hitbox tools, JSON editor, stage editor, and import pipeline ship with the game UI.

## High-level flow

```mermaid
flowchart LR
  Title[TitleScreen] --> Main[MainMenu]
  Main --> MatchOpt[MatchOptionsMenu]
  MatchOpt --> CharSel[CharacterSelect]
  CharSel --> StageSel[StageSelect]
  StageSel --> Arena[TestArena + TestArenaController]
  Arena --> FighterA[FighterBase P1]
  Arena --> FighterB[FighterBase P2]
  FighterA --> StateCtrl[StateController]
  FighterB --> StateCtrl
  StateCtrl states.json
  FighterA --> Damage[DamageSystem]
  FighterB --> Damage
```

- **UI scenes** (`ui/`) drive mode selection, options, editors, and HUD.
- **Battle** lives under `stages/` (`TestArena.tscn` + `TestArenaController.gd`): round logic, teams, replays, online hooks, and HUD updates.
- **Fighters** are `FighterBase` instances driven by **StateController** (per-frame state machine from `states.json` and related data).

## Core engine modules (`engine/`)

| Module | Role |
|--------|------|
| `FighterBase.gd` | Character node: health, resources, animation, hitpause, team meta, Smash percent/stocks when enabled. |
| `StateController.gd` | Executes current state: controllers (hits, movement, spawns, audio, state transitions). |
| `CommandInterpreter.gd` | Reads `commands.json` and feeds the move buffer / state transitions. |
| `DamageSystem.gd` | Hit resolution, blocking, hitpause, damage application. |
| `HitboxSystem.gd` | Spatial queries for attacks, throws, push boxes, clash logic. |
| `ProjectileSystem.gd` / `ProjectileBase.gd` | Spawned attack entities from state controllers. |
| `ContentResolver.gd` | Resolves paths for mods (bundled `res://` vs `user://`). |
| `ModLoader.gd` | Loads character packs from disk trees. |
| `ContentImportService.gd` | glTF/glB import and scaffold generation for new mods. |
| `InputReplayRecorder.gd` | Record/playback for replays and debug. |
| `NetworkManager.gd` | Lightweight host/join for experimental online play. |
| `CameraController.gd` | Battle camera behavior. |
| `SystemSFX.gd` | Centralized UI/battle sound hooks. |

## Data layout (character)

Typical mod folder (under `user://mods/<Name>/` or `res://mods/<Name>/`):

- `character.def` — display name, model path, scale, defaults.
- `states.json` — state definitions and **controllers** (the backbone of behavior).
- `commands.json` — command patterns and linked states.
- `physics.json` — movement constants.
- Optional: `hurtboxes.json`, `projectiles.json`, `sounds.json`, `transformations.json`, `costumes.json`, etc.

See **[Character_Guide.md](Character_Guide.md)** for authoring detail.

## State controllers

State machine **controllers** are the programmable layer inside `states.json`. Full reference and recipes: **[STATE_CONTROLLERS_GUIDE.md](STATE_CONTROLLERS_GUIDE.md)**.

## Extending the engine

- **New gameplay**: prefer new controllers and states in JSON; touch `engine/` only when you need a new primitive (e.g. a new hit type or global rule).
- **New UI**: `ui/` scenes + `GlobalUITheme.tres`; battle HUD implements `set_battle_state` from `TestArenaController`.
- **Performance**: profile with Godot profiler; hot paths are per-frame state evaluation and hit detection.

## Related docs

- [IN_GAME_GUIDE.md](IN_GAME_GUIDE.md) — menus, modes, tools from a player/creator perspective.
- [Character_Guide.md](Character_Guide.md) — file-by-file character authoring.
- [STATE_CONTROLLERS_GUIDE.md](STATE_CONTROLLERS_GUIDE.md) — controller reference.
