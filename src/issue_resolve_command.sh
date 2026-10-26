json=$(seerr_api POST "/issue/${args[id]}/resolved")
seerr_report "$json" "Resolved issue #${args[id]} for $(seerr_media_label "$json")"
