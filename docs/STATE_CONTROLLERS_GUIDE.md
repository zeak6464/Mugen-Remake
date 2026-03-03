# State Controllers Guide

This guide is the detailed reference for the `controllers` array used in `states.json`.

It is based on current runtime behavior in `engine/StateController.gd`.

## 1) Where controllers run

Controllers run inside each state entry in `states.json`:

```json
{
  "p_light": {
    "animation": "attack_light",
    "controllers": [
      {
        "type": "PlaySnd",
        "id": "swing_light",
        "trigger1": "time = 1",
        "persistent": 0
      }
    ],
    "next": { "frame": 20, "id": "idle" }
  }
}
```

## 2) Controller execution rules

- Controllers are evaluated in list order each tick.
- If one controller changes state, execution stops for the old state list immediately.
- By default, controllers do not run during hitpause.
- A controller runs in hitpause only if `ignorehitpause = true`.
- `persistent` controls execution rate:
  - `0`: once per state entry
  - `1`: every tick (default)
  - `N > 1`: every N physics ticks

## 3) Trigger semantics

- `triggerall`: shared AND gate for all numbered triggers.
- `trigger1`, `trigger2`, ...: OR group.
- No triggers present means "always true".
- Each trigger entry can be:
  - bool/int/float
  - string expression
  - dictionary expression
  - array of atoms (AND list)

Practical pattern:

```json
{
  "type": "ChangeState",
  "value": "idle",
  "triggerall": "time >= 18",
  "trigger1": "movecontact = 0",
  "trigger2": "moveguarded = 1"
}
```

This means:
- `time >= 18` must be true, and
- either `movecontact = 0` OR `moveguarded = 1`.

## 4) Generic controller fields

- `type`: controller name (case-insensitive in runtime dispatch)
- `persistent`: cadence (see above)
- `ignorehitpause`: allow execution during hitpause
- `triggerall`, `trigger1..n`: conditions

Many controllers also accept aliases for key fields (for example `value` and `amount`).

## 5) Supported controller types

Current types implemented by runtime:

- `ChangeState`, `SelfState`, `CtrlSet`, `Null`, `Turn`
- `VelSet`, `VelAdd`, `VelMul`, `PosSet`, `PosAdd`
- `PowerAdd`, `PowerSet`, `LifeAdd`, `LifeSet`
- `PlaySnd`, `StopSnd`, `SndPan`
- `ChangeAnim`, `ChangeAnim2`, `SprPriority`, `Trans`, `Offset`, `PalFX`, `AfterImage`, `AfterImageTime`, `AngleSet`, `AngleAdd`
- `Projectile`
- `TargetState`, `TargetLifeAdd`, `TargetPowerAdd`, `TargetVelSet`, `TargetVelAdd`, `TargetPosSet`, `TargetPosAdd`, `TargetFacing`, `BindToTarget`, `TargetBind`, `TargetDrop`
- `Pause`, `SuperPause`, `EnvShake`, `EnvColor`, `FallEnvShake`, `ForceFeedback`, `ScreenBound`
- `NotHitBy`, `HitBy`, `HitOverride`, `MoveHitReset`, `HitAdd`, `HitFallVel`, `HitFallSet`, `HitFallDamage`, `ReversalDef`, `AttackDist`, `AttackMulSet`, `DefenceMulSet`, `PlayerPush`, `Width`, `Gravity`
- `AssertSpecial`, `PosFreeze`, `StateTypeSet`
- `VarSet`, `VarAdd`, `FVarSet`, `FVarAdd`, `VarRandom`, `VarRangeSet`, `ParentVarSet`, `ParentVarAdd`
- `Explod`, `RemoveExplod`, `ModifyExplod`, `Helper`, `DestroySelf`, `BindToRoot`, `BindToParent`
- `VictoryQuote`
- `DisplayToClipboard`, `ClearClipboard`, `AppendToClipboard`

---

