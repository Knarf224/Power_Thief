# Power Thief – MVP Task List

## Overview
**Goal:** Build a minimal playable prototype (Week 1 scope).
**Engine:** Godot 4.3
**Style:** Top-down, simple colored shapes — player and some enemies now use sprite assets

---

## Project Structure
- [x] Create folder structure (`scenes/`, `scripts/`, `assets/`, `resources/`, `scenes/core_system/`)

---

## 1. Player
- [x] Player scene with CharacterBody2D
- [x] WASD top-down movement
- [x] Mouse-aimed basic attack (shoots a projectile, left-click)
- [x] Right-click dash toward mouse cursor
- [x] Health system (take damage, die, `health_changed` signal)
- [x] 3 power core slots (equip/swap, auto-fills empty slot, replaces slot 0 if full)
- [x] Keys **1 / 2 / 3** activate the core in that slot (replaced Spacebar — allows multiple active cores independently)
- [x] Player sprite: `assets/sprites/player_sprite.png` at 1.875× scale (replaced Polygon2D placeholder)

---

## 2. Power Core System
- [x] Core type enum (NONE, DASH, FIRE, SPLIT, PHASE, EXPLOSION, ICE, LIGHTNING, SHIELD, SUMMON, POISON)
- [x] 3-slot core manager on player
- [x] Core pickup world item (star shape, color-coded, bobs up and down)
- [x] Cores inactive (dimmed) until all enemies in room are cleared
- [x] Only ONE core lootable per room — second disappears on pickup
- [x] **Dash Core** — passive, doubles dash speed (500→1000) and duration (0.15→0.30s)
- [x] **Fire Core** — active (slot key), drops fire bomb at feet, 40 AoE damage, 1.5s fuse, 3s cooldown
- [x] **Split Core** — passive, fires 2 projectiles per shot in ±15° V shape
- [x] **Phase Core** — active (slot key), player becomes intangible for 1.5s, 8s cooldown; player goes semi-transparent visually
- [x] **Explosion Core** — passive, every dash leaves a 25 dmg / 80px AoE explosion at the dash start point
- [x] **Ice Core** — passive, shots slow enemies 40% for 2s on hit
- [x] **Lightning Core** — passive, shots chain to up to 2 nearby enemies (8 dmg, 120px chain range) on hit
- [x] **Shield Core** — passive, absorbs one hit completely; recharges in 10s
- [x] **Summon Core** — active (slot key), spawns a ghost ally that chases and attacks enemies for 8s, 15s cooldown
- [x] **Poison Core** — passive, shots apply poison DoT (5 dmg/tick every 0.5s for 3s = 30 total)

---

## 3. Enemies (10 types)
- [x] Base enemy class (`base_enemy.gd`) — health, AI loop, death, core drop, slow effect, poison DoT, stuck-detection teleport system (`teleport_when_stuck`, `teleport_target`, `teleport_zones`), `_is_dying` guard on `take_damage()` to prevent double-death, `_enforce_bounds()` to snap escaped enemies back to room center
- [x] **Fire Mage** — ranged, maintains 160px distance, shoots every 1s, drops Fire Core (red projectile); sprite at 3× scale
- [x] **Rogue Assassin** — chases, dashes at player within 120px, contact damage, drops Dash Core
- [x] **Slime** — slow chase, contact damage, splits into 2 minis on death, Split Core drops from last mini
- [x] **Ghost** — always intangible; only takes damage when player is within 100px, drops Phase Core (white); `_physics_process` calls `_enforce_bounds()` since Ghost bypasses `move_and_slide()`
- [x] **Bomb Beetle** — chases, contact damage, explodes on death (70 dmg / 80px AoE), drops Explosion Core (brown)
- [x] **Ice Witch** — ranged, 180px preferred distance, shots slow player 50% for 3s, drops Ice Core (cyan projectile); sprite at 3× scale
- [x] **Lightning Sprite** — fastest enemy (150 spd), ranged, fast fire rate, drops Lightning Core (yellow projectile)
- [x] **Stone Golem** — tankiest (80 HP), absorbs 1 hit (recharges 8s), 25 contact dmg, drops Shield Core (gray)
- [x] **Necromancer** — ranged, summons up to 3 Spirits every 4s, drops Summon Core (dark purple projectile)
- [x] **Summoned Spirit** — 10 HP (1-shot), 15 contact dmg, spawned by Necromancer only, no core drop
- [x] **Poison Toad** — ranged, 120px preferred distance, shots apply poison DoT, drops Poison Core (yellow-green projectile)
- [x] All projectile-shooting enemies fire color-matched projectiles
- [x] 2 random enemies spawn per room from the 10 available types

