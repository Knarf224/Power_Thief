# Power Thief — Room Reference

## Room Selection Algorithm

Rooms are selected by `GameState.next_room_scene()`. The first three rooms are always Standard Combat so the player can learn the controls before any special mechanics appear. Room 4 is always a forced special. From room 5 onward, a weighted roll decides each room.

**Rules (room 5+):**
1. Standard Combat starts at a base weight of 45 and gains +25 for every consecutive special room just played, making long special streaks increasingly unlikely.
2. Back-to-back special rooms **are allowed** — the player can see Ambush → Hazard Floor → Power Zone in sequence.
3. The **same** special room can never appear twice in a row — it is excluded from the eligible pool after being played.
4. Landing on Standard Combat resets the consecutive-special streak to 0.

**Fixed sequence every run:**
| Room | Type |
|---|---|
| 1 | Standard Combat (hardcoded start) |
| 2 | Standard Combat (forced) |
| 3 | Standard Combat (forced) |
| 4 | **Random special (always forced)** |
| 5+ | Weighted roll (see weights below) |

**Weights (room 5+ with 0 consecutive specials in streak):**
| Room | Weight | Approx. chance |
|---|---|---|
| Standard Combat | 45 (base) | ~53% |
| Ambush Room | 15 | ~18% |
| Hazard Floor Room | 13 | ~15% |
| Power Zone Room | 12 | ~14% |

Standard weight climbs by 25 per consecutive special: after 1 special in a row it becomes ~68%, after 2 it becomes ~78%.

**Example run sequences (from room 5 onward):**
```
Standard → Ambush → Hazard Floor → Standard → Standard → Power Zone → ...
Standard → Standard → Standard → Ambush → Standard → Power Zone → Standard → ...
```

Player state (health, cores, exit direction) persists across all room transitions via the `GameState` autoload.

---

## Enemy Scaling

Enemy counts are computed by `GameState.get_enemy_count(2)` and scale with `room_counter` (the number of rooms completed before the current one). **Every room type uses the same total count** — special rooms distribute enemies differently but never exceed it.

**Formula:** Flat +2 per room, capped at 24.
```
count = min(2 + room_counter * 2, 24)
```

This replaced the earlier exponential formula (+50%/level) which produced runaway numbers at higher levels. The flat formula gives a predictable, tunable difficulty curve that hits the cap around level 12.

**Progression (all rooms, base 2):**
| Room # | room_counter | Total enemies |
|---|---|---|
| 1 | 0 | 2 |
| 2 | 1 | 4 |
| 3 | 2 | 6 |
| 4 | 3 | 8 |
| 5 | 4 | 10 |
| 6 | 5 | 12 |
| 7 | 6 | 14 |
| 8 | 7 | 16 |
| 9 | 8 | 18 |
| 10 | 9 | 20 |
| 11 | 10 | 22 |
| 12 | 11 | 24 (cap) |
| 13+ | 12+ | 24 (cap) |

**How each room distributes the total:**
| Room | Distribution |
|---|---|
| Standard Combat | All enemies spawned at once |
| Hazard Floor | All enemies spawned at once |
| Ambush Room | Total split across 4 corner rooms (`total / 4` per corner) |
| Power Zone | Total split across waves (`total / wave_count` per wave) |

---

## Boss Companion Count

On boss levels (every 4th room), companions scale with a **flat formula** indexed by boss encounter number, independent of the normal enemy scaling above.

**Formula:**
```
companion_count = 2 + boss_index * 2
```
Where `boss_index` is 0 for the first boss encounter, incrementing by 1 each time a boss is fought.

| Boss encounter | boss_index | Companions |
|---|---|---|
| Level 4  (encounter 1) | 0 | 2 |
| Level 8  (encounter 2) | 1 | 4 |
| Level 12 (encounter 3) | 2 | 6 |
| Level 16 (encounter 4) | 3 | 8 |
| Level 20 (encounter 5) | 4 | 10 |

This replaced the earlier exponential companion curve (L4: 2, L8: 4, L12: 6, L16: 9, L20: 13). The flat formula keeps late boss rooms challenging but not overwhelming when combined with the boss itself.

---

## Implemented Rooms

---

### Standard Combat Room
**Scene:** `scenes/Main.tscn`
**Script:** `scripts/dungeon/main.gd`
**Size:** 1280 × 720

**Layout:**
```
┌────────────────────────────┐
│                            │
│   Open floor, no internal  │
│         obstacles          │
│                            │
└────────────────────────────┘
```

**How it works:**
- Enemies spawn after a **1.2-second delay** along the room's border edges
- Enemies never spawn on the same side the player entered from, preventing instant death on room entry
- Enemy types picked randomly from the full pool of 10 (equally weighted)
- Room clears when all enemies are dead → cores activate → exits open
- Player exits by walking off any edge → next room loads
- Player entry position mirrors the exit edge from the previous room

