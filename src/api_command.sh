path="/${args[path]#/}"
path=${path#/api/v1}
data=${args[--data]:-}

case $data in
  -) data=$(cat) ;;
  @*)
    [[ -f ${data#@} ]] || seerr_fail 2 "file not found: ${data#@}"
    data=$(<"${data#@}")
    ;;
esac

if [[ -n $data ]] && ! jq empty <<<"$data" 2>/dev/null; then
  seerr_fail 2 "--data is not valid JSON"
fi

json=$(seerr_api "${args[method]}" "$path" "$data")
if [[ -n $json ]]; then
  jq . <<<"$json"
fi
