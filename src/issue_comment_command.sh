body=$(jq -cn --arg message "${args[message]}" '{message: $message}')
json=$(seerr_api POST "/issue/${args[id]}/comment" "$body")
seerr_report "$json" "Commented on issue #${args[id]}"
