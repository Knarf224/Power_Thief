# CLAUDE.md — Power Thief / Milk Chug Studios

> This file is the authoritative guide for AI-assisted work on this project.
> Read it fully at the start of every session before writing any code or making changes.

---

## Project Identity

- **Game:** Power Thief — a top-down dungeon crawler with a power-core theft mechanic
- **Studio:** Milk Chug Studios — indie studio publishing at milkchugstudios.com
- **Engine:** Godot 4.3 (GDScript), web-exported to WASM/HTML5
- **Hosted at:** milkchugstudios.com/games/power-thief (via Astro + Vercel)
- **Backend:** Supabase (PostgreSQL + PostgREST + Auth)
- **Website repo:** `C:\Users\Francisco\milk-chug-studios-website` (separate repo, Astro/Node 20)

---

## File Structure

```
new-game-project/
├── CLAUDE.md                    ← you are here
├── project.godot                ← Godot project config (do not hand-edit)
├── export_presets.cfg           ← Web export config
├── deploy.sh                    ← Post-export pipeline (run after every web export)
├── index.*                      ← Godot web export output files (auto-generated)
│
├── assets/
│   ├── audio/                   ← Music (chiptunes by Juhani Junkala)
│   ├── enemies/                 ← Enemy sprite sheets
│   ├── downloads/               ← Downloaded/imported raw assets
│   │   └── frog_spritesheets/   ← Player character skins + hat overlays
│   └── thumbnail.png            ← Game card thumbnail (source of truth)
│
├── scenes/
│   ├── ui/                      ← HomeScreen, HUD, login, leaderboard, win screen, etc.
│   ├── dungeon/                 ← Room scenes (Standard Combat, Ambush, Hazard, PowerZone)
│   ├── enemies/                 ← Enemy scenes + boss scenes
│   ├── core_system/             ← CorePickup scene
│   └── player/                  ← Player scene + projectile scenes
│
├── scripts/
│   ├── autoload/                ← Godot singletons (loaded at startup)
│   │   ├── game_state.gd        ← Run state, room counter, perks, staging/quick mode
│   │   ├── player_auth.gd       ← ALL Supabase auth + HTTP calls
│   │   ├── tracker.gd           ← Per-run stat accumulation → flush to Supabase
│   │   └── music_manager.gd     ← Background music playback
│   ├── dungeon/                 ← Room logic (main.gd, ambush, hazard, power zone, blackout)
│   ├── enemies/                 ← Enemy scripts (base_enemy.gd + 10 enemy types + 5 bosses)
│   ├── player/                  ← Player controller, dash, fire bomb
│   ├── core_system/             ← Core pickup logic
│   ├── ui/                      ← HUD, home screen, login, leaderboard, perk select, win screen
│   ├── fx/                      ← Visual effects (death burst, gravity push)
│   └── pickups/                 ← Power-up pickup logic
│
├── resources/                   ← Godot .tres / .res resource files
│
└── docs/                        ← Design and ops documentation (read before working on related system)
    ├── backendops.md            ← Supabase schema, auth flow, networking, deployment, QA playbook
    ├── boss.md                  ← Boss stats, perk pools, phase behavior
    ├── enemies.md               ← All enemy stats and properties
    ├── buff.md                  ← Power core and perk system reference
    ├── rooms.md                 ← Room types, enemy scaling, room rotation algorithm
    ├── setbacks.md              ← Setback system (negative modifiers between rooms)
    └── TASKv2.md                ← Phase 2 task list and what was completed in Phase 1
```

> **Rule:** Always read the relevant `docs/` file before touching a system.
> The docs are the ground truth for intended behavior — don't invent rules the docs don't describe.

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Game engine | Godot 4.3 | GDScript only — no C# |
| Web runtime | WASM / HTML5 | Exported via Godot web preset |
| Backend | Supabase | PostgreSQL + PostgREST + Supabase Auth |
| Website | Astro (Node 20) | Static site generator, separate repo |
| Dev proxy | Vite (`astro dev`) | Proxies `/api/supabase` → Supabase in dev only |
| Hosting | Vercel (via git push) | milkchugstudios.com |

---

## Autoloads (Singletons)