**Spawn side logic:**
| Player entered from | Eligible spawn sides |
|---|---|
| East (exited west) | North, South, West |
| West (exited east) | North, South, East |
| South (exited north) | North, West, East |
| North (exited south) | South, West, East |
| Center (first room) | All four sides |

**Enemy pool:** All 10 types, equally weighted
**Spawn count:** `GameState.get_enemy_count(2)` — spawned after 1.2s delay (2 → 4 → 6 → 8 → 10 … capped at 24)
**Special behaviours:** None. May have a blackout overlay active (see Blackout Overlay below).

**Floor colours:**
| Zone | Colour | Purpose |
|---|---|---|
| Floor | `Color(0.12, 0.12, 0.18)` | Standard dark blue-grey |
| Walls | `Color(0.28, 0.28, 0.35)` | Slightly lighter grey |

**Intended challenge:** Low early, escalates with room_counter. Open layout gives the player space to dodge and learn enemy patterns.

---

### Ambush Room
**Scene:** `scenes/dungeon/AmbushRoom.tscn`
**Script:** `scripts/dungeon/ambush_room.gd`
**Size:** 1920 × 1080

**Layout:**
```
[NW ROOM] │ N corridor │ [NE ROOM]
──────────┼────────────┼──────────
W corridor │   CENTER   │ E corridor
──────────┼────────────┼──────────
[SW ROOM] │ S corridor │ [SE ROOM]
```
Cross-shaped corridor fills the centre. Four enclosed corner rooms are each separated from the corridor by inner walls with a 120px doorway opening.

**Corner room bounds:**
| Room | Bounds | Size |
|---|---|---|
| NW | (0, 0) → (760, 360) | 760 × 360 |
| NE | (1160, 0) → (1920, 360) | 760 × 360 |
| SW | (0, 720) → (760, 1080) | 760 × 360 |
| SE | (1160, 720) → (1920, 1080) | 760 × 360 |

**Trigger zones:**
- Each corner room has an Area2D covering its full bounds
- A 160×160 centre trigger sits at (880, 460)

**Trigger rules:**
| Player action | Rooms spawned |
|---|---|
| Enter a corner room | That room + 1 random other untriggered room |
| Cross centre zone | ALL remaining untriggered rooms |

- Triggers arm 0.3s after scene load to prevent instant spawning on entry
- Already-triggered rooms are never double-spawned

**Enemy pool:** Ghost / Assassin / BombBeetle weighted 3×, all others 1×
**Spawn count:** `GameState.get_enemy_count(2)` total, split evenly across 4 corners (`total / 4` per triggered corner). Total matches every other room at the same level.

**Special behaviours:**
- **Ghost wall-phasing:** Ghost enemies use direct `global_position` translation instead of `move_and_slide()`, allowing them to pass through all walls and inner dividers.
- **Corner teleport:** Each inner corner has a 140×140 teleport zone. Enemies stuck in one for 1+ second are teleported to the room centre (960, 540). Controlled via `teleport_when_stuck`, `teleport_target`, `teleport_zones` flags on each spawned enemy.
- **_enforce_bounds() safety net:** `base_enemy._enforce_bounds()` is called each physics frame and snaps any enemy whose `global_position` has escaped the viewport bounds back to the room center at (960, 540). Ghost explicitly calls `_enforce_bounds()` in its own `_physics_process` since it bypasses `move_and_slide()`. This fixed a bug where Ghost and other enemies occasionally drifted fully off-screen and became unreachable, soft-locking the room.

**Teleport zone positions:**
| Room | Zone rect | Corner |
|---|---|---|
| NW | Rect2(620, 220, 140, 140) | SE inner |
| NE | Rect2(1160, 220, 140, 140) | SW inner |
| SW | Rect2(620, 720, 140, 140) | NE inner |
| SE | Rect2(1160, 720, 140, 140) | NW inner |

**Floor colours:**
| Zone | Colour | Purpose |
|---|---|---|
| Corridor / centre | `Color(0.10, 0.10, 0.16)` | Standard walkable area |
| Teleport corners | `Color(0.18, 0.08, 0.12)` | Dark red-purple warning tint |

**Player entry positions:**
| Exited from | Enters at |
|---|---|
| West | (1780, 540) — east arm |
| East | (140, 540) — west arm |
| North | (960, 980) — south arm |
| South | (960, 100) — north arm |
| Default | (960, 900) — south arm |

**Intended challenge:** High. Room starts silent. Entering any corner immediately alerts another. Crossing the centre triggers everything. Encourages careful routing, core management, and corridor kiting.

---

