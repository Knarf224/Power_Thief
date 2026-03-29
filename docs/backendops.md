# BackendOps — Power Thief / Milk Chug Studios

> Reference for all backend, database, API, and deployment work.
> Invoke this whenever touching Supabase, player_auth.gd, tracker.gd,
> web export networking, or the Astro website's data layer.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Game engine | Godot 4.3 (GDScript) |
| Web export runtime | Godot HTML5 / WASM |
| Backend / database | Supabase (PostgreSQL + PostgREST + Auth) |
| Website | Astro (static site, Node 20) |
| Dev server proxy | Vite (`astro dev`) |
| Hosting | milkchugstudios.com |
| Studio | Milk Chug Studios |

---

## Supabase Project

- **Project URL:** `https://sbwmznwbfjcnnmgqvifv.supabase.co`
- **Anon key (JWT):** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNid216bndiZmpjbm5tZ3F2aWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwMDQ2OTYsImV4cCI6MjA4ODU4MDY5Nn0.EqErGaIauFjyat08c59QAz7m3ZIMTnIHtRu-8rZMpr0`
- **Note:** Use the JWT key (`eyJ...`) for all direct REST API calls. The `sb_publishable_` key is only accepted by the Supabase JS client, not PostgREST.
- **Dashboard:** https://supabase.com → project `sbwmznwbfjcnnmgqvifv`
- **SQL Editor:** Dashboard → SQL Editor → New query
- **Migration file:** `docs/db_migration_v1.sql`

> The anon key is safe to ship in client code. It is restricted by RLS policies.
> Never commit the `service_role` secret key anywhere.

---

## Database Schema

### `public.profiles`
One row per registered player. Auto-created by the `handle_new_user` trigger on Supabase Auth signup.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | Mirrors `auth.users.id` |
| `username` | TEXT UNIQUE | Player-facing identity |
| `email` | TEXT nullable | Optional real email |
| `created_at` | TIMESTAMPTZ | |

### `public.tracker`
One row per player. Cumulative lifetime stats across all runs. Written via `upsert_tracker()` RPC only.

| Column | Type | Notes |
|---|---|---|
| `user_id` | UUID PK | FK → `profiles.id` |
| `runs_attempted` | INT | |
| `deaths` | INT | |
| `wins` | INT | Cleared room 20 boss |
| `kills_*` | INT ×15 | Per-enemy columns (see schema) |
| `total_kills` | INT | |
| `updated_at` | TIMESTAMPTZ | |

### `public.high_scores`
One row per submitted run. Public leaderboard — ordered by `highest_room DESC`.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | Auto-generated |
| `user_id` | UUID nullable | FK → `profiles.id` |
| `display_name` | TEXT | Snapshot of username at run time |
| `highest_room` | INT | |
| `cores` | TEXT[] | e.g. `['Fire','Dash','Ice']` |
| `achieved_at` | TIMESTAMPTZ | |

### `public.game_stats`
Single-row table for global play count (id = 1 always).

---

## Row Level Security Policies

| Table | Operation | Policy |
|---|---|---|
| `profiles` | SELECT | Public — anyone can read |
| `profiles` | INSERT/UPDATE | Owner only (`auth.uid() = id`) |
| `tracker` | SELECT/INSERT/UPDATE | Owner only (`auth.uid() = user_id`) |
| `high_scores` | SELECT | Public — anyone can read |
| `high_scores` | INSERT | Authenticated only (`auth.uid() = user_id`) |
| `game_stats` | SELECT | Public |
| `game_stats` | UPDATE | Blocked — use `increment_play_count()` RPC only |

> **Never add `allow read, write: if true` policies.** Every table has RLS enabled.

---

## RPC Functions

### `increment_play_count()`
- **Caller:** All players including guests, called at run start
- **Auth required:** No (granted to `anon` and `authenticated`)
- **Called from:** `tracker.gd → on_run_started()`
- **Effect:** Increments `game_stats.total_plays` by 1

### `upsert_tracker(p_user_id UUID, p_runs_delta INT, ...)`
- **Caller:** Logged-in players only, called at run end
- **Auth required:** Yes — function enforces `auth.uid() = p_user_id`
- **Called from:** `tracker.gd → _flush_tracker()`
- **Effect:** INSERT or cumulative UPDATE on `tracker` row

> Always call via `PlayerAuth.supabase_rpc()`, never raw REST POST to the table directly.

---

## Auth Architecture

### How registration works
1. Godot constructs a fake email: `username.to_lower() + "@powerthief.invalid"`
2. POST to `/auth/v1/signup` with `email`, `password`, and `data.username` in metadata
3. Supabase Auth creates the user; `handle_new_user` trigger auto-inserts a `profiles` row
4. If response contains `access_token`, session is applied immediately

### How login works
1. POST to `/auth/v1/token?grant_type=password` with fake email + password
2. Response contains `access_token`, `refresh_token`, `user.id`, `user.user_metadata.username`
3. Session saved to `user://session.cfg` via ConfigFile

