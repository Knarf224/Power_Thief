# Power Thief – Power-Up Buffs Reference

Power-up buffs are temporary one-time pickups that drop randomly from enemies (10% chance on death; guaranteed drop on the 3rd kill in room 1 as a tutorial). They are distinct from **Power Cores** (permanent per-run equipment) and **Perks** (permanent boss rewards).

---

## Drop Mechanics

| Property          | Value                                                                 |
|-------------------|-----------------------------------------------------------------------|
| Drop chance       | 10% on any enemy death (non-boss)                                     |
| Tutorial drop     | Guaranteed on 3rd enemy killed in room 1 (teaches the system)        |
| Despawn time      | 10 seconds after spawning                                             |
| Flash warning     | Pickup flashes in the final 5 seconds before despawn                 |
| Boss immunity     | All bosses are immune to Nuke and Insta Kill effects                  |
| Scene             | `scenes/pickups/PowerUpPickup.tscn`                                   |
| Script            | `scripts/pickups/power_up_pickup.gd`                                  |

---

## Buff Types

### Nuke ☢
> Color: Bright yellow

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | Instantly kills all non-boss enemies in the room | |
| Duration | Instant — one-shot effect | No timer set |
| Visual   | White screen flash (fades out over 0.6s) | |
| Boss immune | Yes | Bosses are unaffected |

---

### Insta Kill ☠
> Color: Red

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | All player hits kill non-boss enemies in one shot regardless of HP | |
| Duration | 10 seconds | `GameState.insta_kill_timer` |
| Boss immune | Yes | Bosses take normal damage |
| Implementation | In `base_enemy.take_damage()`: if timer > 0 and not `is_boss`, sets `health = 0` before applying damage |

---

### Full Heal ♥
> Color: Green

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | Restores player to full health (100 HP) | |
| Duration | Instant — one-shot effect | No timer set |
| Visual   | Floating heart particles spawned at player position | |
| Implementation | Calls `player.heal(MAX_HEALTH)` and `player.spawn_heal_hearts()` |

---

### Shield Burst ⬡
> Color: Blue

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | Player is completely immune to all damage | |
| Duration | 8 seconds | `GameState.shield_burst_timer` |
| Visual   | Pulsing blue aura around player while active | Aura alpha oscillates via sine wave |
| Implementation | In `player.take_damage()`: returns immediately if `shield_burst_timer > 0` |
| Stacks with | Shield Core (perk-level shield still tracked separately) | |

---

### Speed Boost ⚡
> Color: Cyan

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | Player move speed doubled | |
| Duration | 10 seconds | `GameState.speed_boost_timer` |
| Speed while active | 400 (SPEED × 2.0) | Base SPEED = 200 |
| Visual   | Trailing speed particles behind player while moving | |
| Stacks with | Berserker perk (speed boost takes priority in `_move_speed()` check order) | |

---

### Freeze ❄
> Color: Ice blue

| Property | Value | Notes |
|----------|-------|-------|
| Effect   | All non-boss enemies stop moving and are tinted icy blue | |
| Duration | 8 seconds | `GameState.freeze_timer` |
| Boss immune | Yes | Bosses move and attack normally |
| Visual   | Frozen enemies tinted `Color(0.55, 0.85, 1.0)` while timer active | |
| Implementation | In `base_enemy._ai_update()`: velocity set to `Vector2.ZERO`, tint applied, returns before AI runs |

---

## Quick Reference

| Buff         | Icon | Color      | Duration | Effect Summary                          |
|--------------|------|------------|----------|-----------------------------------------|
| Nuke         | ☢    | Yellow     | Instant  | Kill all non-boss enemies               |
| Insta Kill   | ☠    | Red        | 10s      | One-shot all non-boss enemies           |
| Full Heal    | ♥    | Green      | Instant  | Restore to 100 HP                       |
| Shield Burst | ⬡    | Blue       | 8s       | Full damage immunity                    |
| Speed Boost  | ⚡   | Cyan       | 10s      | Move speed ×2                           |
| Freeze       | ❄    | Ice blue   | 8s       | Freeze all non-boss enemies in place    |

---

## Notes

- Timer values in `GameState` (`insta_kill_timer`, `shield_burst_timer`, `speed_boost_timer`, `freeze_timer`) count down each frame via `_process()`. Buffs expire naturally — there is no early cancel.
- Multiple buffs can be active simultaneously (e.g. Speed Boost + Insta Kill).
- Buff timers persist across room transitions (they count down in real time in `GameState`).
