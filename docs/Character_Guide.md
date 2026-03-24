## Character Creation Guide

Related: **[ENGINE_OVERVIEW.md](ENGINE_OVERVIEW.md)** (runtime map) · **[STATE_CONTROLLERS_GUIDE.md](STATE_CONTROLLERS_GUIDE.md)** (state machine) · **[docs/README.md](README.md)** (index)

This is the fastest way to create a playable character for this project.

If you already have a `.glb`, `.gltf`, or a folder with a model inside it, you can now skip the manual starter setup:

- Open the main menu
- Choose `Import Character`
- Pick the model file or folder
- The game copies it into `user://mods/<name>/` and auto-generates the missing starter files
- Open the post-import report to jump straight into `Character Editor`

The generated starter gives you a playable baseline with `idle`, `walk`, `run`, `crouch`, `jump`, `fall`, `hitstun`, `ko`, `victory`, and simple attack states.

### 1) Create a mod folder

Create:

- `mods/<YourCharacterName>/`

Then add these files:

- `character.def`
- `states.json`
- `commands.json`
- `physics.json`
- one model (`model.glb` or `model.gltf`, or use `model_path` in `character.def`)

Recommended optional files:

- `hurtboxes.json` (persistent always-on hurtboxes)
- `sounds.json`
- `projectiles.json`
- `transformations.json`
- `costumes.json`
- `parts.json` (optional; separate `.glb` / `.gltf` per slot on one base rig)

---

### `parts.json` (mix-and-match / Mii-style)

Use this when each slot is its **own imported file** (authors drop meshes into the mod folder), all skinned to the **same skeleton/bone names** as `base_model`.

| Key | Description |
|-----|-------------|
| `enabled` | If `true`, load `base_model` and merge every non-empty `slots` entry. |
| `base_model` | Path relative to the mod folder (or `res://` / `user://`). Must contain a `Skeleton3D`. |
| `slot_order` | Optional array of slot names; **draw order** (earlier = underneath). Slots not listed are appended after. |
| `slots` | Map of slot name → path to a part `.glb` / `.gltf` (empty string = skip). |

Example:

```json
{
  "enabled": true,
  "base_model": "body_base.glb",
  "slot_order": ["torso", "head", "hair", "accessory_1"],
  "slots": {
    "torso": "parts/shirt_red.glb",
    "head": "parts/head_neutral.glb",
    "hair": "parts/hair_spiky.glb",
    "accessory_1": ""
  }
}
```

**Authoring rules:** Part files must match the base skeleton (bone names/rest pose). Meshes are reparented to the base skeleton with identity local transform; offset your mesh in the DCC if needed.

**Note:** Costume `model_path` swaps replace the whole assembled model; use parts **or** full costume swaps unless you extend the pipeline.

---

### `costumes.json` (alt models + per-costume shader)

```json
{
  "costumes": {
    "alt_red": {
      "model_path": "costumes/body_red.glb",
      "shader_path": "res://shaders/character_toon.gdshader",
      "shader_user_uniforms": {
        "base_tint": [1.0, 0.2, 0.2, 1.0],
        "rim_power": 2.5
      }
    },
    "glow": {
      "shader_path": "my_cel.gdshader",
      "shader_user_uniforms": "{\"shade_steps\":4}"
    }
  }
}
```

| Key | Description |
|-----|-------------|
| `model_path` | Optional. Same rules as `character.def` `model_path` (relative to mod). |
| `shader_path` | Optional. Overrides `character.def` for this costume only (relative to mod or `res://` / `user://`). |
| `shader_user_uniforms` | Optional. Object or JSON string. Merged on top of `character.def`’s `shader_user_uniforms` (costume keys win). |

If you omit `shader_path`, the costume keeps the base character shader and only uniform overrides apply. Switching back to the default costume restores `character.def` shading.

---

### 2) `character.def` (character metadata)

Example:

```ini
name = MyFighter
display_name = My Fighter
author = You
version = 1.0
initial_state = idle

model_path = model.glb
model_offset_y = 0.0
model_scale = 1.0

collision_scale = 1.0
ground_offset_y = 0.0

max_resource = 100
starting_resource = 0
max_juggle_points = 6

hurtboxes_file = hurtboxes.json
```