These are globally accessible in every GDScript file. Never duplicate their responsibilities.

| Singleton | Responsibility |
|---|---|
| `PlayerAuth` | All Supabase HTTP calls, auth state, session persistence |
| `GameState` | Run state: room counter, health, perks, cores, staging flags |
| `MusicManager` | Background music — play, stop, crossfade |
| `Tracker` | Accumulates per-run kill/death stats; flushes to Supabase on run end |

---

## Fragile Operations — Read Before Touching

Some operations are silently fragile — doing them wrong produces no error, just a broken game or failed deployment. These are non-negotiable stops.

> **STOP — After every Godot web export:**
> Run `bash deploy.sh` immediately. The Godot exporter sets `ensureCrossOriginIsolationHeaders: true` in `index.html`, which **blocks all Supabase calls silently**. The script flips it to `false`. Skipping this produces a game that appears to load but fails all networking with no obvious error message.

> **STOP — Before every commit:**
> Check that `staging_mode = false` and `quick_mode = false` in `game_state.gd`. Committing with staging on means the live game spawns 1 enemy per room and loops the same scene forever — and it will not be obvious why until someone looks at the code.

> **STOP — Before debugging any 401 or "No connection" error:**
> Delete `session.cfg` at `C:\Users\Francisco\AppData\Roaming\Godot\app_userdata\[game]\session.cfg` and log in fresh first. Tokens expire after ~1 hour. The majority of auth issues are expired tokens, not code bugs. Do not touch code until you have confirmed it is not a token issue.

> **STOP — Before pushing to Vercel:**
> Test the full smoke test at `localhost:4321/games/power-thief` first. The Vite dev proxy (`/api/supabase`) does not exist in the production build. If something works locally but breaks in production, the proxy is the most likely reason.

---

## GDScript Conventions

- Use `snake_case` for variables and functions, `PascalCase` for class names and scene files
- Prefer signals over direct function calls for cross-node communication
- Always extend `Node` for autoloads; extend the appropriate Godot class for scene nodes
- Group constants at the top of each script with `const`, then `@export` vars, then regular vars
- Comment sections with `# ── SECTION NAME ──────────` style headers (already established in codebase)
- Never use `get_node()` paths when `$NodeName` shorthand works
- Avoid `await` chains longer than 2 deep — break into functions
- All enemy scripts extend `base_enemy.gd` — do not duplicate base behavior
- All boss scripts extend `boss_base.gd`

### Naming conventions for scenes and scripts

| Type | Scene file | Script file |
|---|---|---|
| Enemy | `PascalCase.tscn` | `snake_case.gd` |
| Room | `PascalCaseRoom.tscn` | `snake_case_room.gd` |
| Boss | `BossName.tscn` | `boss_name.gd` |
| UI | `ScreenName.tscn` or `ComponentName.tscn` | `screen_name.gd` |
| Autoload | N/A | `snake_case.gd` |

---

## Supabase / Backend Rules

> See `docs/backendops.md` for full detail. These are the non-negotiables.

1. **Never weaken RLS.** All tables have Row Level Security. Never add open `USING (true)` policies.
2. **Never commit the `service_role` key.** Only the anon JWT key (`eyJ...`) belongs in client code.
3. **All tracker writes go through `upsert_tracker()` RPC** — never POST directly to the `tracker` table.
4. **All HTTP calls route through `PlayerAuth`** — `supabase_rpc()`, `rest_get()`, `rest_post()`. Don't add new `HTTPRequest` nodes elsewhere.
5. **After every Godot web export:** run `bash deploy.sh` — it flips `ensureCrossOriginIsolationHeaders` to `false` and copies files to the website repo. Never skip this.
6. **The Vite proxy is dev-only.** Production Supabase calls must go through a server-side route or be confirmed CORS-free from the production domain.
7. **Schema changes:** add to `docs/db_migration_v1.sql` and apply via Supabase SQL editor. Dashboard-only changes will be lost.

### Auth pattern (fake email)
Username-based auth uses the pattern `username.lower() + "@powerthief.invalid"` as the Supabase email. This is intentional — do not change.

### Token expiry
Tokens expire after ~1 hour. The game does NOT auto-refresh. Before debugging 401 errors, always delete `session.cfg` at:
`C:\Users\Francisco\AppData\Roaming\Godot\app_userdata\[game]\session.cfg`