---

## 4. Dungeon
- [x] Standard Combat Room — open layout, 2 enemies, room state machine (FIGHTING → CORES_ACTIVE → TRANSITION_READY)
- [x] Walls removed when room is cleared and core is picked up
- [x] "Walk in any direction" prompt shown to player
- [x] Player walks off screen → enters new room from opposite edge with fresh enemies
- [x] `GameState` autoload — persists health, cores, exit direction, room counter across scene changes
- [x] Deterministic room rotation — weighted roll system with streak protection and same-room-twice prevention
- [x] **Room selection algorithm** — rooms 1-3 always Standard, room 4 always forced special, room 5+ weighted roll
- [x] **Ambush Room** — 1920x1080 cross-corridor layout with 4 enclosed corner rooms
  - [x] Trigger zones per corner + center trigger (crossing center spawns all rooms at once)
  - [x] 0.3s arm delay prevents immediate trigger on scene load
  - [x] Ghost / Assassin / BombBeetle weighted 3x in enemy pool
  - [x] Corner teleport zones — enemies stuck in inner corners for 1s teleport to room center (960, 540)
  - [x] Teleport zones marked with dark red-purple floor tiles
  - [x] Core pickup race condition fixed — one-frame delay before checking for empty core group
  - [x] `_enforce_bounds()` safety net — enemies that escape the viewport are snapped to the room center
- [x] **Hazard Floor Room** — 1536x864 with 16×9 tile grid; tiles cycle SAFE→WARNING→DANGER→COOLDOWN
  - [x] 8 DPS while standing on DANGER tile; hazard stops on room clear
  - [x] Difficulty scales: more tiles per wave and shorter warning window as room_counter increases
- [x] **Power Zone Room** — 1280x1280 split into 4 triangular zones by room diagonals
  - [x] Player can only fire basic attack while standing in the active (lit) zone
  - [x] Wave-based enemy spawning — waves do not wait for previous wave to clear
  - [x] Active zone switches on timer with warning flash; never picks same zone twice in a row
- [x] **Blackout Overlay** — optional darkness effect that applies to any room from level 4 onward
  - [x] Scales from 50% activation chance at level 4 to 100% at level 14+
  - [x] Shrinking light radius around player; alternates LIT / DARK phases
- [x] **Boss system** — bosses appear every 4th level overlaid on any room type
  - [x] 5 bosses in random shuffle-bag order — no repeats until all 5 seen, never same boss twice in a row
  - [x] Boss companion count scales separately from normal enemy count (flat formula)
  - [x] All 4 room types support boss spawning and companion count
- [ ] Additional room types (Gauntlet, Siege)

---

## 5. Boss
- [x] **boss_base.gd** — shared base; floating health bar via `_draw()`, `_is_dying` double-death guard, perk drop staging
- [x] **The Warden** — 350 HP, 2-hit iron shield, charges into walls, stunned after wall hit (damage window)
- [x] **The Lich** — 220 HP, invulnerable while spirits alive, summons 3/5 spirits; phases at 40% HP
- [x] **The Phantom** — 180 HP, teleports every 3.5s/2.0s, only vulnerable 1.5s post-teleport, spawns decoys
- [x] **The Plague Lord** — 400 HP, fires poison globs that leave persistent floor pools, phases at 50% HP
- [x] **The Storm Tyrant** — 280 HP, orbits player, homing bolts, storm aura, chain bolt special every 6s
- [x] **Perk select UI** — appears after ALL enemies cleared (not just boss); no cores drop on boss levels
- [x] **11 perks fully implemented** — Auto-Fire, Rapid Fire, Stopping Power, Piercing Shot, Thorns, Life Steal, Death Burst, Berserker, Iron Will, Overclock, Gravity Push
- [x] All perk gameplay effects live and active — not display-only
- [x] Perk symbols displayed in HUD and perk selection UI
- [ ] Win condition / end screen

---

