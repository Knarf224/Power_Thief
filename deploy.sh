#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh — Power Thief post-export pipeline
#
# Run this ONCE after every Godot web export. It fixes all the fragile
# manual steps so nothing gets forgotten.
#
# Usage (from the game project root):
#   bash deploy.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

GAME_ROOT="$(cd "$(dirname "$0")" && pwd)"
WEBSITE_DIR="/d/Coding_W_Knarf/Coding/milk-chug-studios-website/public/play/power-thief"
WEBSITE_CARD_DIR="/d/Coding_W_Knarf/Coding/milk-chug-studios-website/public/games/power-thief"
THUMBNAIL="$GAME_ROOT/assets/thumbnail.png"
INDEX_HTML="$GAME_ROOT/index.html"

echo ""
echo "=== Power Thief Deploy Script ==="
echo ""

# ── 1. Sanity checks ──────────────────────────────────────────────────────────
if [ ! -f "$INDEX_HTML" ]; then
  echo "ERROR: index.html not found at $GAME_ROOT"
  echo "       Export the game from Godot first."
  exit 1
fi

if [ ! -f "$THUMBNAIL" ]; then
  echo "ERROR: Thumbnail not found at $THUMBNAIL"
  exit 1
fi

if [ ! -d "$WEBSITE_DIR" ]; then
  echo "ERROR: Website directory not found: $WEBSITE_DIR"
  echo "       Check that the milk-chug-studios-website repo is at the expected path."
  exit 1
fi

# ── 2. Fix index.html — COEP flag ─────────────────────────────────────────────
if grep -q '"ensureCrossOriginIsolationHeaders":true' "$INDEX_HTML"; then
  sed -i 's/"ensureCrossOriginIsolationHeaders":true/"ensureCrossOriginIsolationHeaders":false/g' "$INDEX_HTML"
  echo "[OK] COEP flag set to false in index.html"
else
  echo "[OK] COEP flag already false — no change needed"
fi

# ── 3. Fix index.html — SW unregister script ─────────────────────────────────
# Inject only if not already present (idempotent)
if grep -q "__gdNetSW_unregistered\|serviceWorker.getRegistrations" "$INDEX_HTML"; then
  echo "[OK] SW unregister script already present — no change needed"
else
  # Insert after the opening <body> tag
  SW_SCRIPT='<script>\n    if ("serviceWorker" in navigator) {\n      navigator.serviceWorker.getRegistrations().then(function(registrations) {\n        for (var r of registrations) { r.unregister(); }\n      });\n    }\n  </script>'
  sed -i "s|<body>|<body>\n  $SW_SCRIPT|" "$INDEX_HTML"
  echo "[OK] SW unregister script injected into index.html"
fi

# ── 4. Restore thumbnail ───────────────────────────────────────────────────────
cp "$THUMBNAIL" "$GAME_ROOT/index.png"
echo "[OK] Thumbnail restored: assets/thumbnail.png → index.png"

# ── 5. Copy all export files to website ───────────────────────────────────────
cp "$GAME_ROOT"/index.* "$WEBSITE_DIR/"
echo "[OK] All index.* files copied to $WEBSITE_DIR"

# ── 6. Keep game card thumbnail in sync ───────────────────────────────────────
# The Supabase games table cover column points to /games/power-thief/thumbnail.png
mkdir -p "$WEBSITE_CARD_DIR"
cp "$THUMBNAIL" "$WEBSITE_CARD_DIR/thumbnail.png"
echo "[OK] Game card thumbnail synced to $WEBSITE_CARD_DIR/thumbnail.png"

# ── 6. Summary ────────────────────────────────────────────────────────────────
echo ""
echo "=== Done. Next steps: ==="
echo ""
echo "  1. Test locally first:"
echo "       cd /d/Coding_W_Knarf/Coding/milk-chug-studios-website"
echo "       npm run dev"
echo "       → Open http://localhost:4321/games/power-thief"
echo ""
echo "  2. When confirmed working locally, commit the website repo:"
echo "       cd /d/Coding_W_Knarf/Coding/milk-chug-studios-website"
echo "       git add public/play/power-thief/"
echo "       git commit -m 'Deploy Power Thief update'"
echo "       git push"
echo ""
echo "  Do NOT push to Vercel until it works locally."
echo ""
