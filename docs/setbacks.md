# Session Setbacks — 2026-03-22

This document is a full, honest account of everything attempted, broken, fixed, and left broken
during the March 22 session. Use it tomorrow to retrace steps, identify root causes, and avoid
repeating the same mistakes.

---

## Starting Condition (What Was Working Before This Session)

Before the session began the following was confirmed working:

- Game exported and playable on the website (rooms showed, enemies spawned)
- Core pickup UI rendered (buttons visible, though stars were squares not stars)
- No tracker/leaderboard (not implemented yet)
- Website deployed at milkchugstudios.com via Vercel

The session goal was to get the core pickup star icons working, keep everything else intact,
and then implement the tracker/leaderboard system.

---

## Failure Log

### Failure #1 — Inner Class Star Icon Broke the Entire .pck

**What was attempted:**
Added a `class StarIcon extends Control` inner class inside `core_swap_ui.gd` with a `_draw()`
override to draw a polygon star shape.

**What happened:**
Godot exports scripts as binary bytecode (`script_export_mode=2`). Inner classes with `_draw()`
overrides appear to cause silent compilation failures in this mode. The exported `.pck` was
broken — the game loaded a black screen.

**User feedback:** "IDK what you did but the core UI issues came back"

**Time wasted:** Multiple export cycles trying to diagnose the black screen.

---

### Failure #2 — External `star_icon.gd` Preload Cascaded Into .pck Failure

**What was attempted:**
Before the inner class, a separate file `scripts/ui/star_icon.gd` was created and referenced
via `preload()` inside `core_swap_ui.gd`.

**What happened:**
The preloaded file either failed to compile or was not properly included in the binary
export, causing a cascade failure in the parent script's bytecode. Black screen again.

**Resolution:**
Deleted `star_icon.gd` entirely. Confirmed no other files reference it.
Replaced with a plain `Label` using the `★` Unicode character — no custom drawing,
no external files, no preload.

**Time wasted:** At least 2-3 export cycles.

---

### Failure #3 — Service Worker Intercepting index.js

**What happened:**
A previous export (from an earlier session, before today) had `ensureCrossOriginIsolationHeaders: true`
set. Godot's web export installs a service worker when this flag is enabled. That service worker
persisted in the browser and intercepted ALL network requests — including `index.js` — returning
the `index.html` HTML response instead of the actual JavaScript file.

**Console error seen by user:**
```
index.js:1 Uncaught SyntaxError: Unexpected token '<'
power-thief:109 Uncaught ReferenceError: Engine is not defined
```

**What this looked like:** Complete black screen. Game did not load at all.

**Resolution:**
- User manually went to `chrome://serviceworker-internals` and unregistered all service workers.
- A SW auto-unregister script was added to `index.html` `<body>` to prevent recurrence:
  ```html
  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for (var r of registrations) { r.unregister(); }
      });
    }
  </script>
  ```

**Critical ongoing issue:** Godot overwrites `index.html` on every export, removing this script.
It must be re-injected manually after every single export. This was automated in the deploy
pipeline but is fragile and easy to forget.

---

### Failure #4 — Vercel Was Serving a Stale/Failed Deployment

**What happened:**
Even after the SW was cleared, the deploy was sometimes not reflecting new exports. Root cause:
Vercel was failing to build due to `"node": ">=22.12.0"` in `package.json` conflicting with
the actual Node version on Vercel's build environment.

**Fix applied:**
- Changed `engines.node` from `">=22.12.0"` to `">=18.17.1"` in `package.json`.
- Removed the `public/games/power-thief/` directory from git (it was a 90MB duplicate of
  `public/play/power-thief/` with no purpose — the website only reads from `play/`).

**Side effect of removing games/ directory:**
The export preset (`export_presets.cfg`) originally pointed to
`../../../milk-chug-studios-website/public/games/power-thief/index.html`. After that directory
was removed from git, Godot either created a new directory there or the user changed the
export path to `./index.html` (exporting into the game project root). The exact moment this
changed is unclear. This caused confusion about where exported files actually go.

**Current state:** Export path is `./index.html` (game project root). Deploy pipeline must
manually copy these to `public/play/power-thief/` before committing.

---

### Failure #5 — Camera Zoom Making the Room Invisible

**What happened:**
After fixing the service worker and getting the game to actually load, the room floor and
enemies were not visible. The camera had `zoom = Vector2(0.6, 0.6)`.

At 0.6x zoom, the visible area is 2133×1200 game units. The room floor is 1280×720 with
color `Color(0.12, 0.12, 0.18)` — nearly black. At 0.6x zoom, this floor covered only
~36% of the visible canvas area, surrounded by pure black background. It was visually
indistinguishable from a black screen.

Enemies did spawn within room bounds but appeared tiny and near the edges of a largely-black canvas.

**User feedback:**
> "The game starts, but just like the issue you got us into no background is displayed nor do
> any enemies spawn... this is a major setback from what the game was doing a little ago and
> extremely disappointing."

**Fix applied:** Changed `zoom = Vector2(0.6, 0.6)` → `zoom = Vector2(1.0, 1.0)` in
`scenes/player/Player.tscn`.

**Status at end of session:** This fix was exported and deployed. Not yet confirmed working
by user — user went to bed before verifying.

---

### Failure #6 — Tracker and Leaderboard Not Working