## 6) Detailed groups and examples

### A) State/Control flow

#### `ChangeState` / `SelfState`
- Core params: `value` (or `state`, `state_id`)
- Optional: `ctrl`, `anim`, `animation_loop`

```json
{
  "type": "ChangeState",
  "value": "idle",
  "ctrl": 1,
  "trigger1": "time >= 24"
}
```

#### `CtrlSet`
- Core params: `value` (or `ctrl`) as bool/int

```json
{ "type": "CtrlSet", "value": 0, "trigger1": "time = 1", "persistent": 0 }
```

#### `StateTypeSet`
- Runtime-supported as a controller type.
- Use to set state type/move type style fields for custom logic.

#### `Null`
- Explicit no-op. Useful while drafting complex state files.

### B) Movement and position

#### `VelSet` / `VelAdd` / `VelMul`
- Params: `x`, `y`, `z` or `value` array/dictionary

```json
{ "type": "VelAdd", "x": 0.5, "y": 0.0, "trigger1": "time < 6" }
```

#### `PosSet` / `PosAdd`
- Params: `x`, `y`, `z`
- `PosAdd` supports `facing_relative` (default true)

#### `Turn`
- Flips facing direction.

#### `Gravity`
- Optional `value` override (float)

#### `PosFreeze`
- Toggle positional freeze using `value`.

### C) Life/Power and combat modifiers

#### `PowerAdd`, `PowerSet`
- `value` or `amount`

#### `LifeAdd`, `LifeSet`
- `value` or `amount`
- `LifeAdd` optional `kill` (default true)

#### `AttackMulSet`, `DefenceMulSet`
- `value` float multiplier

#### `AttackDist`
- `value` for guard distance behavior

### D) Hit interaction and defense

#### `NotHitBy`, `HitBy`
- `value` or `attr`
- Optional `time`, `slot`

#### `HitOverride`
- `attr`, `stateno`
- Optional `slot`, `time`, `forceair`

#### `MoveHitReset`
- No params; resets move contact flags.

#### `HitAdd`, `HitFallVel`, `HitFallSet`, `HitFallDamage`
- Combo/fall handling controllers.

#### `ReversalDef`
- `reversal.attr`
- Optional `p1stateno`, `p2stateno`

### E) Target/opponent operations

#### `TargetState`
- `value`/`state`/`state_id`
- Optional `ctrl`

#### `TargetLifeAdd`, `TargetPowerAdd`
- `value`/`amount`

#### `TargetVelSet`, `TargetVelAdd`
- `x`, `y`, `z` or `value` vector forms

#### `TargetPosSet`, `TargetPosAdd`
- `x`, `y`, `z`
- Optional `facing_relative`

#### `TargetFacing`
- `value > 0`: align to self orientation
- `value < 0`: opposite orientation

#### `BindToTarget`, `TargetBind`, `TargetDrop`
- Grab/bind flow support (`time`, `pos`/`offset`, etc.)

### F) Animation/visual/sound

#### `ChangeAnim`
- `value`/`anim`/`id`
- Optional `animation_loop` or `loop`

#### `ChangeAnim2`
- Opponent animation variant

#### `PlaySnd`, `StopSnd`, `SndPan`
- `PlaySnd`: `id`/`value`, optional `channel`
- `StopSnd`: `channel` or all
- `SndPan`: `pan`/`abspan`

#### `Trans`, `PalFX`, `AfterImage`, `AfterImageTime`
- Transparency/palette/afterimage visuals.

#### `Explod`, `RemoveExplod`, `ModifyExplod`
- Effect lifecycle controllers.

#### `AngleSet`, `AngleAdd`, `SprPriority`, `Offset`
- Rotation and display adjustments.

### G) Pause, camera, arena

#### `Pause`, `SuperPause`
- Tick-based pause control.

#### `ScreenBound`
- `value` 0/1 off-screen behavior.

