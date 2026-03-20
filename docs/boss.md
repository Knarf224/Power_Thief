# Power Thief – Boss & Perk Reference

Bosses appear at **levels 4, 8, 12, 16…** (every 4th level). They are not their own room type — a boss can appear inside any room (Standard Combat, Ambush, Hazard Floor, Power Zone). The room still runs its normal logic; the boss spawns alongside a scaled group of companions. On death the boss drops a **perk choice panel** (player picks 1 of 2 randomly drawn perks).

---

## Boss System Rules

| Property                | Value / Rule                                                                 |
|-------------------------|------------------------------------------------------------------------------|
| Boss trigger            | `(room_counter + 1) % 4 == 0` — levels 4, 8, 12, 16…                       |
| Boss count per room     | Always 1                                                                     |
| Companion count         | Scales via `get_boss_companion_count()` — flat formula, separate from normal |
| Companion formula       | `2 + boss_index * 2`                                                         |
| Companion curve         | L4: 2, L8: 4, L12: 6, L16: 8, L20: 10                                      |
| Boss order              | Random shuffle-bag — all 5 seen before any repeat; never same boss twice in a row |
| Perk draw on boss death | 2 random perks shown from that boss's pool; player picks 1                  |
| Already-owned perks     | Still appear in the draw but are grayed out and unselectable                 |
| Max perks               | 11 total in the pool; player can hold all 11 over time                       |

---

## Bosses

---

### The Warden
> Scene: `scenes/enemies/bosses/Warden.tscn`
> Script: `scripts/enemies/bosses/warden.gd`
> Sprite color: **Dark gray / iron**

**Concept:** A heavily armoured melee brute that defends a section of the room. Slow on approach but telegraphs devastating charges — the player must bait the charge, dodge to the side, and punish the recovery window. Forces constant repositioning.

| Property               | Value      | Notes                                                           |
|------------------------|------------|-----------------------------------------------------------------|
| Max Health             | 350        | ~4× a Stone Golem                                              |
| Walk Speed             | 45         | Very slow — gives the player room to breathe                   |
| Charge Speed           | 700        | Faster than a player dash — commits fully to direction          |
| Charge Windup          | 0.8s       | Visible telegraph before the charge launches                    |
| Charge Distance        | Room width | Travels until it hits a wall or the player                   |
| Charge Damage          | 40         | On collision with player                                        |
| Stun Duration (self)   | 1.2s       | Warden is stunned after hitting a wall — damage window          |
| Contact Damage         | 20         | Slow contact when not charging                                  |
| Contact Cooldown       | 1.0s       |                                                                 |
| Charge Cooldown        | 4.0s       | Time between charges                                            |
| Shield Hits            | 2          | Iron plates absorb 2 hits before HP is touched; recharges 12s  |
| Companion Type         | Stone Golem                                                     |
| Perk Drop Pool         | Stopping Power, Gravity Push, Thorns, Berserker                 |

**Phase behaviour (no phases yet — single health bar):**
- Below 50% HP: charge cooldown reduces to 2.5s and charge speed increases to 900.

---

### The Lich
> Scene: `scenes/enemies/bosses/Lich.tscn`
> Script: `scripts/enemies/bosses/lich.gd`
> Sprite color: **Dark purple / bone white**

**Concept:** A frail but protected spellcaster. Periodically raises a shield of undead — while any summoned spirit is alive the Lich is completely invulnerable. Player must clear the spirits before dealing boss damage. Forces priority target switching under pressure.

| Property               | Value   | Notes                                                              |
|------------------------|---------|--------------------------------------------------------------------|
| Max Health             | 220     | Low for a boss — threat is the invulnerability window              |
| Move Speed             | 80      | Slow drift, always trying to maintain distance                     |
| Preferred Distance     | 200px   |                                                                    |
| Shoot Cooldown         | 1.5s    |                                                                    |
| Projectile Damage      | 20      |                                                                    |
| Projectile Speed       | 280     |                                                                    |
| Summon Cooldown        | 5.0s    | Calls spirits at this interval                                     |
| Spirits per Summon     | 3       | Always summons 3 at once                                           |
| Max Active Spirits     | 6       | Will not summon past this cap                                      |
| Invulnerability        | Active while any spirit is alive — breaks when all spirits are dead |
| Spirit HP              | 10      | Same as Necromancer spirits — 1 shot each                          |
| Spirit Contact Damage  | 15      |                                                                    |
| Spirit Move Speed      | 120     |                                                                    |
| Companion Type         | Necromancer                                                        |
| Perk Drop Pool         | Rapid Fire, Piercing Shot, Auto-Fire                               |