### Hazard Floor Room
**Scene:** `scenes/dungeon/HazardFloorRoom.tscn`
**Script:** `scripts/dungeon/hazard_floor_room.gd`
**Size:** 1536 × 864

**Layout:**
```
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
│         16 columns × 9 rows = 144 tiles           │
│              each tile 96 × 96 px                  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
```

**How it works:**
- Floor is divided into a 16×9 grid of 96×96px tiles, drawn via `_draw()` on the root Node2D
- A central script manages all 144 tiles — no per-tile nodes
- Every 0.4 seconds, N random SAFE tiles are pushed into WARNING state
- Tiles cycle: SAFE → WARNING → DANGER → COOLDOWN → SAFE
- Player takes 2 HP per 0.25s (= 8 DPS) while standing on a DANGER tile
- Hazard stops completely when room is cleared (all tiles snap to SAFE)

**Tile state machine:**
| State | Visual | Duration |
|---|---|---|
| SAFE | Dark blue-grey (base floor) | Until randomly selected |
| WARNING | Gradually lerps to crimson | `_warning_duration` (1.2s base, min 0.6s) |
| DANGER | Pulses crimson ↔ orange | 1.5s |
| COOLDOWN | Fades back to safe | 0.3s |

**Tile colours:**
| State | Colour |
|---|---|
| Grout (gap) | `Color(0.05, 0.05, 0.08)` |
| SAFE | `Color(0.10, 0.10, 0.16)` |
| WARNING | `Color(0.55, 0.08, 0.08)` — deep crimson |
| DANGER | `Color(0.90, 0.40, 0.05)` — bright orange |

**Timing constants:**
| Stat | Value |
|---|---|
| Danger duration | 2.5s per tile |
| Cooldown duration | 0.3s |
| Damage | 2 HP per 0.25s tick (8 DPS) |

**Difficulty scaling** (based on `GameState.room_counter`):
| Stat | Formula | Early | Late |
|---|---|---|---|
| Tiles per wave | `min(6 + rooms / 5, 12)` | 6 | 12 |
| Warning duration | `max(0.6, 1.2 - rooms * 0.02)` | 1.2s | 0.6s |

**Enemy pool:** All 10 types, equally weighted
**Spawn count:** `GameState.get_enemy_count(2)` — all spawned at once. Same total as Standard Combat at the same level.
**Special behaviours:** Enemies are not affected by the floor hazard — only the player takes damage.

**Player entry positions:** 120px from the entry edge, centred on the opposite axis.

**Intended challenge:** Medium-High. Constant positional pressure layered on top of combat. Rewards players with movement cores (Dash, Phase). Punishes players who stand still to aim.

---

### Power Zone Room
**Scene:** `scenes/dungeon/PowerZoneRoom.tscn`
**Script:** `scripts/dungeon/power_zone_room.gd`
**Size:** 1280 × 1280

**Layout:**
```
        North
       /      \
      /   ↑    \
West ←  centre  → East
      \   ↓    /
       \      /
        South
```
The room is divided into 4 triangular zones by the two corner-to-corner diagonals (TL→BR and TR→BL). Zones meet at a decorative circle at the room centre. There are no physical walls between zones — players and enemies move freely across all four.

**Zone geometry:**
| Zone | Triangle vertices |
|---|---|
| North | (0,0), (1280,0), (640,640) |
| East | (1280,0), (1280,1280), (640,640) |
| South | (1280,1280), (0,1280), (640,640) |
| West | (0,1280), (0,0), (640,640) |

**Zone detection:** Two diagonal equations determine which triangle the player is in:
- `above_tlbr = py < px`
- `above_trbl = py < (ROOM_H - px)`

| above_tlbr | above_trbl | Zone |
|---|---|---|
| true | true | North |
| false | true | West |
| true | false | East |
| false | false | South |

**How it works:**
- One zone is "active" (lit) at all times — the player can **only fire their basic attack** while standing in the active zone
- The active zone switches on a timer; before switching it flashes rapidly as a warning
- Enemies spawn in waves regardless of whether previous wave enemies are dead — pressure accumulates
- Room clears when all waves are exhausted AND all enemies are dead
- `player.can_attack` is set to `false` each frame the player is outside the active zone, and restored on room clear/exit/death

**Zone timing:**
| Stat | Formula | Early | Late |
|---|---|---|---|
| Zone duration | `max(2.5, 5.0 - rooms * 0.08)` | 5.0s | 2.5s |
| Warning flash | Fixed 0.6s | — | — |

**Zone colours:**
| State | Colour | Notes |
|---|---|---|
| Inactive | `Color(0.10, 0.10, 0.16)` | Same dark floor as other rooms |
| Active | `Color(0.24, 0.22, 0.35)` | Lighter purple-blue — "lit from below" |
| Warning | `Color(0.52, 0.48, 0.72)` — pulses | Bright flash before zone switches |
| Dividers | `Color(0.04, 0.04, 0.06)` | Thin 5px diagonal lines |
| Centre node | `Color(0.20, 0.20, 0.28)` | Decorative circle, radius 18px |