---

## Development Workflow

### Testing order — ALWAYS smallest scope first

| What changed | Test method | Command |
|---|---|---|
| Game logic (AI, damage, movement) | Godot editor | F5 (full game) or F6 (current scene) |
| Specific room/enemy in isolation | Staging mode | Set `staging_mode = true` in `game_state.gd`, then F6 |
| Web rendering / UI layout | Local Astro dev | `bash deploy.sh` → `npm run dev` → localhost:4321 |
| Networking (tracker, leaderboard) | Local Astro dev | Same as above — Vite proxy handles Supabase |
| Everything confirmed working | Push to Vercel | `git push` in the **website repo** |

**Never push to Vercel just to test.** Anything testable at localhost must be tested there first.

For staging mode details see `docs/staging.md`. For the full export → deploy → push pipeline use the **godot-deploy** skill.

---

## Testing Philosophy

> Adapted from proven frontend testing practice — applied to the Godot/web context.

### Core principle
Test the contract, not the implementation. Assert outcomes a player would notice — enemy dies, score updates, room transitions, tracker submits — rather than internal state that could change without breaking anything visible.

### Test layer decision tree — always start at the smallest scope

| Scope | How | When to use |
|---|---|---|
| Game logic (damage, AI, movement) | Godot editor (F5 / F6) | Any logic change |
| Room or enemy in isolation | Staging mode + F6 | New enemy, room type, or mechanic |
| UI layout and web rendering | `localhost:4321` after `deploy.sh` | Any UI or export change |
| Networking (tracker, leaderboard) | `localhost:4321` with `npm run dev` | Any backend or HTTP change |
| Full integration confirmed | Push to Vercel | Only after all scopes above pass |

### Minimum smoke test — run this before every Vercel push
1. Game loads at `localhost:4321/games/power-thief` with zero red errors in the browser console
2. `[relay] iframe fetch patched` appears in the console (confirms Supabase proxy is active)
3. Login flow completes and username is displayed correctly
4. A full room clears and the tracker submits without a network error in the console

### Debug order when something breaks
Work through in this exact order — stop when you find the cause:
1. **Browser console (F12)** — read every red error before touching any code
2. **Network tab** — confirm whether the request reached Supabase and what status code it returned
3. **Visual check** — note the exact broken state so you can describe it precisely
4. **Flags check** — verify `staging_mode`, token freshness (`session.cfg`), and `ensureCrossOriginIsolationHeaders` in `index.html`

### Anti-patterns to avoid
- Pushing to Vercel to test something — always test locally first
- Debugging 401 errors before checking the token — delete `session.cfg` and log in fresh first
- Hardcoding enemy counts or pool overrides and forgetting to revert — use staging flags, not code edits
- Assuming the COEP flag is flipped — always open `index.html` and confirm `ensureCrossOriginIsolationHeaders: false` after an export

---

## QA Checklist

Before any commit touching gameplay or backend, verify:

- [ ] `staging_mode = false` in `game_state.gd`
- [ ] `quick_mode = false` in `game_state.gd`
- [ ] Any temporary enemy pool overrides reverted
- [ ] Any hardcoded spawn counts reverted to `GameState.get_enemy_count(N)`
- [ ] Game runs in Godot editor without errors (F5)
- [ ] If backend-related: test at localhost:4321 with `npm run dev` running
- [ ] Browser console has no red errors at localhost:4321/games/power-thief
- [ ] `[relay] iframe fetch patched` appears in console (confirms Supabase proxy is active)

For common errors and fixes see `docs/backendops.md → QA Troubleshooting Playbook` or the **godot-deploy** skill's troubleshooting reference.

---

## Game Systems Quick Reference

### Power Cores (10 total)
Dash, Fire, Split, Phase, Explosion, Ice, Lightning, Shield, Summon, Poison.
Each enemy drops a specific core type. Player holds 3 slots. See `docs/cores.md`.

### Enemies (10 types)
Fire Mage, Rogue Assassin, Slime (splits), Ghost (phase-only), Bomb Beetle (self-destructs), Ice Witch, Lightning Sprite, Stone Golem (shield), Necromancer (summons spirits), Poison Toad.
All extend `base_enemy.gd`. See `docs/enemies.md` for all stats.

