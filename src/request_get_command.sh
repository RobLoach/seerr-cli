json=$(seerr_api GET "/request/${args[id]}")
titles=$(seerr_titles_map "$json" '.media')
seerr_table "$json" '
  ["ID:", .id],
  ["Title:", (.media | media_title($titles))],
  ["Type:", (.type // .media.mediaType)],
  ["TMDB ID:", .media.tmdbId],
  ["Status:", (.status | request_status)],
  ["Media status:", ((if .is4k then .media.status4k else .media.status end) | media_status)],
  ["4K:", (.is4k | yes_no)],
  ["Seasons:", ([.seasons[]?.seasonNumber | tostring] | join(", "))],
  ["Requested by:", (.requestedBy | user_name)],
  ["Modified by:", (.modifiedBy | user_name)],
  ["Created:", (.createdAt | date)],
  ["Updated:", (.updatedAt | date)]' --argjson titles "$titles"