#### `EnvShake`, `EnvColor`, `FallEnvShake`
- Arena-level effects (when arena supports them).

#### `Width`, `PlayerPush`
- Push/collision footprint behavior.

### H) Helpers and parent/root binding

#### `Helper`
- Spawn helper (`name`, `id`, `pos`, `stateno`, etc.)

#### `DestroySelf`
- Works when helper metadata marks the actor as helper.

#### `ParentVarSet`, `ParentVarAdd`
- Write to parent vars from helper context.

#### `BindToRoot`, `BindToParent`
- Keep helper attached to root/parent.

### I) Variables and debug

#### `VarSet`, `VarAdd`, `FVarSet`, `FVarAdd`
- Integer and float var writes.

#### `VarRandom`, `VarRangeSet`
- Randomized and bulk var writes.

#### `DisplayToClipboard`, `ClearClipboard`, `AppendToClipboard`
- Debug text/clipboard output.

#### `VictoryQuote`
- Sets win quote id/selection.

## 7) Best practices

- Keep high-impact controllers (`ChangeState`, `CtrlSet`, `TargetState`) near top of list.
- Use `persistent = 0` for one-shot events (sfx spawn, state init setup).
- Use explicit `triggerall` guards for readability.
- Separate "init", "active", and "recovery" controller blocks by frame triggers.
- Prefer small, clear controller entries over giant all-in-one entries.

## 8) Common pitfalls

- Typos in `type` silently do nothing (no default fallback behavior).
- `triggerall` false blocks all numbered triggers.
- Missing numbered triggers with only `triggerall` can make logic appear always-on.
- Controllers may match, but state transition can still fail due to fighter/state rules.
- During hitpause, expect controllers to stop unless `ignorehitpause` is enabled.

## 9) Recommended authoring pattern

For each attack state:

1. Frame 1 init (`CtrlSet`, setup vars, one-shot sfx).
2. Active window (`Hitboxes`/`Throwboxes` timeline + optional movement controllers).
3. On-hit branch (`trigger` conditions using hit flags).
4. Recovery and return (`ChangeState` back to neutral).

This keeps behavior deterministic and easier to debug.

## 10) JSON example for every controller

Use this as a reference library. These are example entries for a `controllers` array:

