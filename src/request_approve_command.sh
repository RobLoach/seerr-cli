json=$(seerr_api POST "/request/${args[id]}/approve")
seerr_report "$json" "Approved request #${args[id]} ($(seerr_media_label "$json"))"
