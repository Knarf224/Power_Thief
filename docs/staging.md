# Staging Guide — Power Thief

Use this guide when testing a specific room or enemy type without playing through the full game.

---

## How to Enable Staging Mode

Open `scripts/autoload/game_state.gd` and make two changes:

**1. Flip the staging flag ON**
```gdscript
# Change this:
var staging_mode := false
# To:
var staging_mode := true
```

**2. Set the room you are testing**
```gdscript
var staging_room := "res://scenes/dungeon/HazardFloorRoom.tscn"
#                                          ^ change to whatever scene you are working on
```

**3. Run the scene directly with F6**
- In the Godot editor, open the scene file you want to test
- Press **F6** (Run Current Scene) — this skips the main scene and starts directly in your room
- Press **F5** to run the full game from the beginning as normal

---

## What Staging Mode Does

| Behavior               | Normal mode                          | Staging mode                   |
|------------------------|--------------------------------------|--------------------------------|
| Enemy count per room   | Scales with room_counter (2→4→6→9…) | **1** (always)                 |
| Room after clearing    | Weighted random selection            | **Loops back to staging_room** |
| Starting room (F6)     | Current open scene                   | Current open scene             |
| Starting room (F5)     | Main.tscn                            | Main.tscn (unchanged)          |

All rooms call `GameState.get_enemy_count(default)` so the count drops to 1 automatically — no per-room changes needed.

**Normal mode enemy scaling (base 2):** room 1 = 2, room 2 = 4, room 3 = 6, room 4 = 9, room 5 = 13 ...
All room types use this same total — special rooms distribute it across zones or waves but never exceed it.
See `docs/rooms.md` → Enemy Scaling for the full progression table.

---

## How to Return to Full Game Mode

```gdscript
var staging_mode := false   # ← flip back to false
var quick_mode   := false   # ← also reset this if you used it
```

That's it. The room rotation and enemy counts return to normal instantly.

---

## Testing the Room Order Algorithm (Quick Mode)

If you want to see the **weighted room selection** play out without killing large enemy waves:

**1. Enable quick mode**
```gdscript
var quick_mode := true
```

**2. Press F5** (Run Project) — do NOT use F6 here; you want the full game flow.

**3. Kill the 1 enemy per room and walk out.** You will see rooms cycle according to the actual algorithm:
- Rooms 1–3 are always Standard Combat
- Room 4 is always a forced random special
- Room 5+ uses a weighted roll — Standard Combat wins ~53% at baseline, rising if specials appear back-to-back
- The same special room never appears twice in a row, but back-to-back specials of different types are allowed

`staging_mode` is NOT the right tool for this — it locks the room to `staging_room` and bypasses `_pick_room()` entirely.

---

## Testing a Specific Enemy Type

If you want to test a specific enemy in the staging room, temporarily edit the room's `ENEMY_SCENES` or `ENEMY_POOL` to only contain that enemy type. Remember to revert after testing.

Example — test only the Poison Toad in HazardFloorRoom:
```gdscript
# In hazard_floor_room.gd, temporarily replace ENEMY_SCENES with:
const ENEMY_SCENES = [
    "res://scenes/enemies/PoisonToad.tscn",
]
```

---

## Testing a Specific Enemy Count

If you need more than 1 enemy for a specific test (e.g. testing crowd behavior), override the count directly in the room's `_spawn_enemies()` for that session:

```gdscript
# Temporarily change:
var count := GameState.get_enemy_count(2)
# To a hardcoded number:
var count := 3
```

Revert when done.

---

## Quick Reference — Room Scene Paths

| Room               | Scene path                                      |
|--------------------|-------------------------------------------------|
| Standard Combat    | `res://scenes/Main.tscn`                        |
| Ambush Room        | `res://scenes/dungeon/AmbushRoom.tscn`          |
| Hazard Floor Room  | `res://scenes/dungeon/HazardFloorRoom.tscn`     |
| Power Zone Room    | `res://scenes/dungeon/PowerZoneRoom.tscn`       |

---

## Checklist Before Committing

- [ ] `staging_mode` is set back to `false`
- [ ] Any temporary enemy pool overrides are reverted
- [ ] Any hardcoded spawn counts are reverted to `GameState.get_enemy_count(N)`