**Phase behaviour:**
- Below 40% HP: summons 5 spirits per wave instead of 3; shoot cooldown drops to 0.8s.

---

### The Phantom
> Scene: `scenes/enemies/bosses/Phantom.tscn`
> Script: `scripts/enemies/bosses/phantom.gd`
> Sprite color: **Pale blue / translucent white**

**Concept:** An elusive hunter that teleports around the room and creates ghostly decoys. Decoys look identical but deal no damage and vanish after one player hit. The real Phantom is only vulnerable for a short window after each teleport, forcing the player to identify and burst it quickly.

| Property               | Value   | Notes                                                              |
|------------------------|---------|--------------------------------------------------------------------|
| Max Health             | 180     | Lowest boss HP — the evasion is the defence                        |
| Move Speed             | 130     | Fast drift between teleports                                       |
| Teleport Cooldown      | 3.5s    | Disappears and reappears at a random room position                 |
| Vulnerability Window   | 1.5s    | Only takes damage for 1.5s after materialising post-teleport       |
| Invulnerability        | Active between teleports and after vulnerability window closes      |
| Decoys Spawned         | 2       | Spawned alongside each teleport; look identical to the Phantom     |
| Decoy HP               | 1       | Disappear on any hit                                               |
| Contact Damage         | 18      | Real Phantom + decoys both deal damage on contact                  |
| Contact Cooldown       | 0.8s    |                                                                    |
| Shoot Cooldown         | 2.0s    | Fires a spread of 3 slow projectiles                               |
| Projectile Damage      | 12      | Per projectile                                                     |
| Projectile Speed       | 200     | Slow — hard to dodge in a tight room but easy in open space        |
| Companion Type         | Ghost                                                              |
| Perk Drop Pool         | Piercing Shot, Auto-Fire, Life Steal                               |

**Phase behaviour:**
- Below 50% HP: teleport cooldown reduces to 2.0s; spawns 3 decoys instead of 2.

---

### The Plague Lord
> Scene: `scenes/enemies/bosses/PlagueLord.tscn`
> Script: `scripts/enemies/bosses/plague_lord.gd`
> Sprite color: **Yellow-green / sickly brown**

**Concept:** A slow-moving tank that denies floor space by vomiting persistent poison pools. Over time the room fills with hazardous zones the player must dodge around, while still fighting companions and the boss itself. Rewards patience and map awareness.

| Property               | Value   | Notes                                                              |
|------------------------|---------|--------------------------------------------------------------------|
| Max Health             | 400     | Second highest boss HP — very tanky                                |
| Move Speed             | 40      | Slowest boss — the pools do the work                               |
| Shoot Cooldown         | 1.8s    | Lobs poison globs in an arc at the player                          |
| Projectile Damage      | 8       | Low direct damage                                                  |
| Projectile Speed       | 220     | Lobbed arc trajectory                                              |
| Pool Radius            | 60px    | Poison pool placed where the projectile lands                      |
| Pool Duration          | 8.0s    | Pool persists on the floor for 8 seconds                           |
| Pool Damage/Tick       | 4       | Damage per tick while player stands in the pool                    |
| Pool Tick Rate         | 0.5s    | = 8 DPS from each pool; stacks across overlapping pools            |
| Max Active Pools       | 12      | Old pools disappear when cap is reached (oldest removed first)     |
| Contact Damage         | 12      |                                                                    |
| Contact Cooldown       | 1.0s    |                                                                    |
| Companion Type         | Poison Toad                                                        |
| Perk Drop Pool         | Life Steal, Thorns, Death Burst, Iron Will                         |

**Phase behaviour:**
- Below 50% HP: shoot cooldown reduces to 1.0s and pool duration extends to 12s.

---

### The Storm Tyrant
> Scene: `scenes/enemies/bosses/StormTyrant.tscn`
> Script: `scripts/enemies/bosses/storm_tyrant.gd`
> Sprite color: **Electric yellow / white**

**Concept:** An aggressive aerial attacker that keeps the pressure on with homing lightning bolts and a persistent storm aura that zaps the player if they stay too close. Rewards kiting and constant movement — standing still is always punished.