```json
{
  "controllers": [
    { "type": "ChangeState", "value": "idle", "trigger1": "time >= 20" },
    { "type": "SelfState", "value": "idle", "trigger1": "time >= 20" },
    { "type": "CtrlSet", "value": 1, "trigger1": "time = 1", "persistent": 0 },
    { "type": "Null", "trigger1": 1 },
    { "type": "Turn", "trigger1": "p2bodydist x < 0" },

    { "type": "VelSet", "x": 2.0, "y": 0.0, "z": 0.0, "trigger1": "time = 1" },
    { "type": "VelAdd", "x": 0.2, "y": 0.0, "z": 0.0, "trigger1": "time < 6" },
    { "type": "VelMul", "x": 0.9, "y": 1.0, "z": 1.0, "trigger1": "time >= 6" },
    { "type": "PosSet", "x": 0.0, "y": 0.0, "z": 0.0, "trigger1": "time = 1" },
    { "type": "PosAdd", "x": 1.0, "y": 0.0, "z": 0.0, "facing_relative": true, "trigger1": "time = 2" },

    { "type": "PowerAdd", "value": 250, "trigger1": "movehit = 1" },
    { "type": "PowerSet", "value": 1000, "trigger1": "roundstate = 2" },
    { "type": "LifeAdd", "value": -100, "kill": true, "trigger1": "movehit = 1" },
    { "type": "LifeSet", "value": 500, "trigger1": "time = 1", "persistent": 0 },

    { "type": "PlaySnd", "id": "swing_light", "channel": "sfx", "trigger1": "time = 1", "persistent": 0 },
    { "type": "StopSnd", "channel": -1, "trigger1": "time = 30", "persistent": 0 },
    { "type": "SndPan", "channel": 0, "pan": -80, "trigger1": "time = 1" },

    { "type": "ChangeAnim", "value": "attack_light", "loop": false, "trigger1": "time = 1", "persistent": 0 },
    { "type": "ChangeAnim2", "value": "hitstun", "loop": false, "trigger1": "movehit = 1" },
    { "type": "SprPriority", "value": 2, "trigger1": "time = 1", "persistent": 0 },
    { "type": "Trans", "trans": "addalpha", "alpha": [128, 256], "trigger1": "time >= 1" },
    { "type": "Offset", "x": 4, "y": -2, "trigger1": "time >= 1" },
    { "type": "PalFX", "time": 8, "add": [32, 0, 0], "mul": [256, 256, 256], "trigger1": "movehit = 1" },
    { "type": "AfterImage", "time": 10, "length": 4, "trigger1": "time = 1", "persistent": 0 },
    { "type": "AfterImageTime", "time": 5, "trigger1": "time = 1", "persistent": 0 },
    { "type": "AngleSet", "value": 0.0, "trigger1": "time = 1" },
    { "type": "AngleAdd", "value": 5.0, "trigger1": "time < 12" },

    { "type": "Projectile", "id": "fireball_a", "trigger1": "time = 4", "persistent": 0 },

    { "type": "TargetState", "value": "grabbed", "ctrl": 0, "trigger1": "numtarget > 0" },
    { "type": "TargetLifeAdd", "value": -80, "kill": true, "trigger1": "numtarget > 0" },
    { "type": "TargetPowerAdd", "value": -250, "trigger1": "numtarget > 0" },
    { "type": "TargetVelSet", "x": 2.0, "y": 4.5, "z": 0.0, "trigger1": "numtarget > 0" },
    { "type": "TargetVelAdd", "x": 0.0, "y": -1.0, "z": 0.0, "trigger1": "numtarget > 0" },
    { "type": "TargetPosSet", "x": 0.0, "y": 0.0, "z": 0.0, "trigger1": "numtarget > 0" },
    { "type": "TargetPosAdd", "x": 0.5, "y": 0.0, "z": 0.0, "facing_relative": true, "trigger1": "numtarget > 0" },
    { "type": "TargetFacing", "value": -1, "trigger1": "numtarget > 0" },
    { "type": "BindToTarget", "time": 12, "offset": [18, -2], "trigger1": "numtarget > 0" },
    { "type": "TargetBind", "time": 12, "offset": [20, 0], "trigger1": "numtarget > 0" },
    { "type": "TargetDrop", "trigger1": "time >= 20", "persistent": 0 },

    { "type": "Pause", "time": 6, "trigger1": "movehit = 1", "persistent": 0 },
    { "type": "SuperPause", "time": 20, "trigger1": "time = 1", "persistent": 0 },
    { "type": "EnvShake", "time": 10, "freq": 60, "ampl": 4, "phase": 90, "trigger1": "movehit = 1" },
    { "type": "EnvColor", "value": [255, 220, 220], "time": 3, "trigger1": "movehit = 1" },
    { "type": "FallEnvShake", "time": 12, "freq": 60, "ampl": 6, "phase": 90, "trigger1": "fall = 1" },
    { "type": "ForceFeedback", "waveform": "sine", "time": 10, "amplitude": 0.6, "trigger1": "movehit = 1" },
    { "type": "ScreenBound", "value": 1, "trigger1": 1 },

    { "type": "NotHitBy", "value": "projectile", "time": 8, "slot": 0, "trigger1": "time = 1", "persistent": 0 },
    { "type": "HitBy", "value": "SCA,NA,SA,HA", "time": 8, "slot": 0, "trigger1": "time = 1", "persistent": 0 },
    { "type": "HitOverride", "attr": "SCA,NA,SA,HA", "stateno": "guard", "slot": 0, "time": 10, "forceair": false, "trigger1": "time = 1", "persistent": 0 },
    { "type": "MoveHitReset", "trigger1": "time = 1", "persistent": 0 },
    { "type": "HitAdd", "value": 1, "trigger1": "movehit = 1" },
    { "type": "HitFallVel", "trigger1": "fall = 1" },
    { "type": "HitFallSet", "value": -1, "xvel": 2.5, "yvel": -6.0, "trigger1": "fall = 1" },
    { "type": "HitFallDamage", "trigger1": "fall = 1" },
    { "type": "ReversalDef", "reversal.attr": "SCA,AA,AP", "p1stateno": "parry", "p2stateno": "reversed", "trigger1": "time <= 4" },
    { "type": "AttackDist", "value": 120, "trigger1": 1 },
    { "type": "AttackMulSet", "value": 1.2, "trigger1": "time = 1", "persistent": 0 },
    { "type": "DefenceMulSet", "value": 0.9, "trigger1": "time = 1", "persistent": 0 },
    { "type": "PlayerPush", "value": 1, "trigger1": 1 },
    { "type": "Width", "value": [18, 18], "trigger1": 1 },
    { "type": "Gravity", "value": -1, "trigger1": 1 },

    { "type": "AssertSpecial", "flag1": "noautoturn", "flag2": "nojugglecheck", "trigger1": 1 },
    { "type": "PosFreeze", "value": 1, "trigger1": "time <= 3" },
    { "type": "StateTypeSet", "statetype": "S", "movetype": "I", "physics": "N", "trigger1": "time = 1", "persistent": 0 },

    { "type": "VarSet", "v": 0, "value": 1, "trigger1": "time = 1", "persistent": 0 },
    { "type": "VarAdd", "v": 0, "value": 1, "trigger1": "time % 5 = 0" },
    { "type": "FVarSet", "fvar": 0, "fvalue": 1.5, "trigger1": "time = 1", "persistent": 0 },
    { "type": "FVarAdd", "fvar": 0, "fvalue": 0.25, "trigger1": "time < 20" },
    { "type": "VarRandom", "v": 2, "range": [0, 100], "trigger1": "time = 1", "persistent": 0 },
    { "type": "VarRangeSet", "first": 10, "last": 14, "value": 0, "trigger1": "time = 1", "persistent": 0 },
    { "type": "ParentVarSet", "v": 3, "value": 1, "trigger1": 1 },
    { "type": "ParentVarAdd", "v": 3, "value": 1, "trigger1": "time % 10 = 0" },

    { "type": "Explod", "id": 9000, "anim": "hit_spark", "time": 8, "offset": [10, -8], "postype": "p1", "trigger1": "movehit = 1", "persistent": 0 },
    { "type": "RemoveExplod", "id": 9000, "trigger1": "time >= 12", "persistent": 0 },
    { "type": "ModifyExplod", "id": 9000, "time": 4, "pos": [12, -10], "trigger1": "time = 6", "persistent": 0 },
    { "type": "Helper", "name": "AssistA", "id": 1200, "pos": [30, 0], "stateno": "assist_idle", "trigger1": "time = 1", "persistent": 0 },
    { "type": "DestroySelf", "trigger1": "time >= 120", "persistent": 0 },
    { "type": "BindToRoot", "time": 15, "offset": [0, 0], "trigger1": 1 },
    { "type": "BindToParent", "time": 15, "offset": [0, 0], "trigger1": 1 },

    { "type": "VictoryQuote", "value": 2, "trigger1": "win = 1", "persistent": 0 },

    { "type": "DisplayToClipboard", "text": "state=%s time=%d", "params": ["stateno", "time"], "trigger1": 1 },
    { "type": "ClearClipboard", "trigger1": "time = 1", "persistent": 0 },
    { "type": "AppendToClipboard", "text": " hit=%d", "params": ["movehit"], "trigger1": "movehit = 1" }
  ]
}
```
