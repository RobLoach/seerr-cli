# seerr reference

## Commands

| Command | Does | Notable options |
|---|---|---|
| `status` | Server version and update status | |
| `whoami` | The user the API key belongs to | |
| `search QUERY` | Movies, TV shows, and people | `--page`, `--language` |
| `trending` | Trending titles | `--type all\|movie\|tv`, `--window day\|week`, `--page` |
| `movie TITLE_OR_ID` | Movie details and availability | `--year` |
| `tv TITLE_OR_ID` | Show details and per-season availability | `--season N` (episode list), `--year` |
| `request list` | Requests, newest first | `--filter`, `--type movie\|tv\|all`, `--sort added\|modified`, `--user ID`, `--page`, `--take` |
| `request get ID` | One request | |
| `request create movie\|tv TITLE_OR_ID` | Request a title | `--seasons 1,2\|all` (TV), `--4k`, `--year` |
| `request approve\|decline\|retry\|delete ID` | Act on a request | |
| `request count` | Counts by type and status | |
| `media list` | Media Seerr tracks | `--filter`, `--sort added\|modified\|mediaAdded`, `--page`, `--take` |
| `issue list` | Issues (open by default) | `--filter open\|resolved\|all`, `--page`, `--take` |
| `issue create movie\|tv TITLE_OR_ID MESSAGE` | Report a problem | `--problem video\|audio\|subtitles\|other`, `--season N`, `--episode N`, `--year` |
| `issue get\|resolve\|reopen ID` | One issue | |
| `issue comment ID MESSAGE` | Comment on an issue | |
| `user list`, `user get ID` | Users | `--sort`, `--page`, `--take` |
| `config show` | Settings in effect (API key masked) | |
| `config set KEY [VALUE]` | Save a setting | `KEY` is `url`, `api_key`, `timeout`, or `http_client` |
| `api METHOD PATH` | Any API endpoint | `--data JSON\|@FILE\|-` |

Every command takes `--json` except `request delete`, `config`, `completions`, and `api` (which always prints JSON). List commands return 20 results per page by default.

`request list --filter` takes `all`, `pending`, `approved`, `processing`, `available`, `unavailable`, `failed`, `deleted`, or `completed`. `media list --filter` takes `all`, `available`, `partial`, `allavailable`, `processing`, `pending`, or `deleted`.

## Status codes

Tables show names. JSON has numbers.

| `status` on a request | Meaning |
|---|---|
| 1 | pending, waiting for approval |
| 2 | approved |
| 3 | declined |
| 4 | failed |
| 5 | completed |

| `status` or `status4k` on media (`mediaInfo`, `media`) | Meaning |
|---|---|
| 1 | unknown, which usually means never requested |
| 2 | pending |
| 3 | processing, which means requested and downloading |
| 4 | partially available, for example some seasons |
| 5 | available |
| 6 | blocklisted |
| 7 | deleted |

No `mediaInfo` at all means Seerr has never seen the title: nobody has requested it, and it isn't in the library.

| Issue `issueType` | | Issue `status` | |
|---|---|---|---|
| 1 | video | 1 | open |
| 2 | audio | 2 | resolved |
| 3 | subtitles | | |
| 4 | other | | |

## JSON fields

`search` and `trending`:

```json
{"page": 1, "totalPages": 65, "totalResults": 1294,
 "results": [{"mediaType": "movie", "id": 438631, "title": "Dune", "releaseDate": "2021-09-15",
              "mediaInfo": {"status": 5, "status4k": 1}}]}
```

TV results use `name` and `firstAirDate` instead of `title` and `releaseDate`. Person results have `mediaType: "person"`. `id` is the TMDB ID.

`request list`, `media list`, `issue list`, and `user list`:

```json
{"pageInfo": {"page": 1, "pages": 6, "pageSize": 20, "results": 112},
 "results": [{"id": 6, "status": 2, "type": "movie", "is4k": false, "createdAt": "2026-10-21T18:07:54.000Z",
              "media": {"id": 806, "mediaType": "movie", "tmdbId": 1400837, "status": 3, "status4k": 1},
              "requestedBy": {"id": 1, "displayName": "Rob"}}]}
```

Requests and issues don't include the title. Get it with `seerr movie TMDB_ID --json | jq -r .title`, or `.name` for TV. Or read the table output, which looks titles up for you.

`tv ID --json` has per-season availability in `.mediaInfo.seasons[] | {seasonNumber, status}`.

## Errors

- Exit status is 0 on success and 1 on any failure. The message is on stderr and starts with `seerr:`.
- HTTP 401 or 403 means the API key is wrong or lacks permission. Tell the user; don't try to fix the key.
- "did not answer with JSON" means the URL points at something other than Seerr, such as a proxy login page.
- Requests time out after 30 seconds. The user can raise this with `SEERR_TIMEOUT` or `seerr config set timeout SECONDS`.
