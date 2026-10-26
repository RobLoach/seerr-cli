json=$(seerr_api POST "/issue/${args[id]}/open")
seerr_report "$json" "Reopened issue #${args[id]} for $(seerr_media_label "$json")"