| Property               | Value   | Notes                                                              |
|------------------------|---------|--------------------------------------------------------------------|
| Max Health             | 280     |                                                                    |
| Move Speed             | 110     | Moderately fast — always circling the player                       |
| Shoot Cooldown         | 1.2s    | Fires a homing bolt                                                |
| Homing Bolt Damage     | 18      |                                                                    |
| Homing Bolt Speed      | 300     | Initial speed; homes toward player position at launch              |
| Homing Bolt Lifetime   | 3.0s    | Despawns if it hasn't hit anything                                 |
| Homing Turn Rate       | 90°/s   | How fast the bolt curves toward the player                         |
| Storm Aura Radius      | 100px   | Electric field around the boss at all times                        |
| Storm Aura Damage/Tick | 6       |                                                                    |
| Storm Aura Tick Rate   | 0.4s    | = 15 DPS if player stands inside aura                              |
| Chain Bolt (special)   | Every 6s fires a chain bolt that jumps to 3 targets for 15 dmg each |
| Companion Type         | Lightning Sprite                                                   |
| Perk Drop Pool         | Rapid Fire, Gravity Push, Death Burst, Overclock                   |

**Phase behaviour:**
- Below 40% HP: storm aura radius expands to 160px and homing bolt shoot cooldown drops to 0.7s.

---

## Boss Health Bar

All bosses display a **floating health bar** positioned above the sprite (not in the HUD). Implemented in `boss_base.gd` via `_draw()` on the Node2D — no separate child nodes required.

- `BAR_WIDTH = 100px`, `BAR_HEIGHT = 10px`, `BAR_Y = -58` (above sprite)
- Background: `Color(0.22, 0.04, 0.04)` — dark crimson
- Fill: `Color(0.85, 0.12, 0.12)` — bright red, width scales with `health / max_health`
- Border: `Color(0.6, 0.6, 0.6)` — gray outline, 1px
- Boss name drawn above bar using `ThemeDB.fallback_font` at size 13, color `Color(0.92, 0.72, 0.72)`
- `queue_redraw()` called every frame in `_process()` to keep bar current

---

## Perks

Perks are permanent buffs granted by defeating a boss. They persist across all levels in `GameState.player_perks`. On boss death, 2 perks are randomly drawn from that boss's specific pool; the player selects 1. Already-owned perks appear grayed out and cannot be selected (but can still be drawn, which wastes a slot in the pair — encourages collecting new perks early).

**All 11 perks are fully implemented** — gameplay effects are live, not display-only.

**Max perks a player can hold:** 11 (one of each — no duplicates)

Perks are displayed in the HUD below the LEVEL counter (top-right corner) as a list, one per line, in the format `SYMBOL  Name`.

---

### Perk Pool

| # | Symbol | ID              | Name            | Effect                                                                              | Type    |
|---|--------|-----------------|-----------------|------------------------------------------------------------------------------------|---------|
| 1 | `∞`    | auto_fire       | Auto-Fire       | Holding the fire button fires continuously at the player's fire rate               | Passive |
| 2 | `≫`    | rapid_fire      | Rapid Fire      | Player fire rate increased by 40% (shoot cooldown × 0.6)                           | Passive |
| 3 | `✦`    | stopping_power  | Stopping Power  | Player shots deal +30% damage                                                      | Passive |
| 4 | `⇒`    | piercing_shot   | Piercing Shot   | Player shots pass through enemies, hitting every target in their path              | Passive |
| 5 | `※`    | thorns          | Thorns          | When the player takes contact damage, the attacker receives 50% of the damage back | Passive |
| 6 | `♥`    | life_steal      | Life Steal      | Killing an enemy restores 2 HP (capped at max health)                              | Passive |
| 7 | `✸`    | death_burst     | Death Burst     | Enemies explode on death dealing 20 AoE damage in a 60px radius                   | Passive |
| 8 | `⚡`   | berserker       | Berserker       | Below 30 HP: move speed ×1.5 and fire rate ×2                                     | Passive |
| 9 | `◆`    | iron_will       | Iron Will       | Once per room, survive a killing blow at 1 HP instead of dying                     | Passive |
|10 | `⊙`    | overclock       | Overclock       | Active core cooldowns (Fire Bomb, Phase, Summon) reduced by 30%                    | Passive |
|11 | `⊕`    | gravity_push    | Gravity Push    | Dashing repels all enemies within 250px at 800px/s; blue shockwave ring FX on activation | Passive |

---

### Perk Details

#### Auto-Fire (`∞`)
- Holding the mouse button fires automatically at the normal fire rate.
- Implementation: checks `Input.is_action_pressed("fire")` instead of `_just_pressed` when perk is active.

---

#### Rapid Fire (`≫`)
- Multiplies the player's fire cooldown by 0.6 (40% faster firing).
- Stacks multiplicatively if other fire rate modifiers are added later.
- Implementation: `_shoot_cooldown *= 0.6` applied in `_ready()` when perk is detected.

---

#### Stopping Power (`✦`)
- Player projectiles deal 30% more damage.
- Implementation: projectile damage multiplied by 1.3 when perk is active.

---

