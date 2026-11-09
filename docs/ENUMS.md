# Valid values for choice columns

The schema stores these as plain `VARCHAR` with no `CHECK`, so the application is responsible for validating them.

| Column | Values |
|---|---|
| `stats_team.kind` | `MAIN_CLUB`, `EXTERNAL_CLUB`, `NATIONAL_TEAM` |
| `stats_opponent.kind` | `CLUB`, `NATIONAL_TEAM` |
| `stats_player.tracking_type` | `DETAILED` (per match), `SUMMARY` (season totals) |
| `stats_player.position` | `GK`, `CB`, `LB`, `RB`, `LWB`, `RWB`, `CDM`, `CM`, `CAM`, `LM`, `RM`, `LW`, `RW`, `SS`, `ST` |
| `stats_match.stage` | `GROUP`, `R32`, `R16`, `QF`, `SF`, `FINAL`, `LEAGUE` (may be empty) |
| `stats_match.venue` | `HOME`, `AWAY`, `NEUTRAL` (may be empty) |
| `stats_squadentry.role` | `STARTER`, `SUBSTITUTE`, `RESERVE` |
| `stats_transfer.direction` | `IN`, `OUT` |
| `stats_transfer.market` | `SUMMER`, `WINTER` |
| `stats_transfer.operation` | `BUY`, `LOAN`, `LOAN_END`, `FREE`, `CLAUSE`, `ACADEMY` |