Notes:

- `model_path` can be relative (`model.glb`) or absolute (`res://...`, `user://...`).
- `hurtboxes_file` is for persistent bone hurtboxes (recommended).
- `hurtbox_source = mesh_derived` generates persistent hurtboxes from the loaded runtime mesh when you do not want to author `hurtboxes.json` by hand.

---

### 3) `physics.json` (movement)

Example:

```json
{
  "weight": 100,
  "walk_speed": 3.2,
  "run_speed": 6.0,
  "initial_dash": 6.2,
  "jump_speed": 7.5,
  "gravity": 18.0,
  "max_fall_speed": 25.0,
  "fast_fall_speed": 32.0,
  "air_speed": 2.72,
  "air_accel": 0.45,
  "max_jumps": 1
}
```

Supported keys used by runtime:

| Key | Description | Default |
|-----|-------------|--------|
| `weight` | Character weight; higher = less knockback (e.g. in Smash). | 100 |
| `walk_speed` | Horizontal speed while walking. | 3.2 |
| `run_speed` | Horizontal speed while running (after initial dash). | 6.0 |
| `initial_dash` | Speed on the first frame of run (dash). | same as `run_speed` |
| `jump_speed` | Initial upward speed on jump. | 7.5 |
| `gravity` | Downward acceleration per second. | 18.0 |
| `max_fall_speed` | Terminal fall speed (cap on downward velocity). | 25.0 |
| `fast_fall_speed` | Fall cap when holding down in air (fast fall). | ~1.28× `max_fall_speed` |
| `air_speed` | Max horizontal air speed (Smash / air control). | derived from walk |
| `air_accel` / `total_air_accel` | Air horizontal acceleration. | 0.45 |
| `max_jumps` | Number of mid-air jumps. | 1 |
| `smash_air_speed` | Override air speed in Smash mode. | uses `air_speed` |
| `smash_air_accel` | Override air accel in Smash mode. | uses `air_accel` |
| `smash_air_brake` | Air deceleration when releasing horizontal input. | 0.2 |
| `sh_frames`, `fh_frames`, `shff_frames`, `fhff_frames` | Optional frame data (Short Hop, Full Hop, etc.) for display/tools. | (optional) |

---

### 4) `commands.json` (input to state mapping)

Example:

```json
{
  "commands": [
    {
      "id": "p_light",
      "pattern": ["P"],
      "max_window": 8,
      "min_repeat_frames": 8,
      "target_state": "p_light"
    },
    {
      "id": "qcf_p",
      "pattern": [2, 3, 6, "P"],
      "max_window": 20,
      "min_repeat_frames": 12,
      "target_state": "qcf_p"
    }
  ]
}
```

Pattern rules:

- Numbers = numpad directions (`2` down, `6` forward, etc.)
- `"P"`, `"K"`, `"S"`, `"H"` = attack buttons

---

### 5) `states.json` (state machine + attacks)

Minimum structure:

```json
{
  "idle": {
    "animation": "idle",
    "allow_movement": true,
    "cancel_into": ["p_light"],
    "hitboxes": [],
    "throwboxes": [],
    "pushboxes": [],
    "hurtboxes": [],
    "next": {}
  },
  "p_light": {
    "animation": "attack_light",
    "allow_movement": false,
    "cancel_into": [],
    "hitboxes": [
      {
        "id": "p_light_1",
        "start": 3,
        "end": 5,
        "bone": "",
        "offset": [1.0, 1.0, 0.0],
        "size": [1.2, 0.8, 0.8],
        "data": {
          "damage": 30,
          "hitstun_frames": 12,
          "blockstun_frames": 8,
          "pushback": [1.0, 0.0, 0.0],
          "on_hit_adv": 2,
          "on_block_adv": -5,
          "on_hit_result": "Hit"
        }
      }
    ],
    "throwboxes": [],
    "pushboxes": [],
    "hurtboxes": [],
    "next": { "frame": 20, "id": "idle" }
  }
}
```

Important:

- Keep per-state `hurtboxes` empty unless you explicitly want legacy per-animation hurtboxes.
- Preferred workflow is persistent hurtboxes in `hurtboxes.json`.

