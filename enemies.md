# Power Thief – Entity Properties Reference

Use this file to track and balance all entity stats. Update it whenever values change in code.

---

## Player Baseline
> `scripts/player/player.gd` | `scripts/player/projectile.gd`

| Property          | Value  | Notes                                      |
|-------------------|--------|--------------------------------------------|
| Max Health        | 100    |                                            |
| Move Speed        | 200    |                                            |
| Dash Speed        | 500    | Toward mouse cursor                        |
| Dash Duration     | 0.15s  | How long the dash lasts                    |
| Dash Cooldown     | 0.8s   | Time before dash can be used again         |
| Projectile Damage | 10     | Per shot                                   |
| Projectile Speed  | 500    |                                            |
| Projectile Life   | 2.0s   | Despawns after this if no collision        |
| Core Slots        | 3      | Max equippable power cores                 |

---

## Enemies

### Fire Mage
> `scripts/enemies/fire_mage.gd` | Color: Red

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 40     | Lowest HP — fragile but dangerous at range        |
| Move Speed           | 100     | Inherited from base                               |
| Preferred Distance   | 160px  | Tries to maintain this gap from player            |
| Distance Tolerance   | ±30px  | Starts moving when outside this window            |
| Shoot Cooldown       | 1.0s   | Fires every 1 second                              |
| Projectile Damage    | 20     | Double player shot damage                         |
| Projectile Speed     | 300    | Slower than player projectile                     |
| Projectile Lifetime  | 3.0s   |                                                   |
| Drops                | Fire Core (TODO)                                  |

---

### Rogue Assassin
> `scripts/enemies/assassin.gd` | Color: Purple

| Property         | Value  | Notes                                               |
|------------------|--------|-----------------------------------------------------|
| Max Health       | 50     |                                                     |
| Chase Speed      | 120    | Faster than base enemies                            |
| Dash Speed       | 500    | Dashes at player when in range                      |
| Dash Duration    | 0.18s  |                                                     |
| Dash Range       | 120px  | Triggers dash when player is within this distance   |
| Dash Cooldown    | 1.5s   |                                                     |
| Contact Damage   | 15     | Highest contact damage of all enemies               |
| Contact Cooldown | 0.8s   | Can only deal contact damage once per 0.8s          |
| Drops            | Dash Core (TODO)                                    |

---

### Slime
> `scripts/enemies/slime.gd` | Color: Green

| Property              | Value  | Notes                                          |
|-----------------------|--------|------------------------------------------------|
| Max Health (full)     | 60     | Tankiest basic enemy                           |
| Max Health (mini)     | 30     | Spawned on death of full slime                 |
| Move Speed            | 55     | Slowest enemy                                  |
| Contact Damage        | 8      | Lowest damage — danger is the split mechanic   |
| Contact Cooldown      | 0.6s   |                                                |
| Split on Death        | Yes    | Full slime spawns 2 minis; minis do not split  |
| Drops                 | Split Core (TODO)                               |

---

### Ghost
> `scripts/enemies/ghost.gd` | Color: White

| Property             | Value  | Notes                                                   |
|----------------------|--------|---------------------------------------------------------|
| Max Health           | 30     | Low HP — but only reachable up close                    |
| Move Speed           | 90     | Drifts toward player constantly                         |
| Contact Damage       | 12     |                                                         |
| Contact Cooldown     | 0.8s   |                                                         |
| Vulnerability Range  | 100px  | Only takes damage when player is within this distance   |
| Default State        | Intangible | Immune to all damage outside vulnerability range    |
| Drops                | Phase Core                                              |

---

### Bomb Beetle
> `scripts/enemies/bomb_beetle.gd` | Color: Brown/Orange

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 45     |                                                   |
| Move Speed           | 70     | Slow — danger is the death explosion              |
| Contact Damage       | 10     |                                                   |
| Contact Cooldown     | 0.8s   |                                                   |
| Death Explosion Radius | 80px | AoE on death — punishes close-range kills         |
| Death Explosion Damage | 70   | Applied to player if in range                     |
| Drops                | Explosion Core                                    |

