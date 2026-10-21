url="not set"
if [[ -n $seerr_url ]]; then
  url="$seerr_url"
fi

api_key="not set"
if [[ -n $seerr_api_key ]]; then
  api_key="****"
  if ((${#seerr_api_key} > 8)); then
    api_key="${seerr_api_key:0:4}...${seerr_api_key: -4}"
  fi
fi

printf '%-13s %s\n' \
  "Config file:" "${seerr_config_file:-none found}" \
  "URL:" "$url" \
  "API key:" "$api_key" \
  "Timeout:" "${seerr_timeout}s" \
  "HTTP client:" "$seerr_http_client"