**Frame data (hitbox `data`):** You can add optional keys for display and tools (Character Editor shows them as “Frame data” / “Properties on Hit/Block”):
- `on_hit_adv` (number): Frame advantage when the move hits (e.g. `2` = +2 on hit).
- `on_block_adv` (number): Frame advantage when the move is blocked (e.g. `-5` = -5 on block).
- `on_hit_result` (string, optional): Label for hit result, e.g. `"Hit"`, `"Knockdown"`, `"Launch"`. If omitted, the editor infers “Knockdown” when `knockdown` is true.

- **Smash mode % damage:** In Smash mode, the value added to the defender's percent is normally `damage`. Set `smash_percent` or `smash_damage` in hitbox data to use a different % for Smash (e.g. `damage`: 30, `smash_percent`: 12 for 12% in Smash).

Startup / active / recovery are derived from hitbox `start`/`end` and state `next.frame`.

---

### 6) `hurtboxes.json` (persistent hurtboxes, recommended)

Use either format:

```json
{
  "hurtboxes": [
    { "id": "torso", "bone": "spine", "offset": [0.0, 0.0, 0.0], "size": [1.0, 1.1, 0.8] },
    { "id": "head", "bone": "head", "offset": [0.0, 0.0, 0.0], "size": [0.55, 0.55, 0.55] }
  ]
}
```

or:

```json
[
  { "id": "torso", "bone": "spine", "offset": [0.0, 0.0, 0.0], "size": [1.0, 1.1, 0.8] },
  { "id": "head", "bone": "head", "offset": [0.0, 0.0, 0.0], "size": [0.55, 0.55, 0.55] }
]
```

These are always active and bone-following in runtime.

---

### 6.5) Mesh-derived persistent hurtboxes

If you want the engine to build the baseline hurtboxes from the character mesh at runtime, add this to `character.def`:

```ini
hurtbox_source = mesh_derived
```

Notes:

- This uses the loaded model mesh plus the runtime skeleton to generate a small persistent body profile.
- The generated profile is intended as a baseline for gameplay and training-mode debugging, not exact triangle collision.
- `hurtboxes_file` still wins if you provide both. Use `mesh_derived` when you want automatic baseline hurtboxes instead of hand-authored ones.
- `CesiumMan` now uses this mode as the sample baseline.

---

### 6.6) `sounds.json` (character audio)

Character sounds are defined by sound ID in `sounds.json`. Those IDs can then be triggered from a state's `sounds` timeline, from a `PlaySnd` controller, or by built-in combat event fallbacks that look up common IDs such as `hit_light`, `hit_heavy`, `guard`, `parry`, `throw_start`, `throw_hit`, and `ko`.

Example `sounds.json`:

```json
{
  "swing_light": {
    "path": "sounds/swing_light.ogg",
    "volume_db": -4.0,
    "pitch_scale": 1.0,
    "bus": "Master"
  },
  "hit_heavy": {
    "path": "sounds/hit_heavy.ogg",
    "volume_db": -1.0,
    "pitch_scale": 0.9,
    "bus": "Master"
  },
  "voice_attack": {
    "path": "voice/attack_01.ogg",
    "volume_db": -2.0,
    "pitch_scale": 1.0,
    "bus": "Master"
  }
}
```

Notes:

- `path` can be relative to the character mod folder, or absolute via `res://` / `user://`.
- Supported runtime formats are `.ogg`, `.mp3`, and `.wav`.
- `volume_db`, `pitch_scale`, and `bus` are optional.
- When a sound is played with channel `voice`, the engine routes it to the fighter's voice player. Otherwise it uses the normal SFX player.

Example state timeline usage:

```json
"sounds": [
  { "frame": 4, "id": "swing_light", "channel": "sfx" },
  { "frame": 1, "id": "voice_attack", "channel": "voice" }
]
```

Example controller usage:

```json
{ "type": "PlaySnd", "id": "voice_attack", "channel": "voice", "trigger1": "time = 1", "persistent": 0 }
```

---

### 6.7) `projectiles.json` (projectile data + visuals)

