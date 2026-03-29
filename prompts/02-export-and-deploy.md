# Prompt: Export and Deploy Power Thief

Use this prompt when deploying an updated build to milkchugstudios.com.
Work through each stage in order — do not skip to a later stage until the current one passes.

---

## Stage 1 — Pre-export checklist (verify in Godot before exporting)

- [ ] `staging_mode = false` in `scripts/autoload/game_state.gd`
- [ ] `quick_mode = false` in `scripts/autoload/game_state.gd`
- [ ] Any temporary enemy pool overrides reverted
- [ ] Any hardcoded spawn counts reverted to `GameState.get_enemy_count(N)`
- [ ] F5 in Godot runs clean — no errors in the output panel

---

## Stage 2 — Godot web export

1. In Godot: **Project → Export → Web → Export Project**
2. Destination: `./index.html` (game project root — `C:\Users\Francisco\Power_Thief\new-game-project\`)
3. Click **Export Project** and wait for it to finish

---

## Stage 3 — Post-export pipeline (run immediately after export)

From the game project root in a bash terminal:

```bash
bash deploy.sh
```

This script automatically:
- Flips `ensureCrossOriginIsolationHeaders` to `false` in `index.html`
- Injects the service worker unregister script (if missing)
- Restores `assets/thumbnail.png` → `index.png`
- Copies all `index.*` files to the website repo at `public/play/power-thief/`
- Syncs the game card thumbnail to `public/games/power-thief/thumbnail.png`

---

## Stage 4 — Local test (must pass before pushing to Vercel)

Start the website dev server:

```bash
cd C:\Users\Francisco\milk-chug-studios-website
npm run dev
```

Open `http://localhost:4321/games/power-thief` and verify:

- [ ] Game loads with no red errors in browser console (F12 → Console)
- [ ] `[relay] iframe fetch patched` appears in console
- [ ] Login flow completes successfully
- [ ] A full run completes — enemies spawn, room clears, transition works
- [ ] Tracker data submits on run end (no red network errors)
- [ ] Leaderboard page loads and displays scores

Do not proceed to Stage 5 until all boxes above are checked.

---

## Stage 5 — Deploy to production

```bash
cd C:\Users\Francisco\milk-chug-studios-website
git add public/play/power-thief/
git add public/games/power-thief/thumbnail.png
git commit -m "Deploy Power Thief — [brief description of what changed]"
git push
```

Wait for Vercel to finish (~1–2 min), then verify at:
**https://milkchugstudios.com/games/power-thief**

---

## Adding future prompts

To add a new saved prompt, create `prompts/03-[short-name].md` and follow the same format:
- Fill-in block at the top (context for the specific task)
- Instructions block for Claude (what to read first, steps in order)
- Verification block at the end (how to confirm it worked)
