## Turn a TMDB ID or a title into a TMDB ID.
##
## A title is searched for. Results with exactly that title win over the first
## result, unless they are obscure: an exact match needs at least a tenth of
## the votes of the first result or the top exact match, so "Matrix" still
## finds The Matrix rather than a 1971 short. If more than one exact match is
## left and a terminal is attached, you're asked which one you mean.
##
## --year limits the results to one release year, and makes a number like
## 1917 count as a title instead of an ID. Up to 3 pages of results are
## searched for a match.
##
## Sets seerr_tmdb_id, and seerr_tmdb_match to "Title (Year)" when it searched.
## Usage: seerr_tmdb_resolve movie|tv TITLE_OR_ID
seerr_tmdb_resolve() {
  local type=$1 query=$2 year=${args[--year]:-}
  local json pick answer page=1 pages
  local -a matches=()
  local filter='
    [.results[]
      | select(.mediaType == $type)
      | select($year == "" or ((.releaseDate // .firstAirDate) | year) == $year)
      | {
          id,
          label: (title_year | one_line),
          votes: (.voteCount // 0),
          exact: ((.title // .name | ascii_downcase) == ($query | ascii_downcase))
        }]
    | . as $all
    | [$all[] | select(.exact)] as $exact
    | ([$exact[].votes, ($all[0].votes // 0)] | max) as $top
    | [$exact[] | select(.votes * 10 >= $top)][:10] as $choices
    | if ($choices | length) > 0 then $choices else $all[:1] end
    | .[]
    | "\(.id)\t\(.label)"'

  seerr_tmdb_match=""
  if [[ $query =~ ^[0-9]+$ && -z $year ]]; then
    seerr_tmdb_id=$query
    return
  fi

  while true; do
    json=$(seerr_api GET "/search$(seerr_query query "$query" page "$page" language "${args[--language]:-}")")
    mapfile -t matches < <(jq -r --arg type "$type" --arg year "$year" --arg query "$query" "$(seerr_jq_defs) $filter" <<<"$json")
    pages=$(jq -r '.totalPages // 1' <<<"$json")
    if ((${#matches[@]} > 0 || page >= pages || page >= 3)); then
      break
    fi
    page=$((page + 1))
  done

  if ((${#matches[@]} == 0)); then
    seerr_die "no $type found matching '$query'${year:+ from $year}. Try 'seerr search \"$query\"'."
  fi

  pick=${matches[0]}
  if ((${#matches[@]} > 1)) && [[ -t 0 && -t 2 ]]; then
    printf 'Several matches for "%s":\n' "$query" >&2
    for answer in "${!matches[@]}"; do
      printf '  %d) %s, TMDB ID %s\n' $((answer + 1)) "${matches[answer]#*$'\t'}" "${matches[answer]%%$'\t'*}" >&2
    done

    while true; do
      read -r -p "Which one? [1-${#matches[@]}, default 1] " answer || seerr_die "no match chosen"
      answer=${answer:-1}
      if [[ $answer =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#matches[@]})); then
        pick=${matches[answer - 1]}
        break
      fi
      printf 'Enter a number from 1 to %d.\n' "${#matches[@]}" >&2
    done
  fi

  seerr_tmdb_id=${pick%%$'\t'*}
  seerr_tmdb_match=${pick#*$'\t'}
}
