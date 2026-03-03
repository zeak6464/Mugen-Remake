## Character Creation Guide

This is the fastest way to create a playable character for this project.

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

---

### 3) `physics.json` (movement)

Example:

```json
{
  "walk_speed": 3.2,
  "run_speed": 6.0,
  "jump_speed": 7.5,
  "gravity": 18.0
}
```

Supported keys currently used by runtime include:

- `walk_speed`
- `run_speed`
- `jump_speed`
- `gravity`
- `max_fall_speed`
- `smash_air_speed`
- `smash_air_accel`
- `smash_air_brake`

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
          "pushback": [1.0, 0.0, 0.0]
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

### 7) Grapples / throws

Use `throwboxes` in a state (not regular strike hitboxes):

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

Optional anti-spam tuning:

- `grapple_whiff_cooldown_frames` in throw data.

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
- `Projectile`: spawns projectile by `id`/`value` from `projectiles.json`
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