---

### Ice Witch
> `scripts/enemies/ice_witch.gd` | Color: Cyan

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 40     | Fragile but crippling at range                    |
| Move Speed           | 100     |                                                   |
| Preferred Distance   | 180px  | Keeps more distance than Fire Mage                |
| Distance Tolerance   | ±30px  |                                                   |
| Shoot Cooldown       | 1.5s   | Slower fire rate than Fire Mage                   |
| Projectile Damage    | 15     |                                                   |
| Projectile Speed     | 250    | Slow — but applies slow on hit                    |
| Slow Amount          | 50%    | Reduces player speed for 3s on hit                |
| Slow Duration        | 3.0s   |                                                   |
| Drops                | Ice Core                                          |

---

### Lightning Sprite
> `scripts/enemies/lightning_sprite.gd` | Color: Yellow

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 20     | Fragile — kill fast before it cycles              |
| Move Speed           | 150    | Fastest enemy in the game                         |
| Shoot Cooldown       | 0.8s   | Fast fire rate                                    |
| Projectile Damage    | 12     |                                                   |
| Projectile Speed     | 400    |                                                   |
| Chain Range          | 100px  | Projectile chains to nearby enemies on hit        |
| Chain Targets        | 2      | Can jump to 2 additional enemies per shot         |
| Chain Damage         | 8      | Reduced damage per chain jump                     |
| Drops                | Lightning Core                                    |

---

### Stone Golem
> `scripts/enemies/stone_golem.gd` | Color: Gray

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 80     | Tankiest enemy in the game                        |
| Move Speed           | 50     | Second slowest after Slime                        |
| Contact Damage       | 25     | Highest single-hit damage of all enemies          |
| Contact Cooldown     | 1.2s   |                                                   |
| Shield Hits          | 1      | Absorbs one hit before damage reaches HP          |
| Shield Recharge Time | 8.0s   | Shield regenerates after this delay               |
| Drops                | Shield Core                                       |

---

### Necromancer
> `scripts/enemies/necromancer.gd` | Color: Dark Purple

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 35     | Priority target — disabling summons is key        |
| Move Speed           | 90     |                                                   |
| Shoot Cooldown       | 2.0s   | Infrequent shots — threat is summoning            |
| Projectile Damage    | 15     |                                                   |
| Summon Cooldown      | 4.0s   | Calls a Summoned Spirit every 4 seconds           |
| Max Summoned         | 3      | Will not summon if 3 spirits already active       |
| Drops                | Summon Core                                       |

#### Summoned Spirit *(spawned by Necromancer)*
> No script file — spawned inline by Necromancer | Color: Pale Purple

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 10     | Dies in 1 player shot                             |
| Move Speed           | 110    | Faster than Necromancer — rushes player           |
| Contact Damage       | 15     | Dangerous in groups — Necromancer can stack 3     |
| Contact Cooldown     | 0.8s   |                                                   |
| Drops                | Nothing — no core, no pickup                      |

---

### Poison Toad
> `scripts/enemies/poison_toad.gd` | Color: Yellow-Green

| Property             | Value  | Notes                                             |
|----------------------|--------|---------------------------------------------------|
| Max Health           | 50     |                                                   |
| Move Speed           | 60     | Slow — relies on DoT to punish the player         |
| Preferred Distance   | 120px  |                                                   |
| Distance Tolerance   | ±25px  |                                                   |
| Shoot Cooldown       | 1.2s   |                                                   |
| Projectile Damage    | 5      | Low direct damage — threat is poison              |
| Poison Damage/Tick   | 5      | Damage per tick while poisoned                    |
| Poison Tick Rate     | 0.5s   |                                                   |
| Poison Duration      | 3.0s   | Total poison = 30 damage over 3 seconds           |
| Drops                | Poison Core                                       |

---

## Damage Reference

