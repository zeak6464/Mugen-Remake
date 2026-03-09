# Mugen Remake

`Mugen Remake` is a Godot-based fighting game engine inspired by MUGEN, with support for 3D characters, data-driven movesets, stage imports, and in-engine editing tools.

The project is built around editable mod folders, JSON/DEF-driven character data, and a runtime that supports both traditional fighter behavior and platform-fighter style rules such as stocks, blast zones, and multi-jump characters.

## Current focus

- 3D character and stage workflow
- MUGEN-inspired data-driven authoring
- in-game editors and creator tools
- mod import pipeline for characters and stages
- support for traditional fighter systems and Smash-style rulesets

## Current features

- Game modes:
  - `Training`
  - `Arcade`
  - `2P Versus`
  - `Smash`
  - `Team`
  - `Survival`
  - `Watch`
- Character systems:
  - `states.json`, `commands.json`, `physics.json`, `character.def`
  - hitboxes, throwboxes, persistent hurtboxes
  - projectiles with custom visuals, trails, and projectile clashes
  - sound definitions via `sounds.json`
  - transformations/forms and costumes
  - multi-jump support
- Tools:
  - `Character Editor`
  - `Stage Editor`
  - `Model Viewer`
  - in-battle training menu and hitbox tools
- Content pipeline:
  - import `.glb` / `.gltf` characters and stages
  - auto-generate missing starter files
  - baseline import templates based on `CesiumMan`

## Tech stack

- `Godot 4.6+`
- `GDScript`
- data-driven runtime using JSON and DEF-style files

## Project layout

- `engine/` core runtime systems
- `ui/` menus, editors, viewers, and HUD
- `stages/` battle scene and arena controller
- `mods/` bundled sample characters/mod content
- `docs/` authoring and gameplay guides

## Getting started

1. Open the project in Godot.
2. Run the main scene.
3. Use the main menu to enter a mode, import content, or open the editors.

Default desktop play controls for `P1`:

- Move: `W A S D`
- `P`: `J`
- `K`: `K`
- `S`: `U`
- `H`: `I`
- Pause / training menu: `Esc`

## Modding workflow

Characters and stages can be authored directly in project folders or imported through the UI.

Typical character files:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- optional `sounds.json`
- optional `projectiles.json`
- optional `hurtboxes.json`
- optional `transformations.json`
- optional `costumes.json`

The runtime supports content from both:

- `res://mods/`
- `user://mods/`

Stages are scanned from:

- `res://stages/`
- `user://stages/`

## Documentation

- `docs/Character_Guide.md` character setup, files, commands, projectiles, sounds
- `docs/IN_GAME_GUIDE.md` menus, flow, modes, tools
- `docs/STATE_CONTROLLERS_GUIDE.md` controller reference and copyable recipes

## What this project is good for

- MUGEN-style characters with 3D models
- anime fighters and crossover fighters
- platform-fighter experiments with stocks and blast zones
- data-driven prototypes that need strong modding support

## Status

This project is actively focused on expanding engine coverage, creator workflow, and modding support rather than presenting itself as a finished commercial game.
