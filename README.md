# Mugen Remake (Godot 4)

Mugen Remake is a **data-driven 3D fighting game engine** inspired by MUGEN.

The goal is to keep MUGEN-style flexibility (state machines, commands, editable character data, and mod folders) while moving to a full 3D character and stage pipeline in Godot.

## What This Project Is

This project is an engine/framework for building and testing fighting-game content, not just a single fixed game.

It is designed so creators can:

- Add characters and stages with JSON/DEF files
- Tune combat without hardcoding everything in scripts
- Use in-game editors for iteration
- Run multiple game modes (training, versus, smash-style, team, watch)

## Current Features

- Main menu with ring navigation and multiple game modes
- Character Select with 3D previews, forms/costumes, and roster paging
- Stage Select with 3D preview and ready-confirm flow
- Training/Arcade/Versus/Smash/Team/Survival/Watch modes
- Pause/training menu with move list, controls overlay, and sound config
- Data-driven combat core:
  - `states.json`
  - `commands.json`
  - `physics.json`
  - persistent `hurtboxes.json`
- Runtime mod/stage loading from `user://` and `res://`
- One-click import for dropped or picked `.glb` / `.gltf` characters and stages
- Character Editor, Box Tools, and Stage Editor
- Model Viewer (zoom + animation selector)
- VFX integration for hit/block/parry/KO feedback

## Why Data-Driven

Most gameplay behavior is authored in files instead of hardcoded logic per character.

That means you can:

- Prototype moves by editing JSON
- Add custom commands and state transitions
- Reuse systems across many characters
- Support modding workflows more easily

## Tech Stack

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Content:** JSON + DEF style metadata
- **3D Assets:** `.glb` / `.gltf`

## Project Structure

- `engine/` - combat, state machine, command interpreter, hitbox/damage systems, loaders
- `ui/` - menus, HUD, select screens, viewer, editors
- `stages/` - bundled stages (mirrored to `user://stages/`)
- `mods/` - bundled characters (mirrored to `user://mods/`)
- `docs/` - detailed guides
- `shaders/` - rendering shaders
- `addons/vfx_library/` - battle VFX addon

## Getting Started

1. Open the project in **Godot 4.6**.
2. Run `res://ui/MainMenu.tscn` (or press Play).
3. Pick a mode and start testing.

## Default Controls (P1)

- Move: `W A S D`
- `P`: `J`
- `K`: `K`
- `S`: `U`
- `H`: `I`

Useful battle keys:

- Pause/training menu: `Esc`
- Round reset: `F5`
- Toggle dummy control: `F6`
- Toggle hitbox debug: `Backslash` or `F7`

## Content Loading

Character roots are scanned in this order:

1. `user://mods/`
2. `res://mods/`

Stage roots are scanned in this order:

1. `user://stages/`
2. `res://stages/`

This allows local mod content to override bundled assets.

## Drag-And-Drop Import

You can now import starter content directly from the main menu.

- `Import Character` accepts a `.glb`, `.gltf`, or a folder and copies it into `user://mods/<name>/`
- `Import Stage` accepts a `.glb`, `.gltf`, or a folder and copies it into `user://stages/<name>/`
- Missing starter files are auto-generated so the new content appears in select/editor/runtime immediately
- The post-import report tells you what was generated, what was inferred, and what still needs cleanup

Generated character starters include:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- empty support files for hurtboxes, sounds, projectiles, transformations, and costumes

Generated stage starters include:

- `stage.def`
- auto-derived camera defaults
- floor, arena bounds, and blast zone defaults
- music placeholders

## Documentation

- Full player + editor overview: `docs/IN_GAME_GUIDE.md`
- Full state controller reference and examples: `docs/STATE_CONTROLLERS_GUIDE.md`

## Character Mod Quick Start

Create a folder:

- `mods/<YourCharacterName>/`

Minimum required files:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- model (`.glb` or `.gltf`) or explicit `model_path`

Recommended optional files:

- `hurtboxes.json` (persistent hurtboxes)
- `sounds.json`
- `projectiles.json`
- `transformations.json`
- `costumes.json`

## Stage Quick Start

Create a folder:

- `stages/<YourStageName>/`

Recommended files:

- `stage.def`
- stage model (`.glb`/`.gltf`/scene)
- `preview.png`

## UI Skin Overrides (Optional)

UI/audio overrides can be dropped into `user://ui-skin/`:

- `textures/` for menu backgrounds
- `audio/ui/` for UI SFX
- `audio/battle/` for battle event SFX

If override files exist, they are used; otherwise defaults are used.

## Status

The project is in active development and focused on expanding MUGEN-style parity and tooling in a 3D pipeline.
# Mugen Remake (Godot 4)

Data-driven 3D fighting engine inspired by MUGEN, built in Godot.

## Current Status

This project is in active development and already includes:

- Training mode
- Arcade mode (CPU opponent)
- 2P Versus mode
- Smash mode (stocks + percent + blast-zone ring-outs)
- Character Select and Stage Select
- Character and Stage editors
- Data-driven character/stage loading from `user://` and `res://`

## Guides

- Full in-game guide: `docs/IN_GAME_GUIDE.md`
- Detailed state controllers: `docs/STATE_CONTROLLERS_GUIDE.md`
- Command syntax/behavior: `README.md` -> `Commands Guide`
- Character authoring: `README.md` -> `Character Creation Guide`

## Run

1. Open the project in Godot 4.6.
2. Run the main scene (`res://ui/MainMenu.tscn`) or press Play.

## Project Structure

- `engine/` - core combat, state, command, hitbox, projectile, and loading systems
- `mods/` - bundled characters (copied to `user://mods/` at runtime)
- `stages/` - bundled stages (copied to `user://stages/` at runtime)
- `ui/` - menus, HUD, editor screens
- `shaders/` - character and stage shaders
- `addons/vfx_library/` - battle VFX addon (particles, freeze-frame helpers, screen effects)

## Battle VFX Integration

Battle VFX is now integrated through global autoloads in `project.godot`:

- `VFX` -> `res://addons/vfx_library/vfx.gd`
- `EnvVFX` -> `res://addons/vfx_library/env_vfx.gd`

Combat events trigger effects from `engine/FighterBase.gd` (`_on_combat_event`):

- `hit` / `throw_hit`: energy burst + short freeze-frame + damage number
- `block`: shield-break style feedback + short freeze-frame
- `parry` / `throw_tech`: combo ring + short freeze-frame
- `ko`: kill effect burst

The VFX anchor point is converted from 3D world position to screen space before spawning effects, so impacts follow fighters during battle.

## Character Mod Folder (Required Files)

Each character folder under `mods/<CharacterName>/` must include:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- A model file (`model.glb`, `model.gltf`, or another valid `.glb/.gltf` in folder)

Optional files:

- `sounds.json`
- `projectiles.json`
- `transformations.json`

The loader scans these roots in priority order:

1. `user://mods/`
2. `res://mods/`