**What was attempted:**
New autoload scripts were written: `PlayerAuth`, `Tracker`, and UI screens for Login,
Almanac, and Leaderboard.

**Current state:**
Scripts exist in the repo but the system has NOT been verified working end-to-end.
Supabase integration requires environment variables and correct table setup. The website
leaderboard page (`Phase 6`) is also incomplete. These features were never tested in
the live environment during this session.

---

### Failure #7 — Thumbnail Ruined

**What happened:**
During the session, `assets/thumbnail.png` was committed. The Godot web export generates
`index.png` (21,443 bytes) as the loading splash/thumbnail. The actual thumbnail asset
(`assets/thumbnail.png`, 30,210 bytes) appears to be different.

The `index.png` currently deployed to `public/play/power-thief/` is the Godot-generated
splash (21,443 bytes), not the custom thumbnail. It is unclear exactly when or how the
custom thumbnail was overwritten, but it likely happened when Godot exported and overwrote
`index.png` in the play directory.

**Status:** Thumbnail needs to be restored. The original thumbnail may exist in git history
or in `assets/thumbnail.png`.

---

## What Was Actually Confirmed Working

- **SW unregister script:** Successfully prevents the service worker from blocking `index.js` on future page loads.
- **Unicode star in core swap UI:** `_make_star_control()` now returns a plain `Label` with `★`. No custom drawing, no external dependencies. Should render correctly in web export (not confirmed live by user since game wasn't loading when core pickup was tested).
- **Vercel deployment pipeline:** Fixed. Deploys are now going through reliably.
- **Node version fix:** `package.json` engines constraint no longer blocks builds.
- **Camera zoom fix:** Deployed — not yet confirmed by user.

---

## What Is Still Broken (As of End of Session)

1. **Game may still not be playable** — Camera fix was deployed but not verified by user.
2. **Core pickup star UI** — Not confirmed working live. May work once game actually runs.
3. **Tracker / Leaderboard** — Not functional end-to-end. Scripts written but untested.
4. **Thumbnail** — Corrupted by Godot export overwriting `index.png`.
5. **Export pipeline fragility** — SW script is re-injected manually every export; easy to forget.

---

## Mistakes I Made (Honest Assessment)

1. **Used `script_export_mode=2` without understanding its constraints.** Inner classes and
   preloaded external scripts are risky in binary export mode. Should have used the simplest
   possible approach (Unicode character) from the start instead of going through 3 failed attempts.

2. **Did not diagnose the service worker issue faster.** The console error `Unexpected token '<'`
   is a clear signal that a network request is returning HTML instead of JS. Should have
   identified the SW as the culprit on the first occurrence instead of re-exporting multiple times.

3. **Did not track where the export files actually go.** The export path changed during the
   session (from `public/games/power-thief/` to `./index.html`) and I did not notice this
   clearly, leading to confusion about whether the latest export was actually being deployed.

4. **Multiple export cycles on the same broken approach.** Each Godot export takes time and
   each deploy takes time. I should have been more certain a fix would work before asking
   the user to export and deploy.

5. **Thumbnail was not protected.** Godot's export overwrites `index.png` and `index.html`.
   I added protection for `index.html` (SW script) but forgot that `index.png` is also
   overwritten. The custom thumbnail must be restored after every export.

---

## Action Plan for Tomorrow

### Priority 1 — Verify the Game Is Actually Playable
- Hard refresh (Ctrl+Shift+R) on the game page
- Confirm room floor is visible, enemies spawn, player can move
- If still broken, check F12 console for errors before touching any code

### Priority 2 — Restore the Thumbnail
- Find the correct thumbnail (check `assets/thumbnail.png` vs what was in git before today)
- Copy it to `public/play/power-thief/index.png` after each export going forward
- Consider adding the thumbnail copy step to the documented deploy pipeline in `backendops.md`

### Priority 3 — Confirm Core Pickup Stars Work
- Pick up a core in-game and verify the `★` symbols render in the UI
- If squares appear, check that the web export font includes the Unicode star glyph

### Priority 4 — Fix the Deploy Pipeline Fragility
- Document exactly which files get overwritten by Godot export and what must be restored
- The current manual steps are: export → inject SW script → copy correct thumbnail → copy to play/ → commit → push
- Consider whether the export path should point directly to `public/play/power-thief/`
  (would eliminate the copy step but would still require post-export file fixes)

### Priority 5 — Tracker and Leaderboard
- Do NOT touch this until the game itself is confirmed working
- Verify Supabase env vars are set in Vercel dashboard
- Test login flow in the live game first, then test tracker submission
- Only then work on the website leaderboard page (Phase 6)

---

## Key Technical Facts to Remember

| Thing | Correct Value |
|---|---|
| Camera zoom | `Vector2(1.0, 1.0)` |
| Window mode | `mode=0` (Windowed, NOT Fullscreen) |
| Script export mode | `2` (bytecode) — avoid inner classes, avoid preload of custom scripts |
| SW unregister script | Must be in `<body>` of `index.html` — gets deleted on every Godot export |
| `index.png` | Gets overwritten by Godot export — custom thumbnail must be restored after every export |
| `ensureCrossOriginIsolationHeaders` | Must be `false` — already set in export preset |
| Export path | Currently `./index.html` (game project root) — must copy to `public/play/power-thief/` |
| Node version | `>=18.17.1` in `package.json` |