| Source                                      | Damage              | Cooldown        |
|---------------------------------------------|---------------------|-----------------|
| Player Projectile                           | 10                  | Click speed     |
| Fire Mage Projectile                        | 20                  | 1.0s per shot   |
| Assassin Contact                            | 15                  | 0.8s            |
| Slime Contact (full)                        | 8                   | 0.6s            |
| Slime Contact (mini)                        | 8                   | 0.6s            |
| Ghost Contact                   | 12                  | 0.8s            |
| Bomb Beetle Contact             | 10                  | 0.8s            |
| Bomb Beetle Death Explosion     | 70                  | Once (on death) |
| Ice Witch Projectile            | 15 + 50% slow (3s)  | 1.5s per shot   |
| Lightning Sprite Projectile     | 12 (8 per chain)    | 0.8s per shot   |
| Stone Golem Contact             | 25                  | 1.2s            |
| Necromancer Projectile          | 15                  | 2.0s per shot   |
| Summoned Spirit Contact         | 15                  | 0.8s            |
| Poison Toad Projectile          | 5 + 30 poison DoT   | 1.2s per shot   |

---

## Hits to Kill Reference
> Based on player projectile damage of 10

| Enemy                              | HP  | Shots to Kill                           |
|------------------------------------|-----|-----------------------------------------|
| Fire Mage                          | 40  | 4                                       |
| Assassin                           | 50  | 5                                       |
| Slime (full)                       | 60  | 6 (then splits)                         |
| Slime (mini)                       | 30  | 3                                       |
| Ghost                  | 30  | 3 (only hittable within 100px)          |
| Bomb Beetle            | 45  | 5 (death explosion 70 dmg — keep range) |
| Ice Witch              | 40  | 4                                       |
| Lightning Sprite       | 20  | 2                                       |
| Stone Golem            | 80  | 9 (first shot hits shield)              |
| Necromancer            | 35  | 4                                       |
| Summoned Spirit        | 10  | 1                                       |
| Poison Toad            | 50  | 5                                       |

---

## Power Cores

### Dash Core
> Dropped by: Rogue Assassin | Color: Purple star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Passive | Always active while equipped                      |
| Effect           | Doubles dash speed and duration                    |
| Dash Speed       | 500 → 1000 | Applied multiplicatively                    |
| Dash Duration    | 0.15s → 0.30s | Applied multiplicatively                 |
| Slot Type        | Passive — no keybind required                      |

---

### Fire Core
> Dropped by: Fire Mage | Color: Orange star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Slot key (1/2/3) | Whichever slot the core occupies             |
| Effect           | Drops a fire bomb at player's feet                 |
| Fuse Time        | 1.5s   | Delay before explosion                             |
| Explosion Radius | 80px   | AoE around bomb position                           |
| Damage           | 40     | Applied to all enemies within radius               |
| Cooldown         | 3.0s   | Cannot be spammed                                  |
| Slot Type        | Active — press the key for its slot                |

---

### Split Core
> Dropped by: Slime (last mini) | Color: Green star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Passive | Modifies every shot automatically                 |
| Effect           | Fires 2 projectiles per click in a V shape         |
| Spread Angle     | ±15°   | Each projectile offset from mouse direction        |
| Damage per shot  | 10     | Same as base projectile — double total if both hit |
| Slot Type        | Passive — no keybind required                      |

---

### Phase Core
> Dropped by: Ghost | Color: White star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Slot key (1/2/3) | Whichever slot the core occupies             |
| Effect           | Player becomes intangible — takes no damage        |
| Duration         | 1.5s   | Length of intangibility window                     |
| Cooldown         | 8.0s   |                                                    |
| Slot Type        | Active — press the key for its slot                |

---

### Explosion Core
> Dropped by: Bomb Beetle | Color: Brown/Orange star

| Property          | Value  | Notes                                             |
|-------------------|--------|---------------------------------------------------|
| Activation        | Passive | Triggers automatically on every dash             |
| Effect            | Leaves an explosion at dash start position         |
| Explosion Radius  | 80px   | Same radius as Fire Core bomb                     |
| Explosion Damage  | 25     | Slightly less than Fire Core                      |
| Slot Type         | Passive — no keybind required                     |

---