Projectiles are defined in `projectiles.json`, then spawned from a state by listing them in that state's `projectiles` timeline.

Example `projectiles.json`:

```json
{
  "projectiles": [
    {
      "id": "fireball_light",
      "speed": 8.0,
      "lifetime_frames": 120,
      "spawn_offset": [1.0, 1.0, 0.0],
      "size": [0.45, 0.45, 0.45],
      "despawn_on_hit": true,

      "visual_path": "res://mods/MyFighter/projectiles/fireball.glb",
      "visual_scale": [1.0, 1.0, 1.0],
      "visual_offset": [0.0, 0.0, 0.0],
      "visual_rotation_degrees": [0.0, 0.0, 0.0],
      "visual_animation": "loop",
      "visual_animation_speed": 1.0,
      "visual_animation_loop": true,
      "visual_face_velocity": true,
      "visual_yaw_offset_degrees": 0.0,
      "visual_tint": [1.0, 0.72, 0.2, 0.78],
      "visual_emission": [1.0, 0.58, 0.16, 1.0],
      "visual_unshaded": true,
      "visual_double_sided": true,

      "trail_enabled": true,
      "trail_color": [1.0, 0.55, 0.18, 0.72],
      "trail_emission": [1.0, 0.42, 0.12, 1.0],
      "trail_size": [0.28, 0.16],
      "trail_lifetime": 0.25,
      "trail_amount": 18,

      "hit_data": {
        "damage": 65,
        "pushback": [3.2, 0.0, 0.0],
        "launch_velocity": [4.0, 2.4, 0.0],
        "hitstun_state": "hitstun",
        "hit_sound": "hit_heavy"
      }
    }
  ]
}
```

Example `states.json` entry that spawns it:

```json
"qcf_p": {
  "animation": "bs01",
  "allow_movement": false,
  "projectiles": [
    { "frame": 8, "id": "fireball_light" }
  ],
  "next": { "frame": 18, "id": "idle" }
}
```

Notes:

- `visual_path` can point to a `.glb`, `.gltf`, or scene file.
- If `visual_path` is missing or fails to load, the engine falls back to the built-in glowing box projectile.
- `model_path` / `model_scale` are also accepted as aliases for `visual_path` / `visual_scale`.
- Projectile-vs-projectile clashes now cancel both projectiles on contact when they belong to opposing fighters/teams.
- Same-owner and same-team projectiles do not cancel each other.

---

### 7) Grapples and throws

Use `throwboxes` in a state (not regular strike hitboxes). Two styles:

**Grapple then throw (hold):** Attacker grabs the defender for a short time, then throws them on release (damage/launch apply). Unblockable; defender can throw tech with the right command. Set `grapple_hold`: true (default). This is “grapple then throw”: grab → hold → release with throw.

**Throw (instant):** Unblockable command grab that applies damage and launch as soon as the throwbox connects. No hold. Set `grapple_hold`: false, or `instant_throw`: true.

Example – grapple (hold):

```json
"throwboxes": [
  {
    "id": "throw_1",
    "start": 4,
    "end": 6,
    "bone": "hand.R",
    "offset": [0.6, 0.0, 0.0],
    "size": [0.8, 0.8, 0.8],
    "data": {
      "attack_type": "grapple",
      "grapple": true,
      "grapple_hold": true,
      "damage": 110,
      "grab_duration_frames": 12,
      "grabbed_state": "grabbed",
      "grapple_state": "hitstun",
      "throw_tech_enabled": true,
      "throw_tech_window": 6
    }
  }
]
```

Example – throw (instant):

```json
"throwboxes": [
  {
    "id": "throw_instant_1",
    "start": 5,
    "end": 7,
    "bone": "",
    "offset": [0.8, 1.0, 0.0],
    "size": [0.7, 0.8, 0.8],
    "data": {
      "attack_type": "grapple",
      "grapple": true,
      "grapple_hold": false,
      "damage": 90,
      "launch_velocity": [0.5, 4.0, 0.0],
      "hitstun_state": "hitstun",
      "hitstun_frames": 24
    }
  }
]
```