**Wave system:**
| Stat | Value |
|---|---|
| Waves per room | `3 + room_counter / 6` |
| Wave interval | 8 seconds |
| Enemies per wave | `get_enemy_count(2) / wave_count` — same total as all other rooms, split across waves |
| First wave delay | 0.5s arm delay after room load |

**Enemy pool:** All 10 types, equally weighted. Enemies spawn at fixed positions within a random zone, with ±40px random scatter.

**Spawn positions per zone:**
| Zone | Spawn candidates |
|---|---|
| North | (640,160), (360,300), (920,300) |
| East | (1120,640), (960,360), (960,920) |
| South | (640,1120), (360,980), (920,980) |
| West | (160,640), (320,360), (320,920) |

**Special behaviours:**
- Active core abilities (Fire Bomb, Phase, Summon) are **not** blocked outside the active zone — only the basic left-click projectile is gated
- Active zone picks a new zone at random, never the same zone twice in a row
- When room is cleared the active zone is set to -1 (no zone lit), restoring normal floor appearance

**Intended challenge:** High. Combines positional pressure (must be in the lit zone to attack) with accumulating enemy count (waves don't wait). Rewards players with movement cores. Punishes passive or stationary play styles.

---

## Blackout Overlay (Room Condition)
**Script:** `scripts/dungeon/blackout_overlay.gd`
**Type:** Reusable Node2D — not a standalone room

The blackout effect is a **condition** that applies randomly to any room after the first 3 levels. Each room instantiates a `BlackoutOverlay` node in `_ready()` and calls `deactivate()` when combat ends.

**Activation rules:**
- Never activates in rooms 1–3 (room_counter < 3)
- From room 4 onward, activation chance scales with depth:

| Room | Activation chance |
|---|---|
| 4 | 50% |
| 6 | 60% |
| 8 | 70% |
| 10 | 80% |
| 12 | 90% |
| 14+ | 100% — guaranteed |

Formula: `clamp(0.50 + (room_counter - 3) * 0.05, base_chance, 1.00)`

**How it works:**
- On activation, creates a `Polygon2D` with `invert_enabled = true` at `z_index = 100`
- The polygon is a 56-point circle recomputed every frame at the player's position
- Everything outside the circle is filled with near-black (`Color(0.00, 0.00, 0.02, 0.97)`)
- Alternates between LIT and DARK phases with a smooth alpha fade
- After each completed dark cycle, the light radius shrinks by 15px (min 80px)
- HUD is unaffected — Control nodes render above all 2D z_index layers

**Timing (scales with `room_counter`):**
| Phase | Formula | Early | Late |
|---|---|---|---|
| LIT duration | `max(3.0, 6.0 - rooms * 0.08)` | 6.0s | 3.0s |
| DARK duration | `min(7.0, 3.5 + rooms * 0.07)` | 3.5s | 7.0s |

**Light radius:**
| Stat | Value |
|---|---|
| Start | `max(80, 180 - room_counter * 4)` px |
| Shrink per cycle | 15px |
| Minimum | 80px |

**Adding blackout to a new room:**
```gdscript
# In _ready(), after player is positioned:
_blackout = load("res://scripts/dungeon/blackout_overlay.gd").new()
_blackout.activation_chance = 0.50  # sets the floor — depth scaling overrides this upward
add_child(_blackout)

# When combat ends (transitioning to CORES_ACTIVE):
_blackout.deactivate()
```

---

## Planned Rooms

---

### Gauntlet Room *(not yet implemented)*
**Concept:** A long narrow corridor. Enemies spawn in waves from one end only, forcing the player to kite backward and hold a chokepoint.
**Intended size:** ~1920 × 480
**Key mechanic:** 3 waves, each spawning from the right edge. Wave 2 spawns only after wave 1 is cleared. Narrow space punishes AoE-less builds.
**Challenge level:** Medium-High
**Notes:** Good pacing room. Natural escalation — wave 1 is manageable, wave 3 is brutal. Dash and Phase cores shine here.

---

### Siege Room *(not yet implemented)*
**Concept:** Enemies spawn from all 4 edges simultaneously in 2 waves. Maximum chaos from the opening second.
**Intended size:** ~1536 × 864
**Key mechanic:** No trigger zones — all enemies spawn the moment the player enters. Rewards AoE builds (Fire, Lightning, Explosion cores). No safe corner to hide in.
**Challenge level:** High
**Notes:** Pairs well after a Standard room to catch players off-guard. Short but intense.
