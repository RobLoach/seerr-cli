## Print an error message to stderr and exit.
seerr_die() {
  printf 'seerr: %s\n' "$*" >&2
  exit 1
}

## Render JSON as an aligned table, or pretty-print it when --json is set.
## FILTER must emit one array per row. Extra arguments are passed to jq
## before the filter, e.g. --argjson titles "$titles".
## Usage: seerr_table JSON FILTER [JQ_ARGS...]
seerr_table() {
  local json=$1 filter=$2 rows
  shift 2

  if [[ -n ${args[--json]:-} ]]; then
    jq . <<<"$json"
    return
  fi

  rows=$(jq -r "$@" "$(seerr_jq_defs) ($filter) | map(if . == null or . == \"\" then \"-\" else (tostring | one_line) end) | join(\"\\t\")" <<<"$json") ||
    seerr_die "could not read the response from $seerr_url"
  if [[ -n $rows ]]; then
    seerr_columns <<<"$rows"
  fi
}

## Print a summary line under a table. Does nothing when --json is set.
## Usage: seerr_footer JSON FILTER
seerr_footer() {
  if [[ -n ${args[--json]:-} ]]; then
    return
  fi

  echo
  jq -r "$(seerr_jq_defs) $2" <<<"$1"
}

## Print MESSAGE, or the JSON response when --json is set.
## Usage: seerr_report JSON MESSAGE
seerr_report() {
  if [[ -n ${args[--json]:-} ]]; then
    if [[ -n $1 ]]; then
      jq . <<<"$1"
    fi
  else
    printf '%s\n' "$2"
  fi
}

## Align tab-separated columns when `column` is available.
seerr_columns() {
  if command -v column >/dev/null 2>&1; then
    column -t -s $'\t'
  else
    cat
  fi
}

## jq definitions shared by every table and footer.
seerr_jq_defs() {
  cat <<'JQ'
def lookup(names): if . == null then null else (names[tostring] // tostring) end;
def request_status: lookup({"1": "pending", "2": "approved", "3": "declined", "4": "failed", "5": "completed"});
def media_status: lookup({"1": "unknown", "2": "pending", "3": "processing", "4": "partial", "5": "available", "6": "blocklisted", "7": "deleted"});
def issue_type: lookup({"1": "video", "2": "audio", "3": "subtitles", "4": "other"});
def issue_status: lookup({"1": "open", "2": "resolved"});
def user_type: lookup({"1": "plex", "2": "local", "3": "jellyfin", "4": "emby"});
def user_name: .displayName // .username // .plexUsername // .jellyfinUsername // .email;
def yes_no: if . == true then "yes" elif . == false then "no" else null end;
def date: if type == "string" and length >= 10 then .[0:10] else null end;
def year: if type == "string" and length >= 4 then .[0:4] else null end;
def one_line: gsub("\\s+"; " ");
def title_year: (.title // .name) + (((.releaseDate // .firstAirDate) | year) as $year | if $year then " (\($year))" else "" end);
def media_title($titles): $titles["\(.mediaType):\(.tmdbId)"];
def media_label($titles): media_title($titles) // (if .tmdbId then "\(.mediaType) \(.tmdbId)" else "unknown title" end);
def results_table:
  ["TYPE", "ID", "TITLE", "YEAR", "STATUS"],
  (.results[] | [.mediaType, .id, (.title // .name), ((.releaseDate // .firstAirDate) | year), (.mediaInfo.status | media_status)]);
def page_footer:
  if .totalResults == 0 then "No results." else "Page \(.page) of \(.totalPages), \(.totalResults) results" end;
def page_info_footer:
  .pageInfo | if .results == 0 then "No results." else "Page \(.page) of \(.pages), \(.results) total" end;
JQ
}