You can use `instant_throw`: true instead of `grapple_hold`: false. For instant throws you typically set `launch_velocity`, `hitstun_frames`, and optionally `knockdown`; no `grab_duration_frames` or `grabbed_state`.

**Different throw from same grab (forward / back):** For grapple-then-throw, you can give two release outcomes. Add to the throwbox `data`:

- `release_forward`: dict with damage, launch_velocity, pushback, hitstun_frames, etc. Used when the attacker holds **forward** (toward the defender) at release.
- `release_back`: dict for when the attacker holds **back** at release.

Base `damage`, `launch_velocity`, etc. are used if no direction is held or as fallback. Example: base damage 80, `release_forward`: `{ "damage": 100, "launch_velocity": [0.8, 5, 0] }`, `release_back`: `{ "damage": 70, "launch_velocity": [-0.5, 4, 0] }`.

- **Grabbed defender can attack:** In throwbox data, `grabbed_can_attack` (default true) lets the defender keep input while grabbed so they can cancel into an attack state (e.g. `grabbed_jab`) and hit the grabber. In that attack's hitbox `data`, set `grapple_escape_frames` (e.g. 15) so each hit shortens the grab; when the grabber's hold reaches 0 the grapple releases. Use `grabbed_can_attack`: false to disable (defender cannot attack out).

Optional anti-spam tuning:

- `grapple_whiff_cooldown_frames` in throw/grapple data.

---

### 8) Test in-game

1. Launch game.
2. Open Character Select and pick your mod.
3. If model does not appear, verify:
   - `character.def` path keys
   - model file exists and is valid `.glb/.gltf`
4. If attacks do nothing, verify:
   - command `target_state` exists in `states.json`
   - hitbox `start/end` frames are valid

---

### 9) Editor workflow (recommended)

- Use `Character Editor -> Box Tools`:
  - Edit `hitboxes`, `throwboxes`, `pushboxes` per state
  - Edit `Persistent Hurtboxes` for always-on body volumes
- Save from editor to write both:
  - `states.json`
  - `hurtboxes.json`

## Commands Guide

This section explains how `commands.json` works in this engine.

### File format

Use this root shape:

```json
{
  "commands": [
    {
      "id": "p_light",
      "pattern": ["P"],
      "max_window": 8,
      "min_repeat_frames": 8,
      "target_state": "p_light"
    }
  ]
}
```

Each command entry supports:

- `id` (string): unique command name
- `pattern` (array): input pattern tokens (required)
- `max_window` (int): how many recent frames to search
- `min_repeat_frames` (int): re-trigger delay for same command
- `target_state` (string): state to enter on match

Optional transform keys:

- `transform_to`
- `transform_state`
- `revert_transform`

### Pattern tokens

Supported pattern token types:

- Direction ints: `1` to `9` (numpad notation)
- Button strings: `"P"`, `"K"`, `"S"`, `"H"`
- Hold/release strings:
  - `"hold:P"`
  - `"release:P"`

Direction reference:

- `1` down-back
- `2` down
- `3` down-forward
- `4` back
- `5` neutral
- `6` forward
- `7` up-back
- `8` up
- `9` up-forward

Directions are mirrored by facing, so `6` always means "forward".

### Matching behavior

- The final token must happen on the latest frame.
- Older tokens are searched backward within `max_window`.
- Same command cannot retrigger until `min_repeat_frames` passes.
- Even on input match, state transition must still pass runtime rules (`cancel_into`, `cancel_windows`, locks).

### Examples

Single button normal:

```json
{
  "id": "p_light",
  "pattern": ["P"],
  "max_window": 8,
  "min_repeat_frames": 8,
  "target_state": "p_light"
}
```

QCF + P:

```json
{
  "id": "qcf_p",
  "pattern": [2, 3, 6, "P"],
  "max_window": 20,
  "min_repeat_frames": 12,
  "target_state": "qcf_p"
}
```

Double tap run:

```json
{
  "id": "run_forward",
  "pattern": [6, 6],
  "max_window": 10,
  "min_repeat_frames": 10,
  "target_state": "run"
}
```

Transform on:

```json
{
  "id": "transform_on",
  "pattern": [2, 1, 4, "S"],
  "max_window": 20,
  "min_repeat_frames": 12,
  "transform_to": "power_form",
  "transform_state": "transform_start"
}
```

