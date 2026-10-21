type=${args[type]}
seasons=${args[--seasons]:-}
is4k=false
if [[ -n ${args[--4k]:-} ]]; then
  is4k=true
fi

if [[ $type == movie && -n $seasons ]]; then
  seerr_die "--seasons only applies to TV requests"
fi

if [[ $type == tv ]]; then
  seasons=${seasons:-all}
fi

seerr_tmdb_resolve "$type" "${args[title_or_id]}"

body=$(jq -cn --arg type "$type" --argjson id "$seerr_tmdb_id" --argjson is4k "$is4k" --arg seasons "$seasons" '
  {mediaType: $type, mediaId: $id, is4k: $is4k}
  + if $type == "tv" then
      {seasons: (if $seasons == "all" then "all" else ($seasons | split(",") | map(tonumber)) end)}
    else {} end')
json=$(seerr_api POST /request "$body")
status=$(jq -r "$(seerr_jq_defs) .status | request_status" <<<"$json")
title=${seerr_tmdb_match:-$(seerr_media_label "$json")}
seerr_report "$json" "Requested $title as request #$(jq -r .id <<<"$json") ($status)"