### Session persistence
- Stored at: `user://session.cfg` (Windows: `%APPDATA%\Godot\app_userdata\[game]\session.cfg`)
- Fields saved: `access_token`, `refresh_token`, `user_id`, `username`
- **Tokens expire after ~1 hour.** Expired tokens cause 401 on authenticated endpoints.
- To clear: delete `session.cfg`, or press Logout in-game

### Token expiry handling
Currently the game does NOT auto-refresh tokens. If a player has an old saved session:
- `tracker` and `high_scores` INSERT calls will return **401**
- Fix: log out and back in to get a fresh token
- Future work: call `/auth/v1/token?grant_type=refresh_token` on startup

---

## Godot Networking Layer

### File: `scripts/autoload/player_auth.gd`

All Supabase HTTP calls go through this singleton. Key methods:

| Method | Description |
|---|---|
| `register(username, password, real_email)` | Creates Supabase Auth account |
| `login(username, password)` | Gets access token |
| `logout()` | Posts logout, clears session |
| `supabase_rpc(fn_name, params, callback)` | Calls an RPC function |
| `rest_get(path_and_query, callback)` | Authenticated GET to REST API |
| `rest_post(table, body, callback)` | Authenticated POST to REST API |

### Request routing: Desktop vs Web

```
_make_request()
  ├── OS.get_name() == "Web"  →  _web_fetch()   (JavaScriptBridge + polling)
  └── otherwise               →  _native_request()  (HTTPRequest node)
```

### Web export networking — important notes

The game runs inside an `<iframe>` on the Astro website. There are two potential blockers for HTTP requests in this context:

**1. COEP service worker (Godot export flag)**
Every Godot web export sets `"ensureCrossOriginIsolationHeaders": true` in `index.html`. This installs a service worker that adds `Cross-Origin-Embedder-Policy: require-corp` headers, which blocks ALL cross-origin fetches (including to Supabase).

**Fix:** The `deploy.sh` script handles this automatically. If fixing manually, open `public/play/power-thief/index.html` and change:
```js
"ensureCrossOriginIsolationHeaders": false
```
The unregister script in `<body>` also clears any previously installed service worker on next page load.

**2. CORS (browser policy)**
Direct requests from `localhost:4321` (or the production domain) to `supabase.co` are subject to CORS. Supabase allows these requests with the anon key, but COEP blocks them first (see above).

**The iframe fetch override (in `[slug].astro`)** intercepts `fetch()` calls inside the iframe that target `supabase.co` and reroutes them through the Vite proxy (`/api/supabase`), which is same-origin and CORS-free.

### Vite proxy (dev only)

Configured in `astro.config.mjs`:
```
/api/supabase  →  https://sbwmznwbfjcnnmgqvifv.supabase.co
```
This proxy only works in `astro dev`. Production deployments need a server-side route or edge function to provide the same path (or direct Supabase calls if CORS is not blocked in production).

---

## File Map — What Does What

| File | Role |
|---|---|
| `scripts/autoload/player_auth.gd` | Supabase Auth + all HTTP calls |
| `scripts/autoload/tracker.gd` | Per-run stat accumulation + flush to Supabase |
| `docs/db_migration_v1.sql` | Full Supabase schema — tables, RLS, triggers, RPCs |
| `astro.config.mjs` | Vite proxy config for `/api/supabase` |
| `.env` | `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY` |
| `src/lib/supabase.js` | Supabase JS client (used by Astro pages) |
| `src/pages/games/[slug].astro` | Game embed page + iframe fetch relay |
| `src/pages/games/power-thief/leaderboard.astro` | Public leaderboard page |
| `public/play/power-thief/index.html` | Godot web export HTML (COEP flag flipped by `deploy.sh`) |

