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

## Example queries

Run them in DBeaver or with `sqlite3 fifa.sqlite3`. Every query below was tested against a populated copy of the database.

### How the model fits together

- A `stats_player` is tracked in one of two ways (`tracking_type`):
  - `DETAILED`: one `stats_appearance` row per match (goals and assists in that match).
  - `SUMMARY`: season totals in `stats_seasonstat`, split by competition in `stats_seasonstatcompetition`.
- `stats_match` stores the result from our side: `our_goals` vs `their_goals`, for `team_id` against `opponent_id`.
- `stats_opponent` also serves as the counterparty of a transfer (`stats_transfer.counterparty_id`).
  `counterparty_club` is a free-text fallback and can be empty, so read the club name with `COALESCE`.

### Results

Record per season and team:

```sql
SELECT s.label AS season, t.name AS team, COUNT(*) AS played,
       SUM(m.our_goals >  m.their_goals) AS wins,
       SUM(m.our_goals =  m.their_goals) AS draws,
       SUM(m.our_goals <  m.their_goals) AS losses
FROM stats_match m
JOIN stats_season s ON s.id = m.season_id
JOIN stats_team   t ON t.id = m.team_id
WHERE m.our_goals IS NOT NULL AND m.their_goals IS NOT NULL
GROUP BY s.id, t.id
ORDER BY s.start_year, t.name;
```

Head-to-head record against opponents faced at least 3 times:

```sql
SELECT o.name AS opponent, COUNT(*) AS played,
       SUM(m.our_goals > m.their_goals) AS w,
       SUM(m.our_goals = m.their_goals) AS d,
       SUM(m.our_goals < m.their_goals) AS l
FROM stats_match m
JOIN stats_opponent o ON o.id = m.opponent_id
WHERE m.our_goals IS NOT NULL
GROUP BY o.id
HAVING played >= 3
ORDER BY played DESC;
```

### Scorers

Top scorers from per-match data (`DETAILED` players only):

```sql
SELECT p.name, SUM(a.goals) AS goals, SUM(a.assists) AS assists
FROM stats_appearance a
JOIN stats_player p ON p.id = a.player_id
GROUP BY p.id
ORDER BY goals DESC, assists DESC
LIMIT 10;
```

Career totals for every player, combining both tracking types:

```sql
SELECT name, SUM(goals) AS goals, SUM(assists) AS assists
FROM (
    SELECT p.id, p.name, a.goals, a.assists
    FROM stats_appearance a
    JOIN stats_player p ON p.id = a.player_id
    UNION ALL
    SELECT p.id, p.name, c.goals, c.assists
    FROM stats_seasonstatcompetition c
    JOIN stats_seasonstat ss ON ss.id = c.season_stat_id
    JOIN stats_player p      ON p.id  = ss.player_id
)
GROUP BY id
ORDER BY goals DESC;
```

Goals by stage of the competition:

```sql
SELECT m.stage, SUM(a.goals) AS goals
FROM stats_appearance a
JOIN stats_match m ON m.id = a.match_id
GROUP BY m.stage
ORDER BY goals DESC;
```

One `SUMMARY` player, season by season and competition by competition:

```sql
SELECT s.label AS season, comp.name AS competition, c.matches, c.goals, c.assists
FROM stats_seasonstatcompetition c
JOIN stats_seasonstat    ss   ON ss.id   = c.season_stat_id
JOIN stats_season        s    ON s.id    = ss.season_id
JOIN stats_competition   comp ON comp.id = c.competition_id
JOIN stats_player        p    ON p.id    = ss.player_id
WHERE p.name = 'Lamine Yamal'          -- change the name
ORDER BY s.start_year, comp.name;
```

### Squads

Squad of a season, starters first:

```sql
SELECT p.name, p.position, se.role
FROM stats_squadentry se
JOIN stats_player p ON p.id = se.player_id
JOIN stats_season s ON s.id = se.season_id
JOIN stats_team   t ON t.id = se.team_id
WHERE s.label = '2026-2027'            -- change the season
  AND t.kind  = 'MAIN_CLUB'
ORDER BY CASE se.role WHEN 'STARTER' THEN 1 WHEN 'SUBSTITUTE' THEN 2 ELSE 3 END,
         p.position;
```

### Titles

Club titles per team and competition:

```sql
SELECT t.name AS team, comp.name AS competition, COUNT(*) AS titles
FROM stats_clubtitle ct
JOIN stats_team        t    ON t.id    = ct.team_id
JOIN stats_competition comp ON comp.id = ct.competition_id
GROUP BY t.id, comp.id
ORDER BY titles DESC;
```

Individual awards per player:

```sql
SELECT p.name AS player, COUNT(*) AS awards
FROM stats_individualtitle it
JOIN stats_player p ON p.id = it.player_id
GROUP BY p.id
ORDER BY awards DESC;
```

An award can be tied to a competition (for example a top-scorer award of one league), so list each award with its scope:

```sql
SELECT a.name AS award, COALESCE(c.name, '(any competition)') AS competition,
       COUNT(it.id) AS times_won
FROM stats_award a
LEFT JOIN stats_competition     c  ON c.id = a.competition_id
LEFT JOIN stats_individualtitle it ON it.award_id = a.id
GROUP BY a.id
ORDER BY times_won DESC;
```

### Transfers

Spending and income per season (amounts are in the unit you entered them in):

```sql
SELECT s.label AS season,
       COALESCE(SUM(CASE WHEN tr.direction = 'IN'  THEN tr.amount END), 0) AS spent,
       COALESCE(SUM(CASE WHEN tr.direction = 'OUT' THEN tr.amount END), 0) AS earned
FROM stats_transfer tr
JOIN stats_season s ON s.id = tr.season_id
GROUP BY s.id
ORDER BY s.start_year;
```

Most expensive signings, with the selling club:

```sql
SELECT p.name, s.label AS season,
       COALESCE(o.name, NULLIF(tr.counterparty_club, '')) AS club, tr.amount
FROM stats_transfer tr
JOIN stats_player p ON p.id = tr.player_id
JOIN stats_season s ON s.id = tr.season_id
LEFT JOIN stats_opponent o ON o.id = tr.counterparty_id
WHERE tr.direction = 'IN' AND tr.operation = 'BUY' AND tr.amount IS NOT NULL
ORDER BY tr.amount DESC
LIMIT 10;
```

Loans and their returns:

```sql
SELECT p.name, s.label AS season, tr.direction, tr.operation,
       COALESCE(o.name, NULLIF(tr.counterparty_club, '')) AS club
FROM stats_transfer tr
JOIN stats_player p ON p.id = tr.player_id
JOIN stats_season s ON s.id = tr.season_id
LEFT JOIN stats_opponent o ON o.id = tr.counterparty_id
WHERE tr.operation IN ('LOAN', 'LOAN_END')
ORDER BY s.start_year, p.name;
```

Players who never arrived by a transfer (for example, came through the academy):

```sql
SELECT p.name
FROM stats_player p
WHERE NOT EXISTS (
    SELECT 1 FROM stats_transfer t
    WHERE t.player_id = p.id AND t.direction = 'IN'
);
```

### Data-quality checks

Matches without a final score:

```sql
SELECT COUNT(*) AS pending
FROM stats_match
WHERE our_goals IS NULL OR their_goals IS NULL;
```

Matches where the scorers' goals exceed the team's goals (own goals or a typo; worth reviewing):

```sql
SELECT m.id, m.date, m.our_goals, SUM(a.goals) AS scorers_goals
FROM stats_match m
JOIN stats_appearance a ON a.match_id = m.id
GROUP BY m.id
HAVING scorers_goals > m.our_goals;
```
