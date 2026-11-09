# fifa-db

Schema-only SQLite database for the football stats app. No application code and no data.

## Create the database from scratch

Requires `sqlite3` (3.25+).

```bash
scripts/create_db.sh                 # creates ./fifa.sqlite3
scripts/create_db.sh /path/to/x.db   # or choose a path
```

or manually:

```bash
sqlite3 fifa.sqlite3 < schema.sql
```

The script refuses to overwrite an existing file.

## Connect with DBeaver

New Database Connection → SQLite → Path: the `fifa.sqlite3` file → Finish.

## Layout

| Path | What |
|---|---|
| `schema.sql` | All tables, constraints and indexes, in dependency order |
| `scripts/create_db.sh` | Builds an empty DB from `schema.sql` |
| `docs/ENUMS.md` | Allowed values for the choice columns |

## Tables

- Lookups: `stats_competition`, `stats_season`, `stats_team`, `stats_opponent`, `stats_player`, `stats_award`
- Matches: `stats_match`, `stats_appearance` (per-player goals/assists in a match)
- Season totals: `stats_seasonstat`, `stats_seasonstatcompetition`
- Squads/honours/market: `stats_squadentry`, `stats_clubtitle`, `stats_individualtitle`, `stats_transfer`

Foreign keys are enforced only when `PRAGMA foreign_keys = ON` is set per connection (DBeaver's SQLite driver sets it by default).