### Ice Core
> Dropped by: Ice Witch | Color: Cyan star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Passive | Modifies every shot automatically                 |
| Effect           | Player shots apply a slow to enemies on hit        |
| Slow Amount      | 40%    | Reduces enemy move speed by 40%                    |
| Slow Duration    | 2.0s   |                                                    |
| Damage           | 10     | Same as base — slow is the bonus                   |
| Slot Type        | Passive — no keybind required                      |

---

### Lightning Core
> Dropped by: Lightning Sprite | Color: Yellow star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Passive | Modifies every shot automatically                 |
| Effect           | Shots chain to nearby enemies on hit               |
| Chain Range      | 120px  | Jump radius from hit enemy                         |
| Chain Targets    | 2      | Max additional enemies hit per shot                |
| Chain Damage     | 8      | Reduced from base 10 per jump                      |
| Slot Type        | Passive — no keybind required                      |

---

### Shield Core
> Dropped by: Stone Golem | Color: Gray star

| Property           | Value  | Notes                                            |
|--------------------|--------|--------------------------------------------------|
| Activation         | Passive | Always active while equipped                    |
| Effect             | Absorbs one hit completely; recharges over time  |
| Shield Hits        | 1      | Nullifies one hit regardless of damage           |
| Recharge Time      | 10.0s  | After absorbing a hit, shield returns after 10s  |
| Slot Type          | Passive — no keybind required                    |

---

### Summon Core
> Dropped by: Necromancer | Color: Dark Purple star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Slot key (1/2/3) | Whichever slot the core occupies             |
| Effect           | Summons a ghost ally that attacks nearby enemies   |
| Ally Duration    | 8.0s   | Ghost disappears after this time                   |
| Ally Damage      | 8      | Per attack                                         |
| Ally Attack Rate | 1.0s   |                                                    |
| Cooldown         | 15.0s  |                                                    |
| Slot Type        | Active — press the key for its slot                |

---

### Poison Core
> Dropped by: Poison Toad | Color: Yellow-Green star

| Property         | Value  | Notes                                              |
|------------------|--------|----------------------------------------------------|
| Activation       | Passive | Modifies every shot automatically                 |
| Effect           | Player shots apply poison DoT to enemies on hit    |
| Poison Damage    | 5/tick | Damage per tick                                    |
| Tick Rate        | 0.5s   |                                                    |
| Poison Duration  | 3.0s   | Total: 30 poison damage per hit                    |
| Direct Damage    | 10     | Base projectile damage unchanged                   |
| Slot Type        | Passive — no keybind required                      |

---

## Core Rules
- Players start with **3 slots**
- Cores drop **dimmed and inactive** until all enemies in the room are cleared
- Only **one core can be looted per room** — the other disappears on pickup
- If all 3 slots are full, picking up a new core **replaces slot 0**

---

## Notes for Balancing
- Player has **10x** the HP of a Fire Mage — currently very tanky relative to enemies
- Assassin deals the most burst damage through its dash + contact combo
- Slime is the most resource-intensive to kill (6 shots + 2x 3 shots = 12 total shots for full clear)
- Fire Mage projectile speed (300) is faster now — dodging requires more active movement
- **Stone Golem** is the tankiest enemy (80 HP + absorbs first hit) — 9 shots minimum, use crowd control cores
- **Lightning Sprite** is the most fragile (20 HP, 2 shots) but fastest — hardest to hit
- **Poison Toad** deals 35 total damage per hit (5 direct + 30 DoT) — highest sustained damage in the roster
- **Ghost** is always immune until you close the gap to 100px — forces risky melee range; dash cores help
- **Necromancer** should be prioritized: summons every 4s up to 3 spirits, each doing 15 contact damage — can snowball quickly
- **Summoned Spirit** dies in 1 shot but must be cleared quickly; 3 active at once = 45 potential contact damage
- **Bomb Beetle** death explosion now hits for 70 damage — nearly lethal in one blast, always kill from range
- Active cores (slot keys 1/2/3): Fire Core, Phase Core, Summon Core — each responds to the key of whichever slot it occupies, so multiple actives can coexist
