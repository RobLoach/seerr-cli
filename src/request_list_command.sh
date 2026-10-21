query=$(seerr_query \
  take "${args[--take]}" \
  skip "$(seerr_skip)" \
  filter "${args[--filter]:-}" \
  mediaType "${args[--type]}" \
  sort "${args[--sort]}" \
  requestedBy "${args[--user]:-}")
json=$(seerr_api GET "/request$query")
titles=$(seerr_titles_map "$json" '.results[].media')
seerr_table "$json" '
  ["ID", "TYPE", "TMDB", "TITLE", "STATUS", "MEDIA", "4K", "REQUESTED BY", "CREATED"],
  (.results[] | [
    .id,
    (.type // .media.mediaType),
    .media.tmdbId,
    (.media | media_title($titles)),
    (.status | request_status),
    ((if .is4k then .media.status4k else .media.status end) | media_status),
    (.is4k | yes_no),
    (.requestedBy | user_name),
    (.createdAt | date)
  ])' --argjson titles "$titles"
seerr_footer "$json" page_info_footer