#### Piercing Shot (`⇒`)
- Player projectiles no longer despawn on the first enemy hit. They continue travelling and can hit multiple enemies.
- Still despawns at end of `Projectile Lifetime` (2.0s) or on wall collision.
- Implementation: in `projectile.gd`, skip `queue_free()` on enemy hit when perk is active.

---

#### Thorns (`※`)
- When the player receives contact damage from an enemy, that enemy takes `damage_received * 0.5` (rounded down, minimum 1).
- Does not trigger from projectile or hazard damage — only direct contact.
- Implementation: in `player.gd` `take_damage()`, if source is a contact attacker and perk is active, call `source.take_damage(damage / 2)`.

---

#### Life Steal (`♥`)
- Each enemy that dies (is killed, not just damaged) restores 2 HP to the player.
- Capped at `MAX_HEALTH`. Does not trigger on self-destructing enemies (Bomb Beetle explosion).
- Implementation: connected to enemy `died` signal or checked in the enemy death handler.

---

#### Death Burst (`✸`)
- When any enemy dies, it triggers a 60px radius explosion dealing 20 damage to all enemies (not the player) within range.
- Works on all enemies including Summoned Spirits and Slime minis.
- Can chain: if an explosion kills another enemy, that enemy also bursts.
- Visual effect: orange expanding ring + spike FX (`scenes/fx/DeathBurstFx.tscn`, `scripts/fx/death_burst_fx.gd`).
- Re-entrant death crash fixed — `_is_dying` guard on `base_enemy.take_damage()` prevents a chained burst from triggering double-death on an already-dying enemy.
- Implementation: on enemy death, instantiate an AoE check at the death position; deal damage to overlapping enemies in the `enemy` group.

---

#### Berserker (`⚡`)
- While the player's health is below 30 HP: move speed is multiplied by 1.5 and fire rate is multiplied by 2 (shoot cooldown halved).
- Activates and deactivates dynamically as health crosses the 30 HP threshold.
- Implementation: checked every frame in player `_process()`; multipliers applied/removed when threshold is crossed.

---

#### Iron Will (`◆`)
- Once per room, if the player would be reduced to 0 HP or below, they survive at exactly 1 HP instead.
- Resets at the start of each new room.
- Implementation: flag `iron_will_used` checked in `player.take_damage()`; if the hit would be lethal and the flag is false, clamp health to 1 and set the flag.

---

#### Overclock (`⊙`)
- Active core cooldowns for Fire Core, Phase Core, and Summon Core are each reduced by 30%.
- Implementation: cooldown values multiplied by 0.7 when perk is detected in `_ready()`.

---

#### Gravity Push (`⊕`)
- On dash activation, all enemies within **250px** are pushed directly away from the player's position at **800px/s** as an impulse.
- Blue shockwave ring visual effect plays at the player's position on each activation (`scenes/fx/GravityPushFx.tscn`, `scripts/fx/gravity_push_fx.gd`).
- Implementation: in `player.gd` dash logic, iterate the `enemy` group and apply `velocity += direction * 800` for enemies within 250px when perk is active.

---

## Perk × Boss Drop Matrix

| Boss             | Perk Pool                                              |
|------------------|--------------------------------------------------------|
| The Warden       | Stopping Power (`✦`), Gravity Push (`⊕`), Thorns (`※`), Berserker (`⚡`) |
| The Lich         | Rapid Fire (`≫`), Piercing Shot (`⇒`), Auto-Fire (`∞`) |
| The Phantom      | Piercing Shot (`⇒`), Auto-Fire (`∞`), Life Steal (`♥`) |
| The Plague Lord  | Life Steal (`♥`), Thorns (`※`), Death Burst (`✸`), Iron Will (`◆`) |
| The Storm Tyrant | Rapid Fire (`≫`), Gravity Push (`⊕`), Death Burst (`✸`), Overclock (`⊙`) |

> The 2 perks shown on boss death are randomly drawn **from that boss's specific pool**, not the global pool. This loosely ties perk flavour to boss theme while still providing some randomness.

---

## Perk Selection Flow

The perk UI fires **after all enemies in the room are dead** (not just the boss). This prevents the player from being stuck unable to clear remaining companions or open exits.

1. Boss dies → `boss_base._on_death()` calls `GameState.stage_perk_select(perk_a, perk_b)`, setting `boss_defeated_this_level = true` and storing the two chosen perks. No UI yet.
2. Room state machine detects all enemies cleared → checks `boss_defeated_this_level`.
3. If true: opens exits and calls `GameState.open_pending_perk_select()` (deferred). Skips core activation entirely — **no cores drop on boss levels**.
4. Perk UI (`PerkSelect.tscn`) appears paused over the room. Player picks one perk.
5. `_pick()` appends to `GameState.player_perks`, unpauses, frees the UI. Exits are already open.
6. `GameState.boss_defeated_this_level` is reset to `false` in `next_room_scene()`.

