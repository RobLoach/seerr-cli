json=$(seerr_api POST "/request/${args[id]}/retry")
status=$(jq -r "$(seerr_jq_defs) .status | request_status" <<<"$json")
seerr_report "$json" "Retried request #${args[id]} ($(seerr_media_label "$json")), now $status"
