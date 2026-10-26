# seerr-cli

[seerr-cli](https://github.com/robloach/seerr-cli) is a command-line client for [Seerr](https://docs.seerr.dev), the media request manager. Search for movies and TV shows, make and approve requests, and manage issues from your terminal.

```console
$ seerr search "The Matrix"
TYPE    ID     TITLE                     YEAR  STATUS
movie   603    The Matrix                1999  available
movie   604    The Matrix Reloaded       2003  -
person  6384   Keanu Reeves              -     -

$ seerr request create movie "The Matrix Reloaded"
Requested The Matrix Reloaded (2003) as request #12 (pending)
```

## Requirements

- Bash 4.2+ (macOS comes with Bash 3.2; install a newer one with `brew install bash`)
- `curl` or `wget`
- [`jq`](https://jqlang.org)

## Installation

Download [`seerr`](https://github.com/robloach/seerr-cli/blob/HEAD/seerr) from GitHub into a folder on your `PATH`, such as `~/.local/bin`:

```bash
curl -fsSL --create-dirs -o ~/.local/bin/seerr https://raw.githubusercontent.com/robloach/seerr-cli/HEAD/seerr
chmod +x ~/.local/bin/seerr
```

Or clone the repository, which also gets you the [AI agent skill](#ai-agents):

```bash
git clone https://github.com/robloach/seerr-cli.git
install -m 755 seerr-cli/seerr ~/.local/bin/seerr
```

Or use your AI Agent to install it:

```md
Install seerr-cli and its Agent Skill by following the README at https://github.com/robloach/seerr-cli
```

## Configuration

Create a `seerr-cli.yaml` configuration file in `~/.config/seerr-cli.yaml`, following the example in [`.seerr-cli.example.yaml`](.seerr-cli.example.yaml):

```yaml
url: https://seerr.example.com
api_key: YOUR_API_KEY
```

Alternatively, you can set it by using seerr yourself:
```bash
seerr config set url https://seerr.example.com
seerr config set api_key
```

The configuration can be found in the following paths:

1. `~/.config/seerr/seerr-cli.yaml`
2. `~/.config/seerr-cli.yaml`
3. `~/.seerr-cli.yaml`

When `XDG_CONFIG_HOME` is set, it replaces `~/.config` in the first two paths.

### Environment Variables

These can be set with environment variables, or command-line parameters:

| Setting | Flag | Environment variable | Config key |
|---|---|---|---|
| Server URL | `-u`, `--url` | `SEERR_URL` | `url` |
| API key | `-k`, `--api-key` | `SEERR_API_KEY` | `api_key` |
| Config file | `-c`, `--config` | `SEERR_CONFIG` | |
| Request timeout | | `SEERR_TIMEOUT` | `timeout` (seconds, default 30) |
| HTTP client | | `SEERR_HTTP_CLIENT` | `http_client` (`curl` or `wget`) |

The `--url`, `--api-key`, and `--config` flags go before the command:

```bash
seerr -u https://seerr.example.com -k YOUR_API_KEY status
```

### Verification

Verify the settings with `seerr config show`:

```console
$ seerr config show
Config file:  /path/to/seerr-cli.yaml
URL:          https://seerr.example.com
API key:      abcd...wxyz
Timeout:      30s
HTTP client:  curl
```

If the config file is missing or has a bad value, `seerr config show` still shows the settings, then says what's wrong.

## Usage

Run `seerr --help`, or `seerr COMMAND --help` for any command, to see all options.

### Search and browse

```bash
seerr search "Star Trek"                # movies, TV shows, and people
seerr search "Star Trek" --page 2
seerr trending --type tv --window week
seerr movie "The Matrix"                # movie details
seerr movie 603                         # the same movie, by TMDB ID
seerr tv "Game of Thrones"              # show details and season availability
seerr tv "Game of Thrones" --season 1   # episode list
seerr movie Dune --year 1984            # pick a release year
```

`seerr movie`, `seerr tv`, `seerr request create`, and `seerr issue create` take either a TMDB ID or a title. For a title, `seerr` searches and picks a result:

- A result with exactly the title you typed wins over the first result, so `Dune` finds *Dune*, not *Dune: Part Two*.
- Little-known results are skipped: an exact match needs at least a tenth as many votes as the most popular result. `Matrix` still finds *The Matrix*, not an obscure film called *Matrix*.
- If several popular results have exactly that title, such as the 1984 and 2021 versions of *Dune*, `seerr` lists them and asks which one you mean. It only asks in a terminal; in scripts and pipes it uses the first one.
- `--year` keeps only results from that release year. `seerr` looks through the first three pages of search results for a match.
- A number on its own is treated as a TMDB ID. To look up a movie named with a number, add `--year`: `seerr movie 1917 --year 2019`.

### Requests

```bash
seerr request list                      # most recent requests
seerr request list --filter pending
seerr request list --type tv --take 50 --page 2
seerr request get 12

seerr request create movie "The Matrix"
seerr request create movie 603 --4k
seerr request create tv "Game of Thrones"               # all seasons
seerr request create tv "Game of Thrones" --seasons 1,2

seerr request approve 12
seerr request decline 12
seerr request retry 12
seerr request delete 12
seerr request count
```

Request IDs come from `seerr request list`. List commands show 20 results per page; use `--page` to see more, and `--take` to change the page size.

### Media, issues, and users

```bash
seerr media list --filter available
seerr issue list                        # open issues
seerr issue list --filter all
seerr issue get 3                       # details and comments
seerr issue create movie "The Matrix" "Audio is out of sync" --problem audio
seerr issue create tv "Game of Thrones" "No subtitles" --problem subtitles --season 1 --episode 4
seerr issue comment 3 "Replaced the file, should be fixed now"
seerr issue resolve 3
seerr issue reopen 3
seerr user list
seerr user get 1
seerr whoami                            # the user your API key belongs to
seerr status                            # server version and update status
```

`--problem` is one of `video`, `audio`, `subtitles`, or `other` (the default). You can only report issues for media that has been requested in Seerr.

### Any other endpoint

The [Seerr API](https://docs.seerr.dev/api/seerr-api/) has far more endpoints than these commands cover. `seerr api` sends a request to any of them and prints the JSON response:

```bash
seerr api GET /settings/about
seerr api GET "/discover/movies?genre=18&page=2"
seerr api POST /settings/jobs/plex-recently-added-scan/run
seerr api PUT /user/2 --data '{"username": "alice"}'
seerr api PUT /user/2 --data @user.json
echo '{"username": "alice"}' | seerr api PUT /user/2 --data -
```

Paths are relative to `/api/v1`.

## Output and scripting

Commands print aligned tables. Add `--json` (or `-j`) to get the API response as JSON instead, for use with `jq`:

```bash
# Approve every pending movie request. --take 1000 gets them all,
# not just the first page of 20.
seerr request list --filter pending --type movie --take 1000 --json \
  | jq -r '.results[].id' \
  | xargs -n1 seerr request approve
```

The API returns only TMDB IDs for requests, media, and issues. To show titles, these tables make one extra API call per title, 8 at a time, so large lists take longer. `--json` skips those calls.

Errors go to stderr, and `seerr` exits with status 1 on any failure: bad arguments, a server that can't be reached, an HTTP error response, or a response that isn't JSON (for example, a proxy's login page).

Requests time out after 30 seconds. Change that with `SEERR_TIMEOUT` or `seerr config set timeout SECONDS`. With curl, that limit covers the whole request. With wget, it applies to each wait for the server, such as connecting or the next part of the response, so a slow response can take longer. A request that fails is never retried, so a slow server can't cause a request to be created twice.

## AI agents

[`skills/seerr`](skills/seerr/SKILL.md) is an [Agent Skill](https://agentskills.io) that teaches AI agents how to use `seerr`: how to find a title and its ID, what the status codes mean, and how to request, approve, and report problems. It tells agents to ask you before changing anything on your server, and never to read your API key.

```
Install the SKILL in this repository: https://github.com/robloach/seerr-cli
```

## Tab Completion (Optional)

To get tab completion, add one of these lines to your shell's startup file:

```bash
source <(seerr completions bash)  # ~/.bashrc
source <(seerr completions zsh)   # ~/.zshrc, after compinit
```

## Development

`seerr` is generated by [Bashly](https://bashly.dev). Don't edit the `seerr` script directly; edit the files in `src/` and regenerate it.

```
.github/workflows/    CI: runs the checks below on every push and pull request
settings.yml          Bashly settings; turns on shell completions
skills/seerr/         Agent Skill for AI agents
src/
  bashly.yml          commands, flags, and arguments
  bashly-strings.yml  changes to Bashly's built-in messages
  before.sh           runs before every command; resolves settings
  *_command.sh        one file per command
  lib/
    config.sh         reads flags, environment variables, and the config file,
                      and writes the config file
    http.sh           sends requests with curl or wget
    lookup.sh         turns a title into a TMDB ID
    output.sh         renders tables and JSON
    titles.sh         looks up titles for TMDB IDs
    yaml.sh           Bashly's YAML library
    validations/      argument validators
test/
  approve             the tests
  approvals/          approved output for each test
  fixtures/           API responses the tests use instead of a Seerr server
  approvals.bash      the approvals.bash test library, v0.5.1
```

Regenerate the script, check it with [ShellCheck](https://www.shellcheck.net), and run the tests:

```bash
bashly generate   # settings.yml makes this the production build
shellcheck seerr test/approve
test/approve
```

Check the generated `seerr` script rather than the files in `src/`. It contains all of them, so ShellCheck can see variables that one file sets and another uses. CI fails if the committed `seerr` doesn't match what `bashly generate` makes from `src/`.

The tests don't need a Seerr server. They load `seerr` and answer its API requests from `test/fixtures/`, so the curl and wget code in `http.sh` isn't tested. Each test runs a `seerr` command and compares its output with the approved output in `test/approvals/`. When the output is new or has changed, you see the difference and are asked whether to approve it. Commit the approved files along with your change. `AUTO_APPROVE=1 test/approve` approves everything, so review the changes in `test/approvals/` afterwards.

## License

[MIT](LICENSE)