---

## Deployment Workflow

### Testing Strategy — avoid unnecessary Vercel deploys

**Rule: test the smallest scope first. Only escalate when the current scope passes.**

| What changed | Test scope | How |
|---|---|---|
| Game logic (movement, damage, AI) | Godot editor | Press F5 in Godot — instant, no export |
| Web rendering (fonts, UI layout) | Local astro dev | Export → `bash deploy.sh` → `npm run dev` → localhost:4321 |
| Networking (tracker, leaderboard) | Local astro dev | Same as above — Vite proxy handles Supabase |
| Everything confirmed working | Push to Vercel | `git push` in website repo |

**Never push to Vercel just to test.** Anything testable at localhost should be tested there first.

### Local development
```bash
# Run website dev server (includes Vite proxy for Supabase)
cd C:\Users\Francisco\milk-chug-studios-website
npm run dev
# → http://localhost:4321/games/power-thief
```

### Godot web export + deploy (automated)
1. In Godot: Project → Export → Web → Export Project → destination: `./index.html` (game project root)
2. In bash (from game project root):
   ```bash
   bash deploy.sh
   ```
   This script automatically:
   - Sets `ensureCrossOriginIsolationHeaders` to `false`
   - Injects the SW unregister script into `<body>` (if missing)
   - Restores `assets/thumbnail.png` → `index.png`
   - Copies all `index.*` files to `public/play/power-thief/`
3. Test at `http://localhost:4321/games/power-thief` (with `npm run dev` running)
4. When confirmed working locally → commit and push the website repo

### Website deploy to production (milkchugstudios.com)
```bash
npm run build   # generates dist/
# Deploy dist/ to hosting provider
```
> Note: Vite proxy (`/api/supabase`) does NOT exist in production builds.
> Before going live, either: (a) add a server-side API route that proxies Supabase,
> or (b) confirm direct Supabase calls work from the production domain (likely fine once COEP is off).

---

## QA Troubleshooting Playbook

### Step 0 — Before anything else
Open the browser console (F12 → Console) on the game page at `localhost:4321/games/power-thief`.
Read every red error. The error text tells you which layer is failing.

---

### Issue: "No connection" in-game (tracker or leaderboard)

**Checklist — work through in order:**

1. **Is `ensureCrossOriginIsolationHeaders` false?**
   Open `public/games/power-thief/index.html`. Search for `ensureCrossOriginIsolationHeaders`.
   If `true` → set to `false` and hard-refresh the browser (Ctrl+Shift+R).

2. **Is there a CORS error in the console?**
   Look for: `has been blocked by CORS policy`
   Cause: service worker still active from a previous export with COEP flag on.
   Fix: Hard-refresh (Ctrl+Shift+R) once to let the unregister script run, then reload again.

3. **Is the Astro dev server running?**
   The game must be accessed at `localhost:4321/games/power-thief` — NOT by opening `index.html` directly.
   If accessed directly, the Vite proxy and iframe relay do not exist.

4. **Do you see `[relay] iframe fetch patched` in the console?**
   If no → the `load` event on the iframe didn't fire. Try a hard refresh.
   If yes → the fetch override is active. Proceed to step 5.

5. **Is the request reaching Supabase?**
   Look for a network request to `supabase.co` or `/api/supabase` in the Network tab.
   If no request appears at all → the game code change wasn't exported. Re-export.

---

### Issue: 401 Unauthorized on tracker or high_scores

**Cause:** Expired `access_token` in saved session.
Tokens expire after ~1 hour. The game restores the old token from `session.cfg` on startup.

**Fix:**
1. In the game, log out (if logout button is accessible)
2. OR delete `session.cfg` at:
   `C:\Users\Francisco\AppData\Roaming\Godot\app_userdata\[game folder]\session.cfg`
3. Log in fresh — this gets a new valid token
4. Retry the failing operation

**If 401 persists after fresh login:**
The API key (`sb_publishable_`) may not be accepted by PostgREST for this call type.
Fix: Get the legacy JWT anon key from Supabase → Settings → API → Legacy keys (starts with `eyJ...`).
Update `SUPABASE_ANON_KEY` in `player_auth.gd`, re-export, and update `.env`.

---

### Issue: "parse JSON failed at line 0" in console

**Cause:** A Supabase response came back with an empty body and the game tried to parse it as JSON.

