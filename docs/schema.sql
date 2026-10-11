-- =============================================================================
-- Padelicious — Skema Database Backend (PostgreSQL 14+)
-- Lihat docs/database-design.md untuk penjelasan tiap tabel dan keputusan desain.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;     -- email case-insensitive
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- pencarian "contains" pada nama

-- -----------------------------------------------------------------------------
-- ENUM
-- -----------------------------------------------------------------------------
CREATE TYPE user_status         AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE auth_provider       AS ENUM ('google', 'apple', 'facebook', 'reclub');
CREATE TYPE player_gender       AS ENUM ('male', 'female', 'other', 'undisclosed');
CREATE TYPE club_visibility     AS ENUM ('public', 'private', 'invite_only');
CREATE TYPE club_role           AS ENUM ('owner', 'admin', 'member');
CREATE TYPE membership_status   AS ENUM ('active', 'pending', 'left', 'banned');
CREATE TYPE scoring_type        AS ENUM ('normal', 'tennis');
CREATE TYPE tennis_mode         AS ENUM ('race3','race4','race5','race6','race7',
                                         'total3','total4','total5','total6','total7');
CREATE TYPE leaderboard_sort    AS ENUM ('points', 'wins');
CREATE TYPE session_status      AS ENUM ('draft', 'active', 'completed', 'cancelled');
CREATE TYPE participant_role    AS ENUM ('host', 'admin', 'player');
CREATE TYPE participant_source  AS ENUM ('manual', 'club', 'reclub');
CREATE TYPE participant_status  AS ENUM ('active', 'queued', 'withdrawn');
CREATE TYPE round_status        AS ENUM ('pending', 'in_progress', 'completed');
CREATE TYPE match_status        AS ENUM ('scheduled', 'live', 'finished', 'abandoned');
CREATE TYPE team_side           AS ENUM ('a', 'b');
CREATE TYPE import_status       AS ENUM ('pending', 'success', 'failed');
CREATE TYPE share_resource      AS ENUM ('session', 'leaderboard', 'match');
CREATE TYPE share_access        AS ENUM ('view', 'score');

-- -----------------------------------------------------------------------------
-- Trigger util: updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 1. IDENTITAS & AUTENTIKASI
-- =============================================================================

CREATE TABLE users (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email              citext NOT NULL UNIQUE,
  email_verified_at  timestamptz,
  password_hash      text,                       -- NULL bila murni social login
  full_name          text NOT NULL,
  phone              text,
  status             user_status NOT NULL DEFAULT 'active',
  accepted_terms_at  timestamptz,
  last_login_at      timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT users_email_format CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE user_auth_identities (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider         auth_provider NOT NULL,
  provider_user_id text NOT NULL,
  email            citext,
  raw_profile      jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_user_id)
);
CREATE INDEX idx_auth_identities_user ON user_auth_identities (user_id);

