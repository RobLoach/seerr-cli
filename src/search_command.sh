query=${args[query]:-}
id=""
if [[ -n ${args[--imdb]:-} ]]; then
  imdb=$(seerr_imdb_id "${args[--imdb]}") || seerr_die "not an IMDb ID or imdb.com URL: ${args[--imdb]}"
  id="IMDb ID $imdb" query=imdb:$imdb
elif [[ -n ${args[--tvdb]:-} ]]; then
  id="TVDB ID ${args[--tvdb]}" query=tvdb:${args[--tvdb]}
fi

if [[ -n $id && -n ${args[query]:-} ]]; then
  seerr_die "give search terms or an ID, not both"
elif [[ -z $query ]]; then
  seerr_die "give search terms, --imdb ID, or --tvdb ID"
fi

json=$(seerr_api GET "/search$(seerr_query query "$query" page "${args[--page]}" language "${args[--language]:-}")")
if [[ -n $id ]] && jq -e '(.results // []) | length == 0' <<<"$json" >/dev/null; then
  seerr_die "nothing found with $id"
fi
seerr_table "$json" results_table
seerr_footer "$json" page_footer