---

## Implementation Checklist

### GameState
- [x] `player_perks: Array` — list of owned perk IDs (e.g. `["rapid_fire", "thorns"]`)
- [x] `boss_defeated_this_level: bool` — set true on boss death, reset each room transition
- [x] `is_boss_level() -> bool` — returns `(room_counter + 1) % 4 == 0`
- [x] `get_boss_scene() -> String` — cycles through `BOSS_SCENES` in random shuffle-bag order (no repeats until all 5 seen, never same twice in a row)
- [x] `get_boss_companion_count() -> int` — flat formula: `2 + boss_index * 2`
- [x] `stage_perk_select(a, b)` — stores perks and sets flag; no UI yet
- [x] `open_pending_perk_select()` — deferred call that instantiates and adds `PerkSelect.tscn`

### Per-boss scripts
- [x] `scripts/enemies/bosses/warden.gd`
- [x] `scripts/enemies/bosses/lich.gd`
- [x] `scripts/enemies/bosses/phantom.gd`
- [x] `scripts/enemies/bosses/plague_lord.gd`
- [x] `scripts/enemies/bosses/storm_tyrant.gd`

### Boss support scripts
- [x] `scripts/enemies/bosses/lich_spirit.gd` — summonable spirit (boss_spirit group)
- [x] `scripts/enemies/bosses/phantom_decoy.gd` — decoy clone (1 HP, contact damage)
- [x] `scripts/enemies/bosses/plague_lord_projectile.gd` — poison glob, spawns PoisonPool on land
- [x] `scripts/enemies/bosses/poison_pool.gd` — Area2D, 60px, 4 dmg/0.5s tick, timed lifetime
- [x] `scripts/enemies/bosses/storm_bolt.gd` — homing bolt + chain variant

### Shared boss infrastructure
- [x] `scripts/enemies/bosses/boss_base.gd` — floating health bar (`_draw()`), `_is_dying` guard, perk drop staging
- [x] `scripts/ui/perk_select.gd` — 2-choice panel, shows "Already Owned" for duplicates, displays perk symbols
- [x] `scenes/ui/PerkSelect.tscn`

### FX scenes & scripts
- [x] `scenes/fx/DeathBurstFx.tscn` / `scripts/fx/death_burst_fx.gd` — orange ring + spike burst on enemy death
- [x] `scenes/fx/GravityPushFx.tscn` / `scripts/fx/gravity_push_fx.gd` — blue shockwave ring on dash repel

### Perk gameplay implementations
- [x] Auto-Fire — hold-to-fire input
- [x] Rapid Fire — shoot cooldown × 0.6
- [x] Stopping Power — projectile damage × 1.3
- [x] Piercing Shot — projectile passes through enemies
- [x] Thorns — contact retaliation 50%
- [x] Life Steal — heal 2 HP on kill
- [x] Death Burst — 60px AoE explosion on enemy death with visual FX
- [x] Berserker — speed × 1.5 and fire rate × 2 below 30 HP
- [x] Iron Will — survive one killing blow at 1 HP per room
- [x] Overclock — active core cooldowns × 0.7
- [x] Gravity Push — 250px repel at 800px/s on dash with visual FX

### HUD perk display
- [x] Perks listed below LEVEL counter (top-right) as `SYMBOL  Name` lines

### Room integration
- [x] All 4 room types check `GameState.is_boss_level()` in `_ready()` and call `_spawn_boss()`
- [x] `_spawn_boss()` places boss on the far side of the room from the player's entry point
- [x] Companion count uses `GameState.get_boss_companion_count()` on boss levels
- [x] All 4 room state machines skip core activation on boss levels; open exits + show perk UI instead

### Pending
- [x] Win screen / end condition — `WinScreen.tscn` shown after all 5 bosses defeated; Endless Mode or Main Menu buttons

### Bug Fixes Applied
- **Level 4 crash (boss scene null load):** `boss_base.gd` was re-declaring `var is_boss := true` which already exists in `base_enemy.gd` — GDScript 4 parse error caused all boss `.tscn` files to return `null` on `load()`, crashing on `.instantiate()`. Fixed by removing the `var` declaration and using assignment `is_boss = true` in `_ready()`.
- **`warden.gd` extends path typo:** `"boses"` corrected to `"bosses"`.
- **`phantom.gd` extends prefix typo:** `sextends` corrected to `extends`.
