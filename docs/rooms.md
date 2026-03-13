# Power Thief — Room Reference

## Room Rotation

Rooms are managed by `GameState.next_room_scene()` using a fixed rotation:

| Room # | Scene |
|---|---|
| 1 | Standard Combat Room (starting scene) |
| 2 | **Ambush Room (always)** |
| 3 | Standard Combat Room |
| 4 | Standard Combat Room |
| 5 | Ambush Room |
| 6+ | Repeats from 3 |

Player state (health, cores, exit direction) persists across all room transitions via the `GameState` autoload.

---

## Current Rooms

---

### Standard Combat Room
**Scene:** `scenes/Main.tscn`
**Script:** `scripts/dungeon/main.gd`
**Size:** 960 x 540

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
- 2 enemies spawn at fixed positions on room load
- Enemy types picked randomly from the full pool of 10 types (equally weighted)
- Room clears when all enemies are dead → cores activate → exits open
- Player exits by walking off any edge → next room loads
- Player entry position is based on which edge they exited from (opposite wall of next room)

**Enemy pool:** All 10 types equally weighted
- FireMage, Assassin, Slime, Ghost, BombBeetle, IceWitch, LightningSprite, StoneGolem, Necromancer, PoisonToad

**Spawn count:** 2 enemies

**Special behaviours:** None

**Intended challenge:** Low. Introduction room. Open layout gives the player room to dodge and learn enemy patterns.

---

### Ambush Room
**Scene:** `scenes/dungeon/AmbushRoom.tscn`
**Script:** `scripts/dungeon/ambush_room.gd`
**Size:** 1920 x 1080 (2x the Standard room)

**Layout:**
```
[NW ROOM] │ N corridor │ [NE ROOM]
──────────┼────────────┼──────────
W corridor │   CENTER   │ E corridor
──────────┼────────────┼──────────
[SW ROOM] │ S corridor │ [SE ROOM]
```

A cross-shaped corridor fills the center of the room. The 4 corners are enclosed rooms, each separated from the corridor by inner walls. Each inner wall has a 120px doorway opening.

**Corner rooms:**
| Room | Bounds | Size |
|---|---|---|
| NW | (0, 0) to (760, 360) | 760 x 360 |
| NE | (1160, 0) to (1920, 360) | 760 x 360 |
| SW | (0, 720) to (760, 1080) | 760 x 360 |
| SE | (1160, 720) to (1920, 1080) | 760 x 360 |

**Floor colours:**
| Zone | Colour | Purpose |
|---|---|---|
| Corridor / center | Dark blue-black `Color(0.10, 0.10, 0.16)` | Standard walkable area |
| Teleport corner zones | Dark red-purple `Color(0.18, 0.08, 0.12)` | Visually marks corners where enemies teleport |

**Trigger zones:**
- Each corner room has an Area2D covering its full bounds
- A small 160x160 center trigger zone sits at the exact center intersection (880, 460)

**Trigger rules:**
| Player action | Spawns enemies in |
|---|---|
| Enter NW room | NW + 1 random other untriggered room |
| Enter NE room | NE + 1 random other untriggered room |
| Enter SW room | SW + 1 random other untriggered room |
| Enter SE room | SE + 1 random other untriggered room |
| Cross center zone | ALL remaining untriggered rooms |

- Triggers arm 0.3s after scene load to prevent instant spawning
- Already-triggered rooms are never double-spawned
- Enemies chase immediately regardless of which room they spawned in
- Rooms do NOT lock — player can move freely at all times

**Enemy pool:** Ghost / Assassin / BombBeetle appear 3x more than others
| Enemy | Weight |
|---|---|
| Ghost | 3x |
| Assassin | 3x |
| BombBeetle | 3x |
| FireMage | 1x |
| Slime | 1x |
| IceWitch | 1x |
| LightningSprite | 1x |
| Necromancer | 1x |

**Spawn counts:** 3 enemies per triggered room
| Scenario | Max enemies spawned |
|---|---|
| Enter one corner | 6 (that room + 1 random) |
| Cross center | Up to 12 (all 4 rooms) |

**Special behaviours:**
- **Corner teleport:** Each corner room has a 140x140 teleport zone at its inner corner (the corner closest to the corridor). Enemies stuck in one of these zones for 1+ second are teleported to the room center (960, 540). This is exclusive to the Ambush Room — enemies in standard rooms are not affected. Controlled via `teleport_when_stuck`, `teleport_target`, and `teleport_zones` flags set on each spawned enemy.
- **Teleport zone positions:**
  | Room | Zone rect | Corner |
  |---|---|---|
  | NW | Rect2(620, 220, 140, 140) | SE (inner) |
  | NE | Rect2(1160, 220, 140, 140) | SW (inner) |
  | SW | Rect2(620, 720, 140, 140) | NE (inner) |
  | SE | Rect2(1160, 720, 140, 140) | NW (inner) |

**Player entry positions** (based on exit direction from previous room):
| Exited previous room | Enters Ambush Room at |
|---|---|
| West | (1780, 540) — east corridor arm |
| East | (140, 540) — west corridor arm |
| North | (960, 980) — south corridor arm |
| South | (960, 100) — north corridor arm |
| Default (first time) | (960, 900) — south corridor arm |

**Intended challenge:** High. The room starts silent — no enemies until the player steps into a corner or the center. Entering any corner immediately alerts one other room across the map. Crossing the center is the most dangerous moment. Encourages careful movement, core management mid-fight, and using the corridor to kite.

---

## Suggested Future Rooms

---

### Gauntlet Room *(not yet implemented)*
**Concept:** Enemies spawn in waves — clear one wave to unlock the next. A longer room forces sustained engagements with no safe zones.
**Intended size:** ~1152 x 648 (+20% over Standard)
**Key mechanic:** Wave counter on HUD. Player can swap cores between waves. Exits locked until all waves cleared.
**Challenge level:** Medium-High
**Notes:** Good pacing room between Standard and Ambush. Natural escalation — wave 1 is easy, wave 3 is brutal.

---

### Elite Room *(not yet implemented)*
**Concept:** Single elite enemy with boosted health, speed, and a modified attack pattern. Large open arena. Guaranteed rare core drop on kill.
**Intended size:** ~1440 x 810 (+50%)
**Key mechanic:** Elite enemy has 3x health, faster projectiles, and one extra ability (e.g. FireMage Elite gains a fire trail on dash).
**Challenge level:** High — effectively a mini-boss
**Notes:** Closer to a boss fight than a room type. Best used as a pre-boss room or an optional challenge room with a guaranteed rare core reward.

---

### Siege Room *(not yet implemented)*
**Concept:** Player must protect a power core crystal in the center of the room. If the crystal takes too much damage, the player loses a core slot.
**Intended size:** ~1296 x 729 (+35%)
**Key mechanic:** Defensive play style. Enemies path toward the crystal, not just the player.
**Challenge level:** Medium
**Notes:** Requires a CrystalTarget node and enemy AI modification to support dual targeting (player vs crystal).

---

### Maze Room *(not yet implemented)*
**Concept:** Internal walls create a maze of corridors. Enemies and player must navigate the layout. Line-of-sight becomes a key factor.
**Intended size:** ~1440 x 810 (+50%)
**Key mechanic:** Hand-authored or template-based wall grid. Ghost enemies become significantly more dangerous here.
**Challenge level:** Medium
**Notes:** Works especially well with Ghost and Assassin enemy types. Could use predefined wall templates shuffled on load.
