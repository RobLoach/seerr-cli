query=$(seerr_query \
  take "${args[--take]}" \
  skip "$(seerr_skip)" \
  filter "${args[--filter]:-}" \
  sort "${args[--sort]}")
json=$(seerr_api GET "/media$query")
titles=$(seerr_titles_map "$json" '.results[]')
seerr_table "$json" '
  ["ID", "TYPE", "TMDB", "TITLE", "STATUS", "4K STATUS", "UPDATED"],
  (.results[] | [
    .id,
    .mediaType,
    .tmdbId,
    media_title($titles),
    (.status | media_status),
    (.status4k | media_status),
    (.updatedAt | date)
  ])' --argjson titles "$titles"
seerr_footer "$json" page_info_footer