## 6. UI
- [x] Health bar — top left, green fill over red background, shrinks as damage is taken
- [x] Core slot display — bottom left, 3 star-shaped slots that light up with core color when equipped
- [x] Key indicators — 1 / 2 / 3 shown inside each slot box so player knows how to activate cores
- [x] **CORES label** — sits above the slot display; moved up to prevent overlap with slot boxes
- [x] **Level label** — top right, shows current level number (`LEVEL: N`)
- [x] **Perk HUD** — below the LEVEL label (top right); each owned perk shown as "SYMBOL  Name" one per line
- [x] **YOU DIED screen** — dark overlay + large red "YOU DIED" text + "Press R to restart" prompt; R key fully resets GameState (health, cores, perks, room counter) and returns to Home Screen
- [x] **Home Screen** — title + play button; resets GameState on new game start; includes dev tools (see below)
- [x] **Perk Select screen** — fullscreen overlay on boss death; shows 2 perks with symbols, grays out already-owned ones, unpauses and frees self on pick
- [x] **Dev tools (Home Screen)** — `[DEV] Start Level` picker (+/- buttons to set starting room_counter); `[DEV] God Mode` toggle (player health floors at 1, cannot die)
- [ ] Core pickup prompt ("Press E to take / swap")
- [ ] Win screen

---

## Current Core Properties
| Core           | Trigger      | Effect                                          | Cooldown | Dropped By           |
|----------------|--------------|-------------------------------------------------|----------|----------------------|
| Dash Core      | Passive      | 2× dash speed + duration                        | —        | Rogue Assassin       |
| Fire Core      | Slot key     | Fire bomb — 40 AoE dmg, 80px radius, 1.5s fuse | 3.0s     | Fire Mage            |
| Split Core     | Passive      | 2 projectiles per shot at ±15°                  | —        | Slime (last mini)    |
| Phase Core     | Slot key     | 1.5s intangibility, player goes transparent     | 8.0s     | Ghost                |
| Explosion Core | Passive      | Dash leaves 25 dmg / 80px explosion at origin  | —        | Bomb Beetle          |
| Ice Core       | Passive      | Shots slow enemies 40% for 2s                   | —        | Ice Witch            |
| Lightning Core | Passive      | Shots chain to 2 nearby enemies (8 dmg, 120px) | —        | Lightning Sprite     |
| Shield Core    | Passive      | Absorbs 1 hit; recharges in 10s                 | —        | Stone Golem          |
| Summon Core    | Slot key     | Ghost ally attacks enemies for 8s               | 15.0s    | Necromancer          |
| Poison Core    | Passive      | Shots apply 5 dmg/tick for 3s (30 total)        | —        | Poison Toad          |

---

## Remaining MVP Items
- [ ] Additional room types (Gauntlet, Siege)
- [ ] Win screen / end condition after all boss cycles
- [ ] Core pickup prompt UI ("Press E to take / swap")
- [ ] Core Selection UI — when all 3 slots are full, show UI to choose which slot to replace (currently auto-replaces slot 0)

---

## Upcoming Features

### Core Selection UI
When the player picks up a core and all 3 slots are already full, display a slot-choice overlay so the player can decide which core to replace instead of auto-replacing slot 0.
- [ ] Design and build `CoreSwapUI.tscn` — shows all 3 current slots + incoming core
- [ ] Pause game while UI is open
- [ ] Confirm selection replaces chosen slot; cancel keeps existing loadout
- [ ] Integrate into `core_pickup.gd` pickup flow

### Balance & Tuning Pass
Several cores and perks feel underpowered compared to others; dedicated tools are needed to iterate without rebuilding.
- [ ] Identify weakest cores and perks through playtesting (Poison Core, Split Core candidates)
- [ ] Add in-game stat overlay (dev build only) showing DPS, perk status, room_counter
- [ ] Tune Fire Core bomb radius (80px may be too small for slower enemies)
- [ ] Tune Overclock reduction amount (30% may not feel impactful enough)
- [ ] Tune Berserker threshold (30 HP — consider whether triggering is too rare)

### Sprite & Animation Improvements
Replace remaining placeholder colored shapes with art assets and add idle/attack animations.
- [ ] Replace all remaining colored polygon enemies with sprites (Assassin, Slime, Ghost, Bomb Beetle, Lightning Sprite, Stone Golem, Necromancer, Poison Toad)
- [ ] Replace all boss placeholder shapes with sprites
- [ ] Add idle animation (looping) for player and all enemies
- [ ] Add attack/shoot animation frame for ranged enemies
- [ ] Add death animation (brief) before `queue_free()`

