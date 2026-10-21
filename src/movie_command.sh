seerr_tmdb_resolve movie "${args[title_or_id]}"
json=$(seerr_api GET "/movie/$seerr_tmdb_id$(seerr_query language "${args[--language]:-}")")
seerr_table "$json" '
  ["Title:", .title],
  ["Released:", .releaseDate],
  ["Runtime:", (if .runtime then "\(.runtime) min" else null end)],
  ["Genres:", ([.genres[]?.name] | join(", "))],
  ["Rating:", (if .voteCount > 0 then "\(.voteAverage)/10 (\(.voteCount) votes)" else null end)],
  ["TMDB ID:", .id],
  ["IMDb ID:", (.imdbId // .externalIds.imdbId)],
  ["Status:", ((.mediaInfo.status | media_status) // "not requested")],
  ["4K status:", (.mediaInfo.status4k | media_status)],
  ["Overview:", .overview]'
