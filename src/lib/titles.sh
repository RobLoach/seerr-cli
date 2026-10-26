## Look up the title of every movie and TV show referenced in a response.
## Request, media, and issue responses only carry TMDB IDs, so this makes one
## extra API call per unique title, 8 at a time. Prints a JSON object such as
## {"movie:603": "The Matrix (1999)"} for jq's media_title($titles). The year
## tells apart titles such as the 1984 and 2021 Dune. Makes no calls
## and prints {} when --json is set.
## Usage: seerr_titles_map JSON MEDIA_FILTER
##   MEDIA_FILTER selects the media objects, e.g. '.results[].media'
seerr_titles_map() {
  local json=$1 filter=$2
  local dir key count=0
  local -a keys=()

  if [[ -z ${args[--json]:-} ]]; then
    mapfile -t keys < <(jq -r "[$filter | select(.mediaType == \"movie\" or .mediaType == \"tv\") | \"\(.mediaType):\(.tmdbId)\"] | unique[]" <<<"$json")
  fi
  if ((${#keys[@]} == 0)); then
    echo '{}'
    return
  fi

  dir=$(mktemp -d)
  # shellcheck disable=SC2064 # expand $dir now; it is local to this function
  trap "rm -rf '$dir'" EXIT

  for key in "${keys[@]}"; do
    seerr_title_fetch "$key" >"$dir/$count" &
    count=$((count + 1))
    if ((count % 8 == 0)); then
      wait
    fi
  done
  wait

  cat "$dir"/* | jq -sc 'map({(.key): .title}) | add // {}'
  rm -rf "$dir"
  trap - EXIT
}

## Print {"key": KEY, "title": "TITLE (YEAR)"} for a key like "movie:603", or
## nothing when the title can't be fetched.
seerr_title_fetch() {
  seerr_request GET "/${1%%:*}/${1#*:}"
  if [[ $seerr_status == 2?? ]]; then
    jq -c --arg key "$1" "$(seerr_jq_defs) select(.title // .name) | {key: \$key, title: title_year}" <<<"$seerr_body" 2>/dev/null || true
  fi
}

## Print the title of the media in a request or issue response, falling back
## to its type and TMDB ID when the title cannot be found, or to
## "unknown title" when the response has no media.
## Usage: seerr_media_label JSON
seerr_media_label() {
  local titles

  titles=$(seerr_titles_map "$1" '.media')
  jq -r --argjson titles "$titles" "$(seerr_jq_defs) .media | media_label(\$titles)" <<<"$1"
}
