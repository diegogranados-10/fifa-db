-- Football stats database schema (SQLite 3).
-- Tables are ordered so every foreign key points to a table defined above it.
-- Column values for "choice" columns are documented in docs/ENUMS.md.

PRAGMA foreign_keys = ON;

BEGIN;

-- ---------------------------------------------------------------- lookups

CREATE TABLE stats_competition (
    id   INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE stats_season (
    id         INTEGER          NOT NULL PRIMARY KEY AUTOINCREMENT,
    label      VARCHAR(9)       NOT NULL UNIQUE,
    start_year INTEGER UNSIGNED NOT NULL CHECK (start_year >= 0)
);

CREATE TABLE stats_team (
    id   INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(120) NOT NULL UNIQUE,
    kind VARCHAR(13)  NOT NULL
);

CREATE TABLE stats_opponent (
    id      INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    name    VARCHAR(120) NOT NULL UNIQUE,
    country VARCHAR(2)   NOT NULL,
    kind    VARCHAR(13)  NOT NULL
);

CREATE TABLE stats_player (
    id            INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    name          VARCHAR(120) NOT NULL,
    tracking_type VARCHAR(8)   NOT NULL,
    position      VARCHAR(3)   NOT NULL
);

CREATE TABLE stats_award (
    id             INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    name           VARCHAR(120) NOT NULL,
    competition_id BIGINT       NULL REFERENCES stats_competition (id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_award_name_competition UNIQUE (name, competition_id)
);
CREATE INDEX stats_award_competition_id_a1a3c327 ON stats_award (competition_id);
-- NULLs are distinct in a UNIQUE constraint, so awards with no competition need their own index.
CREATE UNIQUE INDEX unique_award_name_without_competition ON stats_award (name) WHERE competition_id IS NULL;

-- ---------------------------------------------------------------- matches

CREATE TABLE stats_match (
    id             INTEGER          NOT NULL PRIMARY KEY AUTOINCREMENT,
    date           DATE             NOT NULL,
    stage          VARCHAR(6)       NOT NULL,
    venue          VARCHAR(7)       NOT NULL,
    our_goals      INTEGER UNSIGNED NULL CHECK (our_goals >= 0),
    their_goals    INTEGER UNSIGNED NULL CHECK (their_goals >= 0),
    competition_id BIGINT           NOT NULL REFERENCES stats_competition (id) DEFERRABLE INITIALLY DEFERRED,
    opponent_id    BIGINT           NULL     REFERENCES stats_opponent (id)    DEFERRABLE INITIALLY DEFERRED,
    season_id      BIGINT           NOT NULL REFERENCES stats_season (id)      DEFERRABLE INITIALLY DEFERRED,
    team_id        BIGINT           NOT NULL REFERENCES stats_team (id)        DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX stats_match_competition_id_e0a3ac83 ON stats_match (competition_id);
CREATE INDEX stats_match_opponent_id_1bee7eea    ON stats_match (opponent_id);
CREATE INDEX stats_match_season_id_f141925a      ON stats_match (season_id);
CREATE INDEX stats_match_team_id_693981d5        ON stats_match (team_id);

CREATE TABLE stats_appearance (
    id        INTEGER          NOT NULL PRIMARY KEY AUTOINCREMENT,
    goals     INTEGER UNSIGNED NOT NULL CHECK (goals >= 0),
    assists   INTEGER UNSIGNED NOT NULL CHECK (assists >= 0),
    player_id BIGINT           NOT NULL REFERENCES stats_player (id) DEFERRABLE INITIALLY DEFERRED,
    match_id  BIGINT           NOT NULL REFERENCES stats_match (id)  DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX stats_appearance_player_id_02035cee ON stats_appearance (player_id);
CREATE INDEX stats_appearance_match_id_ce11f128  ON stats_appearance (match_id);

-- ---------------------------------------------------------------- season totals

CREATE TABLE stats_seasonstat (
    id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    player_id BIGINT  NOT NULL REFERENCES stats_player (id) DEFERRABLE INITIALLY DEFERRED,
    season_id BIGINT  NOT NULL REFERENCES stats_season (id) DEFERRABLE INITIALLY DEFERRED,
    team_id   BIGINT  NOT NULL REFERENCES stats_team (id)   DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_season_stat UNIQUE (player_id, team_id, season_id)
);
CREATE INDEX stats_seasonstat_player_id_7352d957 ON stats_seasonstat (player_id);
CREATE INDEX stats_seasonstat_season_id_a8b3cede ON stats_seasonstat (season_id);
CREATE INDEX stats_seasonstat_team_id_b0b96f60   ON stats_seasonstat (team_id);

CREATE TABLE stats_seasonstatcompetition (
    id             INTEGER          NOT NULL PRIMARY KEY AUTOINCREMENT,
    matches        INTEGER UNSIGNED NOT NULL CHECK (matches >= 0),
    goals          INTEGER UNSIGNED NOT NULL CHECK (goals >= 0),
    assists        INTEGER UNSIGNED NOT NULL CHECK (assists >= 0),
    competition_id BIGINT           NOT NULL REFERENCES stats_competition (id) DEFERRABLE INITIALLY DEFERRED,
    season_stat_id BIGINT           NOT NULL REFERENCES stats_seasonstat (id)  DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX stats_seasonstatcompetition_competition_id_b4adbe61 ON stats_seasonstatcompetition (competition_id);
CREATE INDEX stats_seasonstatcompetition_season_stat_id_8f7cbd01 ON stats_seasonstatcompetition (season_stat_id);

-- ---------------------------------------------------------------- squads, titles, transfers

CREATE TABLE stats_squadentry (
    id        INTEGER     NOT NULL PRIMARY KEY AUTOINCREMENT,
    role      VARCHAR(10) NOT NULL,
    player_id BIGINT      NOT NULL REFERENCES stats_player (id) DEFERRABLE INITIALLY DEFERRED,
    season_id BIGINT      NOT NULL REFERENCES stats_season (id) DEFERRABLE INITIALLY DEFERRED,
    team_id   BIGINT      NOT NULL REFERENCES stats_team (id)   DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_squad_entry UNIQUE (team_id, season_id, player_id)
);
CREATE INDEX stats_squadentry_player_id_00c955ce ON stats_squadentry (player_id);
CREATE INDEX stats_squadentry_season_id_f93601b8 ON stats_squadentry (season_id);
CREATE INDEX stats_squadentry_team_id_41a62504   ON stats_squadentry (team_id);

CREATE TABLE stats_clubtitle (
    id             INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    competition_id BIGINT  NOT NULL REFERENCES stats_competition (id) DEFERRABLE INITIALLY DEFERRED,
    season_id      BIGINT  NOT NULL REFERENCES stats_season (id)      DEFERRABLE INITIALLY DEFERRED,
    team_id        BIGINT  NOT NULL REFERENCES stats_team (id)        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_club_title UNIQUE (team_id, season_id, competition_id)
);
CREATE INDEX stats_clubtitle_competition_id_e646e9c6 ON stats_clubtitle (competition_id);
CREATE INDEX stats_clubtitle_season_id_3055e820      ON stats_clubtitle (season_id);
CREATE INDEX stats_clubtitle_team_id_0f8fac2e        ON stats_clubtitle (team_id);

CREATE TABLE stats_individualtitle (
    id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    award_id  BIGINT  NOT NULL REFERENCES stats_award (id)  DEFERRABLE INITIALLY DEFERRED,
    player_id BIGINT  NOT NULL REFERENCES stats_player (id) DEFERRABLE INITIALLY DEFERRED,
    season_id BIGINT  NOT NULL REFERENCES stats_season (id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_individual_title UNIQUE (player_id, award_id, season_id)
);
CREATE INDEX stats_individualtitle_award_id_d2dd52c7  ON stats_individualtitle (award_id);
CREATE INDEX stats_individualtitle_player_id_fb426992 ON stats_individualtitle (player_id);
CREATE INDEX stats_individualtitle_season_id_42e11338 ON stats_individualtitle (season_id);

CREATE TABLE stats_transfer (
    id                INTEGER      NOT NULL PRIMARY KEY AUTOINCREMENT,
    direction         VARCHAR(3)   NOT NULL,
    market            VARCHAR(6)   NOT NULL,
    counterparty_club VARCHAR(120) NOT NULL,
    operation         VARCHAR(8)   NOT NULL,
    amount            DECIMAL      NULL,
    player_id         BIGINT       NOT NULL REFERENCES stats_player (id)   DEFERRABLE INITIALLY DEFERRED,
    season_id         BIGINT       NOT NULL REFERENCES stats_season (id)   DEFERRABLE INITIALLY DEFERRED,
    counterparty_id   BIGINT       NULL     REFERENCES stats_opponent (id) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX stats_transfer_player_id_3ce1fbd9       ON stats_transfer (player_id);
CREATE INDEX stats_transfer_season_id_3874eb14       ON stats_transfer (season_id);
CREATE INDEX stats_transfer_counterparty_id_a7d70cb0 ON stats_transfer (counterparty_id);

COMMIT;
