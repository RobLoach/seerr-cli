seerr_tmdb_resolve tv "${args[title_or_id]}"
language=$(seerr_query language "${args[--language]:-}")

if [[ -n ${args[--season]:-} ]]; then
  json=$(seerr_api GET "/tv/$seerr_tmdb_id/season/${args[--season]}$language")
  seerr_table "$json" '
    ["EPISODE", "AIR DATE", "NAME"],
    (.episodes[] | [.episodeNumber, .airDate, .name])'
  return
fi

json=$(seerr_api GET "/tv/$seerr_tmdb_id$language")
seerr_table "$json" '
  ["Name:", .name],
  ["First aired:", .firstAirDate],
  ["Show status:", .status],
  ["Networks:", ([.networks[]?.name] | join(", "))],
  ["Genres:", ([.genres[]?.name] | join(", "))],
  ["Seasons:", (.numberOfSeasons // .numberOfSeason)],
  ["Episodes:", .numberOfEpisodes],
  ["Rating:", (if .voteCount > 0 then "\(.voteAverage)/10 (\(.voteCount) votes)" else null end)],
  ["TMDB ID:", .id],
  ["Status:", ((.mediaInfo.status | media_status) // "not requested")],
  ["Overview:", .overview]'

if [[ -z ${args[--json]:-} ]]; then
  echo
  seerr_table "$json" '
    . as $show
    | ["SEASON", "EPISODES", "AIR DATE", "STATUS", "NAME"],
      (.seasons[] | .seasonNumber as $number | [
        $number,
        .episodeCount,
        .airDate,
        ([$show.mediaInfo.seasons[]? | select(.seasonNumber == $number) | .status][0] | media_status),
        .name
      ])'
fi