### Music
Background music tracks for rooms and boss encounters.
- [ ] Source or compose a standard combat loop track
- [ ] Source or compose a boss fight loop track (higher intensity)
- [ ] Wire tracks to room type — boss fight music starts on boss spawn, returns to room music on boss death
- [ ] Add basic volume control option on Home Screen

### High Score System
Track how far each run reaches and display a leaderboard.
- [ ] Store `furthest_room_counter` in a persistent save file (`user://scores.cfg`)
- [ ] Display personal best on Home Screen ("Best: Level N")
- [ ] Show final level reached on YOU DIED screen
- [ ] Optional: local top-5 run history list

---

## Out of Scope for MVP
- Procedural dungeon generation (hand-placed rooms only)
- Meta progression / unlocks
- Online features
- Shop rooms, Challenge rooms
- Synergies between cores (beyond existing interactions)

---

## File Structure (current)
```
new-game-project/
├── scenes/
│   ├── player/       # Player.tscn, Projectile.tscn, FireBomb.tscn, DashExplosion.tscn, SummonedAlly.tscn
│   ├── enemies/      # FireMage.tscn, Assassin.tscn, Slime.tscn, Ghost.tscn, BombBeetle.tscn,
│   │                 # IceWitch.tscn, LightningSprite.tscn, StoneGolem.tscn, Necromancer.tscn,
│   │                 # PoisonToad.tscn, SummonedSpirit.tscn
│   │                 # Projectiles: EnemyProjectile.tscn, FireMageProjectile.tscn,
│   │                 # IceProjectile.tscn, LightningProjectile.tscn,
│   │                 # NecromancerProjectile.tscn, PoisonToadProjectile.tscn
│   │   └── bosses/   # Warden.tscn, Lich.tscn, Phantom.tscn, PlagueLord.tscn, StormTyrant.tscn
│   │                 # LichSpirit.tscn, PhantomDecoy.tscn
│   │                 # LichProjectile.tscn, PhantomProjectile.tscn
│   │                 # PlagueLordProjectile.tscn, PoisonPool.tscn, StormBolt.tscn
│   ├── core_system/  # CorePickup.tscn
│   ├── dungeon/      # AmbushRoom.tscn, HazardFloorRoom.tscn, PowerZoneRoom.tscn, BlackoutRoom.tscn
│   ├── fx/           # DeathBurstFx.tscn, GravityPushFx.tscn
│   └── ui/           # HUD.tscn, HomeScreen.tscn, PerkSelect.tscn
├── scripts/
│   ├── autoload/     # game_state.gd  ← persists all run state across scene changes
│   ├── player/       # player.gd, projectile.gd, fire_bomb.gd, dash_explosion.gd, summoned_ally.gd
│   ├── enemies/      # base_enemy.gd, fire_mage.gd, assassin.gd, slime.gd, ghost.gd,
│   │                 # bomb_beetle.gd, ice_witch.gd, lightning_sprite.gd, stone_golem.gd,
│   │                 # necromancer.gd, summoned_spirit.gd, poison_toad.gd, enemy_projectile.gd
│   │   └── bosses/   # boss_base.gd, warden.gd, lich.gd, phantom.gd, plague_lord.gd, storm_tyrant.gd
│   │                 # lich_spirit.gd, phantom_decoy.gd
│   │                 # plague_lord_projectile.gd, poison_pool.gd, storm_bolt.gd
│   ├── core_system/  # core_pickup.gd
│   ├── dungeon/      # main.gd, ambush_room.gd, hazard_floor_room.gd, power_zone_room.gd
│   │                 # blackout_overlay.gd
│   ├── fx/           # death_burst_fx.gd, gravity_push_fx.gd
│   └── ui/           # hud.gd, home_screen.gd, perk_select.gd
├── docs/             # boss.md, enemies.md, rooms.md, staging.md, TASK.md
├── resources/
│   └── power_cores/  # (placeholder)
└── assets/
    ├── sprites/      # player_sprite.png
    ├── enemies/      # (placeholder)
    └── audio/        # (placeholder)
```