**Most likely trigger:** An HTTP call is firing with no body (empty `PackedByteArray`) getting treated as a successful 200 response.

**Fix:**
1. Check which function is parsing — add `print(body_bytes.get_string_from_utf8())` before the `JSON.parse_string()` call to see the raw response.
2. If this appeared after adding a new HTTP call on startup (like token refresh), ensure the call only fires when there is a valid token (`if not refresh_token.is_empty()`).
3. Check that the Vite proxy is running (`astro dev` is active) — if the proxy returns an HTML 404 page, JSON parse will fail at a specific line, not line 0.

---

### Issue: 422 or PGRST error on RPC calls

**Common PGRST errors:**

| Code | Message | Fix |
|---|---|---|
| PGRST205 | Cannot find table in schema cache | Run `NOTIFY pgrst, 'reload schema';` in Supabase SQL editor, or reload the API from Dashboard → Settings → API |
| PGRST301 | JWT expired | Log out and log back in |
| 42501 | permission denied | Check RLS policy; run `GRANT USAGE ON SCHEMA public TO anon, authenticated;` |
| 42P01 | relation does not exist | Table wasn't created; re-run `docs/db_migration_v1.sql` |

---

### Issue: Leaderboard on website shows no data or errors

1. Check `.env` — `PUBLIC_SUPABASE_URL` must be `https://sbwmznwbfjcnnmgqvifv.supabase.co`
2. Confirm `high_scores` table exists and has a public SELECT policy
3. Open browser console on the leaderboard page — look for `PGRST` errors in network responses
4. Test directly in Supabase SQL: `SELECT * FROM high_scores ORDER BY highest_room DESC LIMIT 5;`

---

### Issue: Registration succeeds but username doesn't appear

The `handle_new_user` trigger auto-inserts into `profiles`. If this fails:
1. Check Supabase Dashboard → Database → Triggers — confirm `on_auth_user_created` exists
2. Run `SELECT * FROM profiles;` to see if the row was inserted
3. If trigger is missing, re-run the trigger section of `docs/db_migration_v1.sql`

---

## Security Headers (vercel.json — website repo)

The following headers must be set in the **website repo's `vercel.json`** to prevent iframe embedding attacks and future XSS damage. Add or merge into the `headers` array:

```json
{
  "headers": [
    {
      "source": "/games/:path*",
      "headers": [
        { "key": "X-Frame-Options", "value": "SAMEORIGIN" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    },
    {
      "source": "/play/:path*",
      "headers": [
        { "key": "X-Frame-Options", "value": "SAMEORIGIN" },
        { "key": "X-Content-Type-Options", "value": "nosniff" }
      ]
    }
  ]
}
```

> **Why SAMEORIGIN and not DENY?** The game at `/play/power-thief/index.html` must be embeddable by the parent page at `/games/power-thief` — both are on `www.milkchugstudios.com`, which SAMEORIGIN allows. DENY would break the embed.

> **Why no CSP yet?** A full CSP for a Godot WASM game requires `unsafe-eval` and `wasm-unsafe-eval` in `script-src`, plus blob: and data: URIs. Adding a CSP without careful testing tends to break WASM loading. File a follow-up task to tune this once the WASM loading issue is resolved.

---

## Rules

1. **Never weaken RLS.** All four tables have RLS enabled. Do not add open `USING (true)` policies to `tracker` or any write operation.
2. **No service_role key in client code.** Only the anon/publishable key belongs in `player_auth.gd` or `.env`.
3. **All tracker writes go through `upsert_tracker()` RPC.** Never POST directly to the `tracker` table — the RPC enforces ownership.
4. **Re-run `db_migration_v1.sql` to add schema changes.** Keep this file as the single source of truth. Do not alter schema only via the dashboard UI.
5. **After every Godot web export:** flip `ensureCrossOriginIsolationHeaders` to `false` in `index.html`.
6. **Vite proxy is dev-only.** Any production Supabase calls from the website must go through a proper server route, or be direct calls with no CORS blocker.
7. **Test with a fresh session.** Before reporting a backend bug, delete `session.cfg` and log in fresh to rule out expired token issues.
8. **postMessage target origin is locked.** `player_auth.gd` sends postMessages to `'https://www.milkchugstudios.com'` specifically — never change this back to `'*'`, as `'*'` would expose user auth tokens to any site that embeds the game iframe.
