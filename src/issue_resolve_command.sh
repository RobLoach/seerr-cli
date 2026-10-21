json=$(seerr_api POST "/issue/${args[id]}/resolved")
seerr_report "$json" "Resolved issue #${args[id]} ($(seerr_media_label "$json"))"