Transform off:

```json
{
  "id": "transform_off",
  "pattern": [2, 3, 6, "S"],
  "max_window": 20,
  "min_repeat_frames": 12,
  "revert_transform": true,
  "transform_state": "transform_end"
}
```

### Throw / grapple notes

- Commands only request throw state entry.
- Actual throw success is controlled by `throwboxes` and runtime checks (tech, invuln, whiff lockout).

## Stage Folder

Each stage folder under `stages/<StageName>/` should include:

- `stage.def` (recommended)
- At least one `.glb` or `.gltf` stage model

The stage system scans:

1. `user://stages/`
2. `res://stages/`

## Default Controls (P1)

From `project.godot` defaults:

- Move: `W A S D`
- `P`: `J`
- `K`: `K`
- `S`: `U`
- `H`: `I`

Other useful keys in battle:

- Training menu: `Esc`
- Round reset: `F5`
- Toggle dummy control: `F6`
- Toggle hitbox debug: `Backslash` or `F7`

## Notes

- Custom key rebinding is available from `Options -> Controls` (currently P1 actions).
- The project bootstraps bundled `res://mods` and `res://stages` into `user://` so exported builds can still use add-on content in the user folder.

## Drag-and-Drop UI Skin Folder

UI skin overrides can be dropped into `user://ui-skin/` (created automatically at runtime):

- `user://ui-skin/textures/`
  - `main_menu_bg.png` (or `.webp/.jpg/.jpeg`)
  - `options_menu_bg.png`
  - `controls_menu_bg.png`
  - `character_select_bg.png`
  - `stage_select_bg.png`
- `user://ui-skin/audio/ui/`
  - `ui_move.ogg` (or `.wav/.mp3`)
  - `ui_confirm.ogg`
  - `ui_back.ogg`
- `user://ui-skin/audio/battle/`
  - Optional battle event sounds matching IDs in `SystemSFX` (e.g. `battle_hit.ogg`, `round_fight.ogg`)

If an override file exists, it is used automatically. If missing, engine defaults are used.

## MUGEN Controller Parity (Phase 1)

State files now support a `controllers` array in each state entry (in addition to existing fields like `next`, `hitboxes`, and `velocity`).

For full details and examples, see `docs/STATE_CONTROLLERS_GUIDE.md`.

Supported controller types:

- `ChangeState`
- `SelfState`
- `CtrlSet`
- `Null`
- `Turn`
- `VelSet`
- `VelAdd`
- `VelMul`
- `PosSet`
- `PosAdd`
- `PowerAdd`
- `PowerSet`
- `LifeAdd`
- `LifeSet`
- `PlaySnd`
- `ChangeAnim`
- `ChangeAnim2`
- `Projectile`
- `TargetState`
- `TargetLifeAdd`
- `TargetPowerAdd`
- `TargetVelSet`
- `TargetVelAdd`
- `TargetPosSet`
- `TargetPosAdd`
- `Pause`
- `NotHitBy`
- `AttackMulSet`
- `DefenceMulSet`
- `AssertSpecial`
- `Gravity`
- `TargetFacing`
- `ScreenBound`
- `StopSnd`
- `HitOverride`
- `HitAdd`
- `HitFallVel`
- `MoveHitReset`
- `HitBy`
- `PosFreeze`
- `Trans`
- `Offset`
- `PlayerPush`
- `VarRandom`
- `VarRangeSet`
- `HitFallSet`
- `HitFallDamage`
- `EnvShake`
- `EnvColor`
- `SndPan`
- `SprPriority`
- `BindToTarget`
- `TargetBind`
- `SuperPause`
- `ReversalDef`
- `TargetDrop`
- `Width`
- `VictoryQuote`
- `Explod`
- `RemoveExplod`
- `ModifyExplod`
- `AfterImage`
- `AfterImageTime`
- `PalFX`
- `AngleSet`
- `AngleAdd`
- `AttackDist`
- `FallEnvShake`
- `ForceFeedback`
- `DisplayToClipboard`
- `ClearClipboard`
- `AppendToClipboard`
- `Helper`
- `ParentVarSet`
- `ParentVarAdd`
- `BindToRoot`
- `BindToParent`
- `DestroySelf`
- `StateTypeSet`
- `VarSet`
- `VarAdd`
- `FVarSet`
- `FVarAdd`