CREATE TABLE user_sessions (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash text NOT NULL UNIQUE,       -- simpan hash, bukan token mentah
  device_name        text,
  user_agent         text,
  ip_address         inet,
  remember_me        boolean NOT NULL DEFAULT false,
  expires_at         timestamptz NOT NULL,
  revoked_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_user_sessions_active ON user_sessions (user_id)
  WHERE revoked_at IS NULL;

CREATE TABLE password_reset_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  used_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_reset_tokens_user ON password_reset_tokens (user_id)
  WHERE used_at IS NULL;

-- =============================================================================
-- 2. PEMAIN & KLUB
-- =============================================================================

CREATE TABLE players (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid UNIQUE REFERENCES users(id) ON DELETE SET NULL,
  display_name        text NOT NULL,
  initials            char(2) NOT NULL,
  avatar_url          text,
  avatar_color_index  smallint NOT NULL DEFAULT 0
    CHECK (avatar_color_index BETWEEN 0 AND 7),   -- indeks AppColors.chipPairs*
  skill_level         numeric(2,1) CHECK (skill_level BETWEEN 1.0 AND 5.0),
  skill_level_label   text,
  gender              player_gender NOT NULL DEFAULT 'undisclosed',
  is_guest            boolean GENERATED ALWAYS AS (user_id IS NULL) STORED,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_players_updated BEFORE UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_players_name_trgm ON players USING gin (display_name gin_trgm_ops);

CREATE TABLE clubs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            text NOT NULL UNIQUE,
  name            text NOT NULL,
  emoji           text NOT NULL DEFAULT '🎾',
  theme_color     text,
  description     text NOT NULL DEFAULT '',
  city            text,
  visibility      club_visibility NOT NULL DEFAULT 'public',
  owner_player_id uuid REFERENCES players(id) ON DELETE SET NULL,
  member_count    integer NOT NULL DEFAULT 0 CHECK (member_count >= 0),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz
);
CREATE TRIGGER trg_clubs_updated BEFORE UPDATE ON clubs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_clubs_name_trgm ON clubs USING gin (name gin_trgm_ops);
CREATE INDEX idx_clubs_visible ON clubs (visibility) WHERE deleted_at IS NULL;

CREATE TABLE club_members (
  club_id   uuid NOT NULL REFERENCES clubs(id)   ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  role      club_role NOT NULL DEFAULT 'member',
  status    membership_status NOT NULL DEFAULT 'active',
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at   timestamptz,
  PRIMARY KEY (club_id, player_id)
);
CREATE INDEX idx_club_members_player ON club_members (player_id)
  WHERE status = 'active';
-- Satu klub hanya boleh punya satu owner aktif.
CREATE UNIQUE INDEX idx_club_single_owner ON club_members (club_id)
  WHERE role = 'owner' AND status = 'active';

-- Counter cache clubs.member_count
CREATE OR REPLACE FUNCTION sync_club_member_count() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'active' THEN
      UPDATE clubs SET member_count = member_count + 1 WHERE id = NEW.club_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status = 'active' THEN
      UPDATE clubs SET member_count = member_count - 1 WHERE id = OLD.club_id;
    END IF;
  ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status = 'active' THEN
      UPDATE clubs SET member_count = member_count + 1 WHERE id = NEW.club_id;
    ELSIF OLD.status = 'active' THEN
      UPDATE clubs SET member_count = member_count - 1 WHERE id = NEW.club_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_club_member_count
  AFTER INSERT OR UPDATE OR DELETE ON club_members
  FOR EACH ROW EXECUTE FUNCTION sync_club_member_count();

-- =============================================================================
-- 3. SESI & KONFIGURASI MATCH
-- =============================================================================

CREATE TABLE match_types (
  code          text PRIMARY KEY,
  label         text NOT NULL,
  category      text NOT NULL,
  is_team_based boolean NOT NULL DEFAULT false,
  is_mixed      boolean NOT NULL DEFAULT false,
  requires_club boolean NOT NULL DEFAULT false,
  sort_order    smallint NOT NULL DEFAULT 0
);

INSERT INTO match_types (code, label, category, is_team_based, is_mixed, requires_club, sort_order) VALUES
  ('americano',           'Americano',              'Americano', false, false, false, 1),
  ('team_americano',      'Team Americano',         'Americano', true,  false, false, 2),
  ('mix_americano',       'Mix Americano',          'Americano', false, true,  false, 3),
  ('mexicano',            'Mexicano',               'Mexicano',  false, false, false, 4),
  ('team_mexicano',       'Team Mexicano',          'Mexicano',  true,  false, false, 5),
  ('mixicano',            'Mixicano',               'Mexicano',  false, true,  false, 6),
  ('koth',                'King of the Court',      'KOTH',      false, false, false, 7),
  ('team_koth',           'Team King of the Court', 'KOTH',      true,  false, false, 8),
  ('club_team_americano', 'Club Team Americano',    'Club',      true,  false, true,  9),
  ('club_americano',      'Club Americano',         'Club',      false, false, true, 10),
  ('club_mexicano',       'Club Mexicano',          'Club',      false, false, true, 11);

CREATE TABLE sessions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id           uuid REFERENCES clubs(id) ON DELETE SET NULL,
  host_player_id    uuid NOT NULL REFERENCES players(id),
  name              text NOT NULL,
  icon              text NOT NULL DEFAULT '🎾',
  match_type_code   text NOT NULL REFERENCES match_types(code),
  scheduled_date    date NOT NULL,
  court_count       smallint NOT NULL DEFAULT 1
    CHECK (court_count BETWEEN 1 AND 4),
  scoring_type      scoring_type NOT NULL DEFAULT 'normal',
  points_target     smallint CHECK (points_target IN (16, 21, 24, 32)),
  tennis_mode       tennis_mode,
  golden_point      boolean NOT NULL DEFAULT true,
  leaderboard_sort  leaderboard_sort NOT NULL DEFAULT 'points',
  status            session_status NOT NULL DEFAULT 'draft',
  started_at        timestamptz,
  completed_at      timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  -- Konfigurasi scoring harus konsisten: normal pakai points_target,
  -- tennis pakai tennis_mode. NULL di keduanya = "Undefined".
  CONSTRAINT sessions_scoring_consistent CHECK (
    (scoring_type = 'normal' AND tennis_mode IS NULL)
    OR
    (scoring_type = 'tennis' AND points_target IS NULL)
  )
);
CREATE TRIGGER trg_sessions_updated BEFORE UPDATE ON sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_sessions_status_date ON sessions (status, scheduled_date DESC);
CREATE INDEX idx_sessions_club        ON sessions (club_id, scheduled_date DESC);
CREATE INDEX idx_sessions_host        ON sessions (host_player_id, scheduled_date DESC);

