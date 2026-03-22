-- ============================================================
-- Power Thief – Supabase Schema Migration v1
-- ============================================================
-- HOW TO RUN:
--   1. Open your Supabase project dashboard
--   2. Go to SQL Editor → New query
--   3. Paste this entire file and click Run
--   4. Verify: Table Editor should show profiles, tracker,
--              high_scores, and game_stats tables
-- ============================================================


-- ============================================================
-- TABLES
-- ============================================================

-- 1. PROFILES
-- One row per registered player. Linked to Supabase Auth user.
-- Username is the player-facing identity; email is optional
-- (auth always uses a generated fake email internally).
CREATE TABLE IF NOT EXISTS public.profiles (
    id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username    TEXT        UNIQUE NOT NULL,
    email       TEXT,                              -- user-supplied real email, may be null
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 2. TRACKER (Player Almanac)
-- One row per registered player. All counters are cumulative
-- across all runs ever played on that account.
-- Rows are created on first sync via the upsert_tracker() RPC.
CREATE TABLE IF NOT EXISTS public.tracker (
    user_id                 UUID        PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    runs_attempted          INT         NOT NULL DEFAULT 0,
    deaths                  INT         NOT NULL DEFAULT 0,
    wins                    INT         NOT NULL DEFAULT 0,   -- win = cleared level 20 boss
    -- Regular enemy kills
    kills_fire_mage         INT         NOT NULL DEFAULT 0,
    kills_rogue_assassin    INT         NOT NULL DEFAULT 0,
    kills_slime             INT         NOT NULL DEFAULT 0,
    kills_ghost             INT         NOT NULL DEFAULT 0,
    kills_bomb_beetle       INT         NOT NULL DEFAULT 0,
    kills_ice_witch         INT         NOT NULL DEFAULT 0,
    kills_lightning_sprite  INT         NOT NULL DEFAULT 0,
    kills_stone_golem       INT         NOT NULL DEFAULT 0,
    kills_necromancer       INT         NOT NULL DEFAULT 0,
    kills_poison_toad       INT         NOT NULL DEFAULT 0,
    -- Boss kills
    kills_warden            INT         NOT NULL DEFAULT 0,
    kills_lich              INT         NOT NULL DEFAULT 0,
    kills_phantom           INT         NOT NULL DEFAULT 0,
    kills_plague_lord       INT         NOT NULL DEFAULT 0,
    kills_storm_tyrant      INT         NOT NULL DEFAULT 0,
    -- Aggregate
    total_kills             INT         NOT NULL DEFAULT 0,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 3. HIGH SCORES
-- One row per submitted run. Leaderboard = ORDER BY highest_room DESC.
-- user_id is nullable so guests can be supported in a future phase
-- if needed (currently only logged-in players submit scores).
CREATE TABLE IF NOT EXISTS public.high_scores (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
    display_name    TEXT        NOT NULL,          -- snapshot of username at time of run
    highest_room    INT         NOT NULL,
    cores           TEXT[]      NOT NULL DEFAULT '{}',  -- e.g. ARRAY['fire','dash','ice']
    achieved_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS high_scores_room_idx ON public.high_scores (highest_room DESC);


-- 4. GAME STATS
-- Single-row table tracking total plays across all players + guests.
CREATE TABLE IF NOT EXISTS public.game_stats (
    id          INT     PRIMARY KEY DEFAULT 1,
    total_plays BIGINT  NOT NULL DEFAULT 0
);

INSERT INTO public.game_stats (id, total_plays)
VALUES (1, 0)
ON CONFLICT DO NOTHING;


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracker     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.high_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_stats  ENABLE ROW LEVEL SECURITY;


-- PROFILES
-- Everyone can read (leaderboard needs to display usernames).
-- Only the owner can insert or update their own row.
CREATE POLICY "profiles_select_all"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);


-- TRACKER
-- Only the owner can read or modify their own row.
CREATE POLICY "tracker_select_own"
    ON public.tracker FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "tracker_insert_own"
    ON public.tracker FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tracker_update_own"
    ON public.tracker FOR UPDATE
    USING (auth.uid() = user_id);


-- HIGH SCORES
-- Anyone can read (public leaderboard).
-- Only authenticated users can insert their own score.
CREATE POLICY "scores_select_all"
    ON public.high_scores FOR SELECT
    USING (true);

CREATE POLICY "scores_insert_own"
    ON public.high_scores FOR INSERT
    WITH CHECK (auth.uid() = user_id);


-- GAME STATS
-- Anyone (including anon/guests) can read the play count.
-- No direct UPDATE — only via the increment_play_count() RPC.
CREATE POLICY "stats_select_all"
    ON public.game_stats FOR SELECT
    USING (true);


-- ============================================================
-- AUTH TRIGGER
-- Automatically creates a profiles row when a new Supabase Auth
-- user is created. The Godot register call passes username and
-- optional real_email inside raw_user_meta_data.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, username, email)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'username',
        NULLIF(NEW.raw_user_meta_data->>'real_email', '')
    );
    RETURN NEW;
END;
$$;

