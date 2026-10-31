# seerr-cli

[seerr-cli](https://github.com/robloach/seerr-cli) is a command-line client for [Seerr](https://docs.seerr.dev), the media request manager. Search for movies and TV shows, and make requests directly from your terminal.

```console
$ seerr search Caminandes
TYPE   ID      TITLE                     YEAR  STATUS
movie  253777  Caminandes: Llama Drama   2013  available
movie  253774  Caminandes: Gran Dillama  2013  -
movie  406956  Caminandes: Llamigos      2016  -

$ seerr request create movie "Caminandes: Llamigos"
Requested Caminandes: Llamigos (2016) as request #12 (pending)
```

## Requirements

- Bash 4.2+
- `curl` or `wget`
- [`jq`](https://jqlang.org)

## Installation

Download [`seerr`](https://github.com/robloach/seerr-cli/blob/HEAD/seerr) into a folder on your `PATH`, such as `~/.local/bin`:

```bash
curl -fsSL --create-dirs -o ~/.local/bin/seerr https://raw.githubusercontent.com/robloach/seerr-cli/HEAD/seerr
chmod +x ~/.local/bin/seerr
```

Or by cloning the repository:

```bash
git clone https://github.com/robloach/seerr-cli.git
install -m 755 seerr-cli/seerr ~/.local/bin/seerr
```

## Configuration

Create a `seerr-cli.yaml` configuration file in `~/.config/seerr-cli.yaml`, following the example in [`.seerr-cli.example.yaml`](.seerr-cli.example.yaml):

```yaml
url: http://[address]:5055
api_key: YOUR_API_KEY
```

Alternatively, you can set it by using seerr yourself:
```bash
seerr config set url http://[address]:5055
seerr config set api_key
```

The configuration can be found in the following paths:

1. `~/.config/seerr/seerr-cli.yaml`
2. `~/.config/seerr-cli.yaml`
3. `~/.seerr-cli.yaml`

`XDG_CONFIG_HOME` is also considered above.

### Environment Variables

| Setting | Flag | Environment variable | Config key |
|---|---|---|---|
| Server URL | `-u`, `--url` | `SEERR_URL` | `url` |
| API key | `-k`, `--api-key` | `SEERR_API_KEY` | `api_key` |
| Config file | `-c`, `--config` | `SEERR_CONFIG` | |
| Request timeout | | `SEERR_TIMEOUT` | `timeout` (seconds, default 30) |
| HTTP client | | `SEERR_HTTP_CLIENT` | `http_client` (`curl` or `wget`) |

The `--url`, `--api-key`, and `--config` flags go before the command:

```bash
seerr -u http://seerr:5055 -k YOUR_API_KEY status
```

### Verification

Verify configuration with `seerr config show`:

```console
$ seerr config show
Config file:  /path/to/seerr-cli.yaml
URL:          https://seerr.example.com
API key:      abcd...wxyz
Timeout:      30s
HTTP client:  curl
```

## Usage

Run `seerr --help`, or `seerr COMMAND --help` for any command, to see all options.

### Search

```bash
seerr search Caminandes                 # movies, TV shows, and people
seerr search Caminandes --page 2
seerr trending --type tv --window week
seerr movie "Big Buck Bunny"            # movie details
seerr movie 10378                       # the same movie, by TMDB ID
seerr tv 6560                           # show details and season availability
seerr tv 6560 --season 1                # episode list
seerr tv "Sherlock Holmes" --year 1954  # pick a release year
```

`seerr movie`, `seerr tv`, `seerr request create`, and `seerr issue create` take either a TMDB ID or a title. For a title, `seerr` searches and picks a result:

- A result with exactly the title you typed wins over the first result, so `Sintel` finds *Sintel*, even if a longer title such as *Sintel: The Making Of* comes first.
- Little-known results are skipped: an exact match needs at least a tenth as many votes as the most popular result. If an obscure film were called *Bunny*, `Bunny` would still find *Big Buck Bunny*.
- If several popular results have exactly that title, such as two films from different years, `seerr` lists them and asks which one you mean. It only asks in a terminal; in scripts and pipes it uses the first one.
- `--year` keeps only results from that release year. `seerr` looks through the first three pages of search results for a match.
- A number on its own is treated as a TMDB ID. To look up a movie whose title is a number, add `--year`, and `seerr` searches for it as a title.

### Requests

```bash
seerr request list                      # most recent requests
seerr request list --filter pending
seerr request list --type tv --take 50 --page 2
seerr request get 12

seerr request create movie "Big Buck Bunny"
seerr request create movie 10378 --4k
seerr request create tv 6560                # all seasons
seerr request create tv 6560 --seasons 1

seerr request approve 12
seerr request decline 12
seerr request retry 12
seerr request delete 12
seerr request count
```

### Media, issues, and users

```bash
seerr media list --filter available
seerr issue list                        # open issues
seerr issue list --filter all
seerr issue get 3                       # details and comments
seerr issue create movie "Big Buck Bunny" "Audio is out of sync" --problem audio
seerr issue create tv 6560 "No subtitles" --problem subtitles --season 1 --episode 4
seerr issue comment 3 "Replaced the file, should be fixed now"
seerr issue resolve 3
seerr issue reopen 3
seerr user list
seerr user get 1
seerr whoami                            # the user your API key belongs to
seerr status                            # server version and update status
```

### Other endpoints

The [Seerr API](https://docs.seerr.dev/api/seerr-api/) has more endpoints. `seerr api` allows querying them and responding with JSON:

```bash
seerr api GET /settings/about
seerr api GET "/discover/movies?genre=18&page=2"
seerr api POST /settings/jobs/plex-recently-added-scan/run
seerr api PUT /user/2 --data '{"username": "alice"}'
seerr api PUT /user/2 --data @user.json
echo '{"username": "alice"}' | seerr api PUT /user/2 --data -
```

### JSON

Commands print aligned tables. Add `--json` (or `-j`) to get JSON, for use with `jq`:

```bash
# Approve every pending movie request.
seerr request list --filter pending --type movie --json \
  | jq -r '.results[].id' \
  | xargs -n1 seerr request approve
```

## AI agents

[`skills/seerr`](skills/seerr/SKILL.md) is an [Agent Skill](https://agentskills.io) that teaches AI agents how to use `seerr`.

```
Install the Agent SKILL in this repository: https://github.com/robloach/seerr-cli
```

### Tab completion (Optional)

To get tab completion, add one of these lines to your shell's startup file:

```bash
source <(seerr completions bash)  # ~/.bashrc
source <(seerr completions zsh)   # ~/.zshrc, after compinit
```

## Development

`seerr` is generated by [Bashly](https://bashly.dev). Don't edit the `seerr` script directly; edit the files in `src/` and regenerate it:

```bash
bashly generate   # settings.yml makes this the production build
shellcheck seerr test/approve
test/approve
```

## License

[MIT](LICENSE)