### Bosses (5 types — shuffle-bag order)
The Warden, The Lich, The Phantom, The Plague Lord, The Storm Tyrant.
Appear every 4th room (rooms 4, 8, 12, 16, 20). All extend `boss_base.gd`. See `docs/boss.md`.

### Room types
Standard Combat, Ambush, Hazard Floor, Power Zone (+ Blackout overlay from level 4).
Room rotation is deterministic with shuffle-bag and streak protection. See `docs/rooms.md`.

### Enemy scaling formula
`min(2 + room_counter * 2, 24)` — caps at 24 enemies at room 12.

---

## Adding a New Enemy

Use the **godot-add-enemy** skill — it walks through all 7 required steps in order.
Quick summary: script → scene → sprite → tracker key → room pool → `docs/enemies.md` → Supabase column.

## Adding a New Boss — Checklist

1. Create script in `scripts/enemies/bosses/` extending `boss_base.gd`
2. Create scene in `scenes/enemies/bosses/`
3. Define perk drop pool in `docs/boss.md` and implement in script
4. Add to boss shuffle-bag in `scripts/dungeon/main.gd`
5. Add full stat block to `docs/boss.md`

## Adding a New Power Core — Checklist

1. Add core ID and color to `scripts/core_system/core_pickup.gd` `CORE_COLORS` dict
2. Implement core effect in `scripts/player/player.gd`
3. Assign core to the appropriate enemy drop in that enemy's script
4. Document in `docs/cores.md`

---

## Skills Available (AI Agent Capabilities)

The following skills are installed and available in this project. Use them proactively.

| Skill | When to use |
|---|---|
| **godot-deploy** | Exporting from Godot, running deploy.sh, testing locally, pushing to Vercel, debugging deploy failures |
| **godot-add-enemy** | Creating a new enemy — script, scene, sprite, tracker key, room pool, docs, Supabase column |
| **godot-add-boss** | Creating a new boss — script, scene, support scenes, shuffle-bag, tracker key, docs/boss.md stat block |
| **godot-add-core** | Adding a new Power Core — ID, color, player effect, enemy drop assignment, docs/cores.md |
| **godot-game-feel** | Adding game feel / juice — screen shake, hit flash, hit stop, particles, scale punch, audio timing |
| **supabase-schema** | Safe database migrations — add column, new table, RPC function, RLS policy; writes to db_migration_v1.sql |
| **milkchug-release** | Publishing to milkchugstudios.com — website content updates, favicon fix, site audit, Vercel deploy |
| **milkchug-security** | Security audits — leaderboard integrity, RLS review, API key hygiene, CSP headers |
| **xlsx** | Game balance spreadsheets, enemy stat comparisons, tracker analytics, bug tracking grids |
| **docx** | Design docs, changelogs, press releases, game jam submissions, milestone reports |
| **pptx** | Studio pitch decks, game jam presentations, publisher meetings |
| **pdf** | Press kits, player guides, export/print documentation |
| **schedule** | Automated QA reminders, deploy checklists, recurring tasks (e.g. weekly leaderboard snapshots) |
| **skill-creator** | Build new custom skills for project-specific workflows |

---

## Key External Links

| Resource | URL |
|---|---|
| Live game | https://milkchugstudios.com/games/power-thief |
| Supabase dashboard | https://supabase.com → project `sbwmznwbfjcnnmgqvifv` |
| Supabase SQL editor | Dashboard → SQL Editor → New query |
| Website repo local path | `C:\Users\Francisco\milk-chug-studios-website` |

---

## Rules — Non-Negotiable

1. Read the relevant `docs/` file before touching any major system.
2. Test in Godot editor before exporting to web. Test locally before pushing to Vercel.
3. Always run `bash deploy.sh` after a Godot web export — never skip it.
4. Never commit with `staging_mode = true`.
5. Never weaken Supabase RLS or commit the `service_role` key.
6. Keep `docs/` files in sync with actual code — update stats and rules as you change them.
7. Suggest improvements and ask questions — the goal is a polished, shippable game on milkchugstudios.com.