CREATE TABLE session_participants (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id                  uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  player_id                   uuid NOT NULL REFERENCES players(id),
  display_name_snapshot       text NOT NULL,
  initials_snapshot           char(2) NOT NULL,
  avatar_color_index_snapshot smallint NOT NULL DEFAULT 0,
  role                        participant_role NOT NULL DEFAULT 'player',
  source                      participant_source NOT NULL DEFAULT 'manual',
  status                      participant_status NOT NULL DEFAULT 'active',
  joined_at                   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (session_id, player_id)
);
CREATE INDEX idx_participants_player  ON session_participants (player_id);
CREATE INDEX idx_participants_session ON session_participants (session_id, status);

CREATE TABLE courts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  court_number smallint NOT NULL CHECK (court_number BETWEEN 1 AND 4),
  label        text,
  UNIQUE (session_id, court_number)
);

CREATE TABLE session_queue (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id     uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  participant_id uuid NOT NULL REFERENCES session_participants(id) ON DELETE CASCADE,
  position       integer NOT NULL CHECK (position > 0),
  enqueued_at    timestamptz NOT NULL DEFAULT now(),
  dequeued_at    timestamptz,
  -- DEFERRABLE agar reorder antrean (swap posisi) tidak gagal di tengah transaksi.
  CONSTRAINT session_queue_position_unique UNIQUE (session_id, position)
    DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX idx_queue_active ON session_queue (session_id, position)
  WHERE dequeued_at IS NULL;

-- =============================================================================
-- 4. RONDE, MATCH, DAN SKOR
-- =============================================================================

CREATE TABLE rounds (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  round_number integer NOT NULL CHECK (round_number > 0),
  status       round_status NOT NULL DEFAULT 'pending',
  generated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (session_id, round_number)
);

CREATE TABLE matches (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  round_id     uuid NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
  court_id     uuid NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
  status       match_status NOT NULL DEFAULT 'scheduled',
  games_a      smallint NOT NULL DEFAULT 0 CHECK (games_a >= 0),
  games_b      smallint NOT NULL DEFAULT 0 CHECK (games_b >= 0),
  points_a     text NOT NULL DEFAULT '0',
  points_b     text NOT NULL DEFAULT '0',
  serving_team team_side,
  winner_team  team_side,
  started_at   timestamptz,
  finished_at  timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (round_id, court_id),
  CONSTRAINT matches_winner_only_when_finished CHECK (
    winner_team IS NULL OR status = 'finished'
  )
);
CREATE TRIGGER trg_matches_updated BEFORE UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_matches_round ON matches (round_id);
CREATE INDEX idx_matches_live  ON matches (status) WHERE status = 'live';

CREATE TABLE match_teams (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  side         team_side NOT NULL,
  score_points integer NOT NULL DEFAULT 0 CHECK (score_points >= 0),
  UNIQUE (match_id, side)
);

CREATE TABLE match_team_players (
  match_team_id  uuid NOT NULL REFERENCES match_teams(id) ON DELETE CASCADE,
  participant_id uuid NOT NULL REFERENCES session_participants(id) ON DELETE CASCADE,
  slot           smallint NOT NULL CHECK (slot IN (1, 2)),
  PRIMARY KEY (match_team_id, slot),
  UNIQUE (match_team_id, participant_id)
);
CREATE INDEX idx_mtp_participant ON match_team_players (participant_id);

-- Event log skor: sumber kebenaran untuk undo, audit, dan replay.
CREATE TABLE match_points (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id              uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sequence              integer NOT NULL CHECK (sequence > 0),
  scoring_team          team_side NOT NULL,
  serving_team          team_side,
  points_a_before       text NOT NULL,
  points_b_before       text NOT NULL,
  games_a_before        smallint NOT NULL,
  games_b_before        smallint NOT NULL,
  is_game_point         boolean NOT NULL DEFAULT false,
  is_golden_point       boolean NOT NULL DEFAULT false,
  recorded_by_player_id uuid REFERENCES players(id) ON DELETE SET NULL,
  recorded_at           timestamptz NOT NULL DEFAULT now(),
  voided_at             timestamptz,
  UNIQUE (match_id, sequence)
);
CREATE INDEX idx_match_points_match_seq ON match_points (match_id, sequence DESC);
CREATE INDEX idx_match_points_live ON match_points (match_id, sequence DESC)
  WHERE voided_at IS NULL;

CREATE TABLE match_substitutions (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id           uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  match_team_id      uuid NOT NULL REFERENCES match_teams(id) ON DELETE CASCADE,
  slot               smallint NOT NULL CHECK (slot IN (1, 2)),
  out_participant_id uuid NOT NULL REFERENCES session_participants(id),
  in_participant_id  uuid NOT NULL REFERENCES session_participants(id),
  at_sequence        integer,
  created_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT subs_different_players CHECK (out_participant_id <> in_participant_id)
);
CREATE INDEX idx_subs_match ON match_substitutions (match_id);

-- =============================================================================
-- 5. KLASEMEN & STATISTIK
-- =============================================================================

CREATE TABLE session_standings (
  session_id     uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  participant_id uuid NOT NULL REFERENCES session_participants(id) ON DELETE CASCADE,
  points         integer NOT NULL DEFAULT 0,
  wins           integer NOT NULL DEFAULT 0,
  losses         integer NOT NULL DEFAULT 0,
  draws          integer NOT NULL DEFAULT 0,
  matches_played integer NOT NULL DEFAULT 0,
  games_won      integer NOT NULL DEFAULT 0,
  games_lost     integer NOT NULL DEFAULT 0,
  win_rate       numeric(5,2) GENERATED ALWAYS AS (
                   CASE WHEN matches_played = 0 THEN 0
                        ELSE ROUND(wins * 100.0 / matches_played, 2) END
                 ) STORED,
  rank           integer,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (session_id, participant_id)
);
CREATE INDEX idx_standings_rank ON session_standings (session_id, rank);

CREATE TABLE player_stats (
  player_id       uuid PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  sessions_played integer NOT NULL DEFAULT 0,
  matches_played  integer NOT NULL DEFAULT 0,
  matches_won     integer NOT NULL DEFAULT 0,
  matches_lost    integer NOT NULL DEFAULT 0,
  total_points    integer NOT NULL DEFAULT 0,
  win_rate        numeric(5,2) GENERATED ALWAYS AS (
                    CASE WHEN matches_played = 0 THEN 0
                         ELSE ROUND(matches_won * 100.0 / matches_played, 2) END
                  ) STORED,
  last_played_at  timestamptz,
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 6. INTEGRASI & SHARING
-- =============================================================================

CREATE TABLE reclub_imports (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id             uuid REFERENCES sessions(id) ON DELETE SET NULL,
  requested_by_player_id uuid REFERENCES players(id) ON DELETE SET NULL,
  match_code             text NOT NULL,
  status                 import_status NOT NULL DEFAULT 'pending',
  imported_count         integer NOT NULL DEFAULT 0,
  error_message          text,
  raw_response           jsonb,
  created_at             timestamptz NOT NULL DEFAULT now(),
  completed_at           timestamptz
);
CREATE INDEX idx_reclub_imports_code    ON reclub_imports (match_code);
CREATE INDEX idx_reclub_imports_session ON reclub_imports (session_id);

CREATE TABLE share_links (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token                text NOT NULL UNIQUE,
  resource_type        share_resource NOT NULL,
  session_id           uuid REFERENCES sessions(id) ON DELETE CASCADE,
  match_id             uuid REFERENCES matches(id) ON DELETE CASCADE,
  access               share_access NOT NULL DEFAULT 'view',
  created_by_player_id uuid REFERENCES players(id) ON DELETE SET NULL,
  expires_at           timestamptz,
  revoked_at           timestamptz,
  view_count           integer NOT NULL DEFAULT 0,
  created_at           timestamptz NOT NULL DEFAULT now(),
  -- Tepat satu target resource yang terisi.
  CONSTRAINT share_links_one_target CHECK (
    (resource_type IN ('session', 'leaderboard') AND session_id IS NOT NULL AND match_id IS NULL)
    OR
    (resource_type = 'match' AND match_id IS NOT NULL)
  )
);
CREATE INDEX idx_share_links_session ON share_links (session_id)
  WHERE revoked_at IS NULL;

-- =============================================================================
-- 7. VIEW BANTU
-- =============================================================================

-- Ringkasan sesi untuk sessions_screen (tab Active / Past).
CREATE VIEW v_session_summaries AS
SELECT
  s.id,
  s.name,
  s.icon,
  s.status,
  s.scheduled_date,
  mt.label                       AS match_type_label,
  c.name                         AS club_name,
  COUNT(sp.id) FILTER (WHERE sp.status <> 'withdrawn') AS player_count
FROM sessions s
JOIN match_types mt ON mt.code = s.match_type_code
LEFT JOIN clubs c ON c.id = s.club_id
LEFT JOIN session_participants sp ON sp.session_id = s.id
GROUP BY s.id, mt.label, c.name;

-- State live tiap court untuk kotc_screen.
CREATE VIEW v_live_courts AS
SELECT
  r.session_id,
  r.round_number,
  co.court_number,
  m.id AS match_id,
  m.status,
  m.games_a,
  m.games_b,
  m.points_a,
  m.points_b,
  m.serving_team
FROM matches m
JOIN rounds r  ON r.id = m.round_id
JOIN courts co ON co.id = m.court_id;
