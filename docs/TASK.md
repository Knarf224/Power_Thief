# Power Thief – MVP Task List

## Overview
**Goal:** Build a minimal playable prototype (Week 1 scope).
**Engine:** Godot 4.3
**Style:** Top-down, simple colored shapes (no art assets required for MVP)

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
- [x] Base enemy class (`base_enemy.gd`) — health, AI loop, death, core drop, slow effect, poison DoT, stuck-detection teleport system (`teleport_when_stuck`, `teleport_target`, `teleport_zones`)
- [x] **Fire Mage** — ranged, maintains 160px distance, shoots every 1s, drops Fire Core (red projectile)
- [x] **Rogue Assassin** — chases, dashes at player within 120px, contact damage, drops Dash Core
- [x] **Slime** — slow chase, contact damage, splits into 2 minis on death, Split Core drops from last mini
- [x] **Ghost** — always intangible; only takes damage when player is within 100px, drops Phase Core (white)
- [x] **Bomb Beetle** — chases, contact damage, explodes on death (70 dmg / 80px AoE), drops Explosion Core (brown)
- [x] **Ice Witch** — ranged, 180px preferred distance, shots slow player 50% for 3s, drops Ice Core (cyan projectile)
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
- [x] Deterministic room rotation — Ambush Room always appears as 2nd room, then every 3rd after
- [x] **Ambush Room** — 1920x1080 cross-corridor layout with 4 enclosed corner rooms
  - [x] Trigger zones per corner + center trigger (crossing center spawns all rooms at once)
  - [x] 0.3s arm delay prevents immediate trigger on scene load
  - [x] Ghost / Assassin / BombBeetle weighted 3x in enemy pool
  - [x] 3 enemies per triggered room (max 12 total)
  - [x] Corner teleport zones — enemies stuck in inner corners for 1s teleport to room center (960, 540)
  - [x] Teleport zones marked with dark red-purple floor tiles
  - [x] Core pickup race condition fixed — one-frame delay before checking for empty core group
- [ ] Additional room types (Gauntlet, Elite, Siege, Maze)
- [ ] Boss room

---

## 5. Boss
- [ ] Boss scene (larger enemy, more health)
- [ ] Phase 1: Basic elemental attacks
- [ ] Phase 2: Steals one of the player's cores temporarily
- [ ] Drops a core on death
- [ ] Win condition triggers when boss dies

---

## 6. UI
- [x] Health bar — top left, green fill over red background, shrinks as damage is taken
- [x] Core slot display — bottom left, 3 star-shaped slots that light up with core color when equipped
- [x] Key indicators — 1 / 2 / 3 shown inside each slot box so player knows how to activate cores
- [x] **YOU DIED screen** — dark overlay + large red "YOU DIED" text + "Press R to restart" prompt; R key fully resets GameState and returns to room 1
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
- [ ] Additional room types (Gauntlet, Elite, Siege, or Maze)
- [ ] Boss fight
- [ ] Win screen
- [ ] Core pickup prompt UI

---

## Out of Scope for MVP
- Procedural dungeon generation (hand-placed rooms only)
- Meta progression / unlocks
- Sound design
- Art assets / animations
- Synergies between cores
- Shop rooms, Challenge rooms
- Online features

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
│   ├── core_system/  # CorePickup.tscn
│   ├── dungeon/      # AmbushRoom.tscn
│   ├── ui/           # HUD.tscn
│   └── boss/         # (empty — next milestone)
├── scripts/
│   ├── autoload/     # game_state.gd  ← persists player state across scene changes
│   ├── player/       # player.gd, projectile.gd, fire_bomb.gd, dash_explosion.gd, summoned_ally.gd
│   ├── enemies/      # base_enemy.gd, fire_mage.gd, assassin.gd, slime.gd, ghost.gd,
│   │                 # bomb_beetle.gd, ice_witch.gd, lightning_sprite.gd, stone_golem.gd,
│   │                 # necromancer.gd, summoned_spirit.gd, poison_toad.gd, enemy_projectile.gd
│   ├── core_system/  # core_pickup.gd
│   ├── dungeon/      # main.gd (Standard Combat Room), ambush_room.gd (Ambush Room)
│   └── ui/           # hud.gd
├── resources/
│   └── power_cores/  # (placeholder)
└── assets/
    ├── enemies/      # fire_mage.png, frost_mage.png  ← 16x16 Aseprite pixel art sprites
    └── audio/        # (placeholder)
```
