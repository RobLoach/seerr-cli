---
name: seerr
description: Searches a Seerr media server for movies and TV shows, requests them, checks whether they're available, approves or declines requests, and reports playback issues, using the seerr command-line tool. Use when the user wants to find, request, or check on a movie or TV show, manage media requests or issues on their media server, or mentions Seerr, Overseerr, or Jellyseerr.
license: MIT
compatibility: Requires the seerr CLI from https://github.com/robloach/seerr-cli (Bash 4.2+, curl or wget, and jq) and network access to a Seerr server.
metadata:
  author: Rob Loach
  version: "0.1.0"
allowed-tools: Bash(seerr status:*) Bash(seerr whoami:*) Bash(seerr search:*) Bash(seerr trending:*) Bash(seerr movie:*) Bash(seerr tv:*) Bash(seerr request list:*) Bash(seerr request get:*) Bash(seerr request count:*) Bash(seerr media list:*) Bash(seerr issue list:*) Bash(seerr issue get:*) Bash(seerr user list:*) Bash(seerr user get:*) Bash(seerr config show:*)
---

# Seerr

`seerr` is a command-line client for a [Seerr](https://docs.seerr.dev) server, from [github.com/robloach/seerr-cli](https://github.com/robloach/seerr-cli). Run `seerr --help` or `seerr COMMAND --help` for every flag.

## Before you start

1. Run `command -v seerr`. If it prints nothing, follow [Install seerr](#install-seerr) below.
2. Run `seerr config show`. If the URL or API key says "not set", ask the user to run `seerr config set url URL` and `seerr config set api_key` themselves. If it ends with an error about the config file, tell the user what it says. Never ask for, print, or read the API key or the config file.
3. Run `seerr status` to check that the server answers.

## Rules

- **Ask before changing anything.** Get the user's go-ahead before `request create`, `approve`, `decline`, `retry`, or `delete`; `issue create`, `comment`, `resolve`, or `reopen`; `config set`; and `seerr api` with POST, PUT, PATCH, or DELETE. Reading is always fine.
- **Use IDs for changes, not titles.** Commands accept a title, but without a terminal they pick a match silently, which may not be the one the user means. Search, confirm the match with the user, then pass its TMDB ID.
- **Read with `--json`, show with tables.** Add `--json` and parse with `jq` when you need data. Leave it off when the user just wants to see a list; tables include titles, but JSON only has TMDB IDs.
- **Don't retry a failed change.** Exit status 1 means it failed, and the reason is on stderr. If a request may have gone through anyway, check `seerr request list` before trying again.
- **Know which ID is which.** TMDB IDs identify a title (`search`, `movie`, `tv`, `request create`, `issue create`). `movie`, `tv`, `request create`, and `issue create` also take an IMDb ID (`tt...`) or imdb.com URL in place of a TMDB ID; `seerr search --imdb ID` or `--tvdb ID` shows what it matches. Request IDs and issue IDs identify one request or issue (`request get|approve|...`, `issue get|comment|...`). `media list` shows Seerr's own media IDs, which no other command takes.
- `-u`, `-k`, and `-c` go before the command: `seerr -c FILE request list`.

## Workflows

### Request a movie or TV show

1. Search: `seerr search "TITLE" --json | jq '.results[] | select(.mediaType != "person") | {mediaType, id, title: (.title // .name), date: (.releaseDate // .firstAirDate), status: .mediaInfo.status}'`
2. If more than one result could be what the user means, list them with years and ask.
3. Check `status`. 5 means it's already available, and 2 or 3 means it's already requested, so tell the user instead of requesting again. 4 means partly available, which is common for TV.
4. For TV, ask which seasons if the user didn't say. `seerr tv ID` shows each season's status.
5. After the user confirms, run `seerr request create movie ID`, or `seerr request create tv ID --seasons 1,2`. Leaving out `--seasons` requests every season except specials (season 0). Seerr skips seasons that are already requested or available, and if none are left, the command fails with "no request created: No seasons available to request". Add `--4k` only if asked.

### Check on something

- Is it available? `seerr movie ID` or `seerr tv ID`. Status names are listed in [REFERENCE.md](REFERENCE.md#status-codes).
- My requests: `seerr request list`. Add `--filter pending` or another status to narrow it.
- Counts by status: `seerr request count`.

### Review pending requests

1. `seerr request list --filter pending` shows the ID, title, type, and who asked.
2. Show the list to the user, and ask which to approve or decline.
3. Run `seerr request approve ID` or `seerr request decline ID` for each one confirmed.

### Report a problem with something

1. Find the TMDB ID as when requesting. Issues only work for titles that are in Seerr: `seerr movie ID --json | jq .mediaInfo.id` must not be `null`.
2. After the user confirms the wording, run `seerr issue create movie ID "What's wrong" --problem audio`. `--problem` is `video`, `audio`, `subtitles`, or `other`. For TV, add `--season N`, and optionally `--episode N`.
3. Follow up with `seerr issue list`, `seerr issue get ID`, `seerr issue comment ID "text"`, or `seerr issue resolve ID`.

### Anything else

`seerr api METHOD /path` calls any [Seerr API](https://docs.seerr.dev/api/seerr-api/) endpoint and prints JSON. Paths are relative to `/api/v1`, for example `seerr api GET /settings/about`. Send a body with `--data '{"key": "value"}'`.

## Reference

[REFERENCE.md](REFERENCE.md) lists every command, the status codes found in JSON, and the JSON fields you'll need most.

## Install seerr

Installing changes the user's machine, so ask first, and only continue with a yes.

1. Check the requirements: `bash --version` must show 4.2 or newer, and `command -v jq` plus `command -v curl` or `command -v wget` must each print a path. If something is missing, tell the user what and how to get it, such as `sudo apt install jq` or `brew install jq`. Don't run a package manager yourself.
2. Download the script into `~/.local/bin`:

   ```bash
   curl -fsSL --create-dirs -o ~/.local/bin/seerr https://raw.githubusercontent.com/robloach/seerr-cli/HEAD/seerr
   chmod +x ~/.local/bin/seerr
   ```

   Without curl, use `mkdir -p ~/.local/bin && wget -qO ~/.local/bin/seerr URL` with the same URL, then the same `chmod`.
3. Run `seerr --version`. If the command isn't found, `~/.local/bin` isn't on `PATH`. Use `~/.local/bin/seerr` in its place for now, and tell the user to add `~/.local/bin` to their `PATH`.
4. Continue with [Before you start](#before-you-start). The user still has to set the URL and API key.