Common controller fields:

- `type`: controller name
- `persistent`:
  - `0` = run once per state entry
  - `1` = run every tick (default)
  - `N > 1` = run every N ticks
- `ignorehitpause`: if `true`, controller can run while in hitpause
- `triggerall`, `trigger1..n`: optional conditional triggers (MUGEN-style OR groups with shared AND gate)

Controller parameter examples:

- `ChangeState`: `value` (target state), optional `ctrl`, optional `anim`
- `SelfState`: alias of `ChangeState` in this engine
- `CtrlSet`: `value` (0/1 or false/true)
- `Null`: explicit no-op controller
- `Turn`: flips the fighter facing direction
- `VelSet` / `VelAdd` / `VelMul`: `x`, `y`, `z` (or `value` as array/dictionary)
- `PosSet`: sets world position (`x`, `y`, `z`)
- `PosAdd`: adds position offsets (`x`, `y`, `z`), with optional `facing_relative` (default `true`)
- `PowerAdd`: adds/subtracts resource meter via `value` (or `amount`)
- `PowerSet`: sets resource meter directly via `value` (or `amount`)
- `LifeAdd`: adds/subtracts life via `value` (or `amount`), optional `kill` (default `true`)
- `LifeSet`: sets life directly via `value` (or `amount`)
- `PlaySnd`: plays character sound by `id`/`value`, optional `channel` (`sfx`/`voice`)
- `ChangeAnim`: plays animation by `value`/`anim`/`id`, optional `animation_loop`/`loop`
- `ChangeAnim2`: change opponent animation by `value`/`anim`, optional `animation_loop`/`loop`
- `Projectile`: spawns projectile by `id`/`value` from `projectiles.json` using that entry's gameplay, visual, and trail settings
- `TargetState`: changes opponent state via `value`/`state`, optional `ctrl`
- `TargetLifeAdd`: adds/subtracts opponent life via `value`/`amount`, optional `kill`
- `TargetPowerAdd`: adds/subtracts opponent power via `value`/`amount`
- `TargetVelSet` / `TargetVelAdd`: applies velocity to opponent with `x`/`y`/`z` (or `value` array/dict)
- `TargetPosSet` / `TargetPosAdd`: sets/adds opponent position with `x`/`y`/`z`, optional `facing_relative`
- `Pause`: hitpause via `time` (int or `[attacker, defender]` pair)
- `NotHitBy`: block hit types via `value`/`attr` (e.g. "all", "projectile"), optional `time`, `slot` (0/1)
- `AttackMulSet`: sets attack multiplier via `value` (float)
- `DefenceMulSet`: sets defence multiplier via `value` (float)
- `AssertSpecial`: flags via `flag1`, `flag2`, `flag3` (e.g. invisible, noautoturn, nojugglecheck)
- `Gravity`: optional `value` (float, -1 = use physics default)
- `TargetFacing`: turn opponent to face (`value` > 0 = same as self, < 0 = opposite)
- `ScreenBound`: `value` 0 = allow off-screen, 1 = constrain to arena
- `StopSnd`: stop sound via `channel` (0/1 = sfx, 2 = voice, -1 = all)
- `HitOverride`: go to `stateno` when hit by `attr`, optional `slot` (0-7), `time`, `forceair`
- `HitAdd`: add `value` hits to combo counter
- `HitFallVel`: set velocity to fall.xvel/fall.yvel when in knockdown (no params)
- `MoveHitReset`: reset movehit/movecontact/moveguarded triggers (no params)
- `HitBy`: allow only hit types via `value`/`attr`, optional `time`, `slot` (0/1)
- `PosFreeze`: freeze position when `value` nonzero
- `Trans`: transparency via `trans` (none/add/sub/add1/addalpha), optional `alpha` [src, dest]
- `Offset`: display offset via `x`, `y`
- `PlayerPush`: disable push when `value` 0, enable when nonzero
- `VarRandom`: set var(`v`) to random in `range` [least, greatest]
- `VarRangeSet`: set vars in `first`..`last` to `value` or `fvalue`
- `HitFallSet`: set fall velocities via `value` (-1 no change), `xvel`, `yvel`
- `HitFallDamage`: apply stored fall damage when in knockdown (no params)
- `EnvShake`: screen shake via `time`, optional `freq`, `ampl`, `phase`
- `EnvColor`: screen color via `value` [r,g,b], optional `time` (requires arena support)
- `SndPan`: pan sound via `channel`, `pan` (or `abspan`)
- `SprPriority`: render priority via `value` (-5 to 5)
- `BindToTarget`: bind self to opponent via `time`, optional `pos`/`offset` [x, y]
- `TargetBind`: bind opponent to self via `time`, optional `pos`/`offset` [x, y]
- `SuperPause`: global pause via `time` (ticks); arena freezes both fighters
- `ReversalDef`: reversal/parry attr via `reversal.attr`, optional `p1stateno`, `p2stateno`
- `TargetDrop`: drop active target/grapple, optional `excludeID`, `keepone`
- `Width`: push/edge width via `edge` [front, back], `player` [front, back], or `value` [f, b]
- `VictoryQuote`: set win quote id via `value`/`quote`
- `Explod`: spawn effect via `anim`/`value`, `time`, `pos`/`offset`, optional `id`, `postype`; emits `explod_requested`
- `RemoveExplod`: remove effect by `id`/`ID`
- `ModifyExplod`: modify effect by `id`, optional `time`, `pos`
- `AfterImage`: enable afterimage via `time`, optional `length`
- `AfterImageTime`: set afterimage duration via `time`/`value`
- `PalFX`: palette effect via `time`, optional `add` [r,g,b], `mul` [r,g,b]
- `AngleSet`: set rotation via `value`/`angle` (degrees)
- `AngleAdd`: add rotation via `value`/`angle` (degrees)
- `AttackDist`: guard distance via `value`
- `FallEnvShake`: trigger screen shake when in knockdown, optional `time`, `freq`, `ampl`, `phase`
- `ForceFeedback`: controller rumble via `waveform`, `time`, `amplitude`
- `DisplayToClipboard` / `ClearClipboard` / `AppendToClipboard`: clipboard
- `Helper`: spawn helper via `name`, `id`, `pos`, `stateno`
- `ParentVarSet` / `ParentVarAdd`: helper parent vars (`v`/`var` with `value`, or `fvar` with `fvalue`)
- `BindToRoot` / `BindToParent`: bind to root/parent (helpers)
- `DestroySelf`: queue_free() only when `is_helper` meta is set
- `StateTypeSet`: runtime overrides for `statetype`, `movetype`, `physics` (single-letter MUGEN style)
- `VarSet` / `VarAdd`: writes/adds integer state vars (`v`/`var`/`index`)
- `FVarSet` / `FVarAdd`: writes/adds float state vars (`v`/`fvar`/`index`)

Basic trigger tokens supported now:

- `time`, `ctrl`, `stateno`
- `statetype`, `movetype`, `physics`
- `p2life`, `p2power`, `p2alive`, `p2stateno`, `p2statetype`, `p2movetype`
- `numproj`
- `numtarget`
- `anim`, `animtime`
- `prevstateno`, `command`
- `movehit`, `moveguarded`, `movecontact`
- `life`, `power`, `alive`, `hitpause`
- `vel x/y/z`, `pos x/y/z`, `p2dist x/y`, `facing`, `random`
- `var(n)`, `fvar(n)`
- `combocount`, `hitadd` (current combo hits against opponent)

Trigger expression examples:

- `trigger1: "time = 0"`
- `triggerall: "ctrl = 1"`
- `trigger2: "power >= 100"`
- `trigger3: "command = qcf_p"`
- `trigger4: "var(0) >= 3"`
- `trigger5: "ctrl = 1 && power >= 50"`

Hit data compatibility aliases for pause timing:

- `pausetime` -> hit pause pair `[attacker, defender]`
- `guard_pausetime` (or `guard.pausetime`) -> guard pause pair `[attacker, defender]`
