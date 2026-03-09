# In-Game Guide

This is the complete player and creator guide for the current game build.

It covers gameplay flow, menus, editors, mod folders, and data-driven systems that are already in the project.

## 1) Game Flow

1. Open `Main Menu`.
2. Pick a mode (`Training`, `Arcade`, `2P Versus`, `Smash`, `Team`, `Survival`, `Watch`).
3. Choose characters in `Character Select`.
4. Choose stage in `Stage Select`.
5. Fight in `TestArena`.
6. Use `Esc` for the in-battle pause/training menu.

## 2) Main Menu

Current menu entries:

- `Training Mode`
- `Arcade Mode`
- `2P Versus`
- `Smash Mode`
- `Team Mode` (with subtype and team size setup)
- `Survival Mode`
- `Watch Mode`
- `Model Viewer`
- `Character Editor`
- `Stage Editor`
- `Open Mods Folder`
- `Open Stages Folder`
- `Import Character`
- `Import Stage`
- `Options`
- `Quit Game`

Navigation:

- Move: `p1_*` or `p2_*` directional actions
- Confirm: `p1_p` / `p2_p`
- Cancel/back: `p1_k` / `p2_k`
- Ring page switch: `p1_h` / `p2_h` (previous), `p1_s` / `p2_s` (next)

Import workflow:

- `Import Character` and `Import Stage` accept either a single `.glb` / `.gltf` file or a whole folder
- Imported content is copied into `user://mods/` or `user://stages/`
- Missing starter files are auto-generated so the content is immediately visible in select/editor/runtime
- A post-import report lists generated files, warnings, and provides a direct button into the relevant editor
- Dragging a stage-like folder onto the main menu imports it as a stage; other dropped content is treated as a character starter by default

## 3) Character Select

### Roster behavior

- Supports all scanned mods from:
  - `user://mods/`
  - `res://mods/`
- Roster paging is fixed at 4 characters per page.
- Up/Down changes page, Left/Right moves inside the current page.
- Character folder panel supports forms/costumes selection.
- 3D preview shows model and updates by cursor target.

### Mode behavior

- `Training/Arcade/Survival`: primarily single-side draft flow.
- `Versus/Smash`: dual-side draft (`P1` and `P2`).
- `Team`: roster drafting per side with size limits (2-4).
- `Watch`: one controller can draft both CPU sides.

### Confirm flow

- Confirm locks current side selection.
- In team mode, each confirm appends roster picks until team size is reached.
- Cancel can unlock and step back depending on lock state.

## 4) Stage Select

- Scans stages from:
  - `user://stages/`
  - `res://stages/`
- Supports normal stage entries plus `Random`.
- Shows stage tile preview and 3D stage model preview when available.
- Stage selection is a 2-step ready flow:
  - First confirm locks stage.
  - Confirm again starts battle.
  - Cancel unlocks or returns back.

Controls:

- Move cursor: `P1` directions
- Confirm/ready/start: `p1_p`
- Back/unready: `Esc` or `p1_k`

## 5) Battle and Pause Menu

## Core battle controls (default P1)

- Move: `W A S D`
- Attack buttons:
  - `P`: `J`
  - `K`: `K`
  - `S`: `U`
  - `H`: `I`

Useful battle keys:

- Pause/training menu: `Esc`
- Round reset: `F5`
- Toggle dummy control: `F6`
- Toggle hitbox debug: `Backslash` or `F7`

### Pause/training menu

Current entries:

- `Resume`
- `Move List`
- `Button Config` (embedded controls menu)
- `Sound Config`
- `Exit to Character Select`
- `Exit to Main Menu`

When opened, battle pause is active and menu supports `P1/P2` navigation actions.

## 6) Game Modes

### Training

- Sandbox testing mode with pause/training tools.

### Arcade

- CPU progression flow using selected character and stage pathing.

### 2P Versus

- Standard player-vs-player style setup.

### Smash

- Stock-based ring-out behavior.
- Uses stage blast zones (`smash_blast_left/right/top/bottom`).
- Stock count reads from options (`smash stocks` setting).

### Team

- Subtypes:
  - `Simul`
  - `Turns`
  - `Tag`
- Team size per side: `2`, `3`, or `4`.
- Team metadata is passed from menu -> select -> arena runtime.

### Survival

- Survival mode flow with CPU enabled.

### Watch

- CPU-vs-CPU style battle flow with draft support.

## 7) Options Menu

Current configurable options include:

- Difficulty
- Life
- Time limit
- Smash stocks
- Game speed
- Resolution
- Master/SFX/BGM audio
- Input buffer display toggle
- Controls remap entry button

Action buttons:

- Load
- Save
- Defaults
- Back

Settings persistence:

- Stored in `user://options.cfg`

## 8) Model Viewer

Purpose:

- Browse mod character models directly from main menu.

Features:

- Mod list from `user://mods/` and `res://mods/`
- Prev/Next character cycling
- Animation selector (if model has `AnimationPlayer`)
- Mouse drag model rotation
- Zoom controls

Zoom controls:

- `p1_up` / `p2_up`: zoom in
- `p1_down` / `p2_down`: zoom out
- Mouse wheel: zoom in/out

## 9) Character Editor

Sections:

- `Box Tools`
- `Raw Files`
- `Preview`
- `Frame Data`

Highlights:

- Box editing uses the dedicated box workflow scene.
- Frame Data view reads from `states.json`.
- Persistent hurtboxes are part of box tools workflow.

## 10) Stage Editor

Purpose:

- Edit `stage.def` values with live 3D preview.

Editable fields include:

- Spawn points (`spawn_p1`, `spawn_p2`)
- Stage offset
- Floor Y
- Arena left/right limits
- Smash blast bounds
- Camera position + look target
- Music and stage metadata fields

Tools:

- Reload stage def from disk
- Save ordered `stage.def`
- Collision debug visibility toggle
- 3D preview markers (spawn, bounds, camera)

## 11) Content System (Mods and Stages)

### Character mods

Search roots:

1. `user://mods/`
2. `res://mods/`

Character core files:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- model (`.glb`/`.gltf`) or explicit `model_path`

### Stages

Search roots:

1. `user://stages/`
2. `res://stages/`

Stage core files:

- `stage.def`
- stage model (`.glb`/`.gltf`/scene)
- optional `preview.png`

## 12) UI Skin Overrides

Drop custom UI assets into `user://ui-skin/`:

- `textures/` backgrounds
- `audio/ui/` UI sounds
- `audio/battle/` battle sounds
- optional main menu video path support

## 13) Scripting and Authoring Docs

Use these alongside this guide:

- `README.md` (project overview + setup)
- `docs/STATE_CONTROLLERS_GUIDE.md` (full state controller reference)
- `README.md` -> `Commands Guide` section (`commands.json` patterns and behavior)
- `README.md` -> `Character Creation Guide`

## 14) Quick Troubleshooting

- Character missing in select:
  - check folder under `user://mods/` or `res://mods/`
  - verify `character.def` and model path
- Stage missing in select:
  - verify `stage.def` exists in stage folder
- Input mismatch:
  - open `Options` -> `Controls`
- No move list text:
  - move list pulls from runtime move list provider during battle pause
- Visual mismatch between editor/game:
  - prefer editor-authored scene layout and save/reload flow for editor data files
