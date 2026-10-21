query=$(seerr_query \
  take "${args[--take]}" \
  skip "$(seerr_skip)" \
  filter "${args[--filter]}" \
  sort "${args[--sort]}")
json=$(seerr_api GET "/issue$query")
titles=$(seerr_titles_map "$json" '.results[].media')
seerr_table "$json" '
  ["ID", "TYPE", "STATUS", "MEDIA", "TMDB", "TITLE", "CREATED BY", "COMMENTS", "CREATED"],
  (.results[] | [
    .id,
    (.issueType | issue_type),
    (.status | issue_status),
    .media.mediaType,
    .media.tmdbId,
    (.media | media_title($titles)),
    (.createdBy | user_name),
    (if .comments then (.comments | length) else null end),
    (.createdAt | date)
  ])' --argjson titles "$titles"
seerr_footer "$json" page_info_footer
