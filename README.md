# Mugen Remake

**Mugen Remake** is a **Godot 4.6** fighting game **engine** inspired by MUGEN: **3D characters**, **folder-based mods**, **JSON/DEF-driven** movesets, and **in-engine tools** so creators can ship content without recompiling the game.

If you want a **next-gen “MUGEN but 3D”** foundation—traditional rounds *or* stock/percent rules—this repo is meant to be **forked, extended, and credited** as your own lane of the genre.

## Why use this instead of only MUGEN / other engines?

| | Mugen Remake |
|---|----------------|
| **Content model** | Mod folders: `character.def` + `states.json` + assets |
| **Rendering** | Full **3D** (Forward+), materials, stages as 3D scenes |
| **Rules** | **2D fighter** rounds + **Smash-like** stocks/percent in one codebase |
| **Tooling** | **Hitbox editor**, **stage editor**, **JSON editor**, **import** from glTF |
| **Stack** | **GDScript**, **Jolt** physics, small core—readable for contributors |

It is **not** a drop-in MUGEN bytecode emulator; it is a **spiritual successor** with a **modern pipeline** for 3D.

## Current focus

- 3D character and stage workflow  
- MUGEN-**inspired**, data-driven authoring  
- In-game editors and creator tools  
- Import pipeline for characters and stages  
- Traditional fighter systems **and** Smash-style rulesets  
- UX and documentation so **other developers** can adopt the engine  

## Current features

- **Game modes**: Training, Arcade, 2P Versus, Smash, Team (simul / turns / tag), Survival, Watch, Co-op vs CPU, Tournament flow, experimental online host/join  
- **Character systems**: `states.json`, `commands.json`, `physics.json`, `character.def`; hitboxes, throw boxes, persistent hurtboxes; projectiles with trails and clashes; `sounds.json`; transformations/forms and costumes; multi-jump  
- **Tools**: Character Editor, Stage Editor, Model Viewer, in-battle training menu  
- **Content pipeline**: import `.glb` / `.gltf`, scaffold starter files, bundled reference content  

## Tech stack

- **Godot 4.6+**  
- **GDScript**  
- Data-driven runtime: JSON + DEF-style files  

## Project layout

- `engine/` — core runtime (fighters, states, hits, damage, mods, import)  
- `ui/` — menus, editors, viewers, HUD  
- `stages/` — arena scene + `TestArenaController` (rounds, teams, HUD, replays)  
- `mods/` — bundled characters / examples  
- `docs/` — **[documentation index](docs/README.md)**  

## Getting started

1. Install **Godot 4.6** (match project features).  
2. Open this folder as a project.  
3. Run **Play** (starts at `TitleScreen`).  
4. Use the **ring menu** for modes, **Import** for glTF drops, **Editors** for data and collision.  

**Default P1 keys**

- Move: `W A S D`  
- Attack: `J` (`p1_p`)  
- Other: `K`, `U`, `I`  
- Pause / training menu: `Esc`  

Full flow and menus: [docs/IN_GAME_GUIDE.md](docs/IN_GAME_GUIDE.md).

## For developers & contributors

- **[docs/ENGINE_OVERVIEW.md](docs/ENGINE_OVERVIEW.md)** — architecture and module map  
- **[docs/ROADMAP.md](docs/ROADMAP.md)** — directional priorities  
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to contribute  

## Modding workflow

Characters and stages live under:

- `res://mods/` or `user://mods/`  
- `res://stages/` or `user://stages/`  

Typical character files include `character.def`, `states.json`, `commands.json`, `physics.json`, plus optional `sounds.json`, `projectiles.json`, `hurtboxes.json`, `transformations.json`, `costumes.json`, and more—see **[docs/Character_Guide.md](docs/Character_Guide.md)**.

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/README.md](docs/README.md) | Index of all docs |
| [docs/Character_Guide.md](docs/Character_Guide.md) | Character setup |
| [docs/IN_GAME_GUIDE.md](docs/IN_GAME_GUIDE.md) | Menus and tools |
| [docs/STATE_CONTROLLERS_GUIDE.md](docs/STATE_CONTROLLERS_GUIDE.md) | State controllers |

## What this project is good for

- MUGEN-style **rosters** with **3D** presentation  
- Anime / crossover fighters and rapid content iteration  
- **Platform-fighter experiments** (stocks, blast zones) sharing core tech with **traditional rounds**  
- **Research engines**: readable GDScript, fork-friendly structure  

## Status

**Active development**—expanding engine coverage, creator workflow, and modding story. The goal is to be an **engine people reach for** when they want **MUGEN’s modularity** in a **3D, Godot-native** package—not a single finished commercial SKU.