-- Drop first so re-running this file is safe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- RPC FUNCTIONS (called from Godot via HTTP POST /rest/v1/rpc/)
-- ============================================================

-- increment_play_count()
-- Called by ALL players (including guests) when a run starts.
-- Anon and authenticated users are both granted execute.
CREATE OR REPLACE FUNCTION public.increment_play_count()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    UPDATE game_stats SET total_plays = total_plays + 1 WHERE id = 1;
$$;

GRANT EXECUTE ON FUNCTION public.increment_play_count() TO anon, authenticated;


-- upsert_tracker(...)
-- Called by logged-in players at the end of every run.
-- Inserts a new tracker row on first run, otherwise ADDS the
-- deltas to the existing cumulative totals.
-- Security: enforces auth.uid() = p_user_id so no spoofing.
CREATE OR REPLACE FUNCTION public.upsert_tracker(
    p_user_id               UUID,
    p_runs_delta            INT,
    p_deaths_delta          INT,
    p_wins_delta            INT,
    p_kills_fire_mage       INT,
    p_kills_rogue_assassin  INT,
    p_kills_slime           INT,
    p_kills_ghost           INT,
    p_kills_bomb_beetle     INT,
    p_kills_ice_witch       INT,
    p_kills_lightning_sprite INT,
    p_kills_stone_golem     INT,
    p_kills_necromancer     INT,
    p_kills_poison_toad     INT,
    p_kills_warden          INT,
    p_kills_lich            INT,
    p_kills_phantom         INT,
    p_kills_plague_lord     INT,
    p_kills_storm_tyrant    INT,
    p_total_kills           INT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only allow users to update their own tracker
    IF auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'unauthorized: cannot update another player''s tracker';
    END IF;

    INSERT INTO tracker (
        user_id, runs_attempted, deaths, wins,
        kills_fire_mage, kills_rogue_assassin, kills_slime, kills_ghost,
        kills_bomb_beetle, kills_ice_witch, kills_lightning_sprite,
        kills_stone_golem, kills_necromancer, kills_poison_toad,
        kills_warden, kills_lich, kills_phantom, kills_plague_lord, kills_storm_tyrant,
        total_kills, updated_at
    )
    VALUES (
        p_user_id, p_runs_delta, p_deaths_delta, p_wins_delta,
        p_kills_fire_mage, p_kills_rogue_assassin, p_kills_slime, p_kills_ghost,
        p_kills_bomb_beetle, p_kills_ice_witch, p_kills_lightning_sprite,
        p_kills_stone_golem, p_kills_necromancer, p_kills_poison_toad,
        p_kills_warden, p_kills_lich, p_kills_phantom, p_kills_plague_lord, p_kills_storm_tyrant,
        p_total_kills, NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        runs_attempted          = tracker.runs_attempted          + EXCLUDED.runs_attempted,
        deaths                  = tracker.deaths                  + EXCLUDED.deaths,
        wins                    = tracker.wins                    + EXCLUDED.wins,
        kills_fire_mage         = tracker.kills_fire_mage         + EXCLUDED.kills_fire_mage,
        kills_rogue_assassin    = tracker.kills_rogue_assassin    + EXCLUDED.kills_rogue_assassin,
        kills_slime             = tracker.kills_slime             + EXCLUDED.kills_slime,
        kills_ghost             = tracker.kills_ghost             + EXCLUDED.kills_ghost,
        kills_bomb_beetle       = tracker.kills_bomb_beetle       + EXCLUDED.kills_bomb_beetle,
        kills_ice_witch         = tracker.kills_ice_witch         + EXCLUDED.kills_ice_witch,
        kills_lightning_sprite  = tracker.kills_lightning_sprite  + EXCLUDED.kills_lightning_sprite,
        kills_stone_golem       = tracker.kills_stone_golem       + EXCLUDED.kills_stone_golem,
        kills_necromancer       = tracker.kills_necromancer       + EXCLUDED.kills_necromancer,
        kills_poison_toad       = tracker.kills_poison_toad       + EXCLUDED.kills_poison_toad,
        kills_warden            = tracker.kills_warden            + EXCLUDED.kills_warden,
        kills_lich              = tracker.kills_lich              + EXCLUDED.kills_lich,
        kills_phantom           = tracker.kills_phantom           + EXCLUDED.kills_phantom,
        kills_plague_lord       = tracker.kills_plague_lord       + EXCLUDED.kills_plague_lord,
        kills_storm_tyrant      = tracker.kills_storm_tyrant      + EXCLUDED.kills_storm_tyrant,
        total_kills             = tracker.total_kills             + EXCLUDED.total_kills,
        updated_at              = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_tracker(
    UUID, INT, INT, INT, INT, INT, INT, INT, INT, INT,
    INT, INT, INT, INT, INT, INT, INT, INT, INT, INT
) TO authenticated;


-- ============================================================
-- DONE
-- ============================================================
-- Tables created:  profiles, tracker, high_scores, game_stats
-- RLS enabled on all tables
-- Auth trigger:    handle_new_user → auto-creates profiles row
-- RPC functions:   increment_play_count(), upsert_tracker()
-- ============================================================
