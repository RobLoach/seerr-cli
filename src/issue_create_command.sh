type=${args[type]}
season=${args[--season]:-0}
episode=${args[--episode]:-0}

if [[ $type == movie && (-n ${args[--season]:-} || -n ${args[--episode]:-}) ]]; then
  seerr_die "--season and --episode only apply to TV issues"
fi

seerr_tmdb_resolve "$type" "${args[title_or_id]}"
details=$(seerr_api GET "/$type/$seerr_tmdb_id")
title=${seerr_tmdb_match:-$(jq -r "$(seerr_jq_defs) title_year" <<<"$details")}

# Issues belong to Seerr's own media record, not the TMDB ID.
media_id=$(jq -r '.mediaInfo.id // empty' <<<"$details")
if [[ -z $media_id ]]; then
  seerr_die "$title isn't in Seerr yet. You can only report issues for media that has been requested."
fi

body=$(jq -cn \
  --arg problem "${args[--problem]}" \
  --arg message "${args[message]}" \
  --argjson media "$media_id" \
  --argjson season "$season" \
  --argjson episode "$episode" '
  {
    issueType: {video: 1, audio: 2, subtitles: 3, other: 4}[$problem],
    message: $message,
    mediaId: $media,
    problemSeason: $season,
    problemEpisode: $episode
  }')
json=$(seerr_api POST /issue "$body")
seerr_require_id "$json" issue
seerr_report "$json" "Created issue #$(jq -r .id <<<"$json") for $title"
