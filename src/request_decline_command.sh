json=$(seerr_api POST "/request/${args[id]}/decline")
seerr_report "$json" "Declined request #${args[id]} ($(seerr_media_label "$json"))"
