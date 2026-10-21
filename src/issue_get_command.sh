json=$(seerr_api GET "/issue/${args[id]}")
titles=$(seerr_titles_map "$json" '.media')
seerr_table "$json" '
  ["ID:", .id],
  ["Title:", (.media | media_title($titles))],
  ["Media:", (.media | "\(.mediaType) \(.tmdbId)")],
  ["Type:", (.issueType | issue_type)],
  ["Status:", (.status | issue_status)],
  ["Season:", (if (.problemSeason // 0) > 0 then .problemSeason else null end)],
  ["Episode:", (if (.problemEpisode // 0) > 0 then .problemEpisode else null end)],
  ["Created by:", (.createdBy | user_name)],
  ["Created:", (.createdAt | date)],
  ["Updated:", (.updatedAt | date)]' --argjson titles "$titles"

if [[ -z ${args[--json]:-} ]] && jq -e '(.comments // []) | length > 0' >/dev/null <<<"$json"; then
  echo
  seerr_table "$json" '
    ["COMMENT BY", "DATE", "MESSAGE"],
    (.comments[] | [(.user | user_name), (.createdAt | date), .message])'
fi
