api_key="not set"
if [[ -n $seerr_api_key ]]; then
  api_key="****"
  if ((${#seerr_api_key} > 8)); then
    api_key="${seerr_api_key:0:4}...${seerr_api_key: -4}"
  fi
fi

timeout=$seerr_timeout
if [[ $timeout =~ ^[0-9]+$ ]]; then
  timeout+=s
fi

printf '%-13s %s\n' \
  "Config file:" "${seerr_config_file:-none found}" \
  "URL:" "${seerr_url:-not set}" \
  "API key:" "$api_key" \
  "Timeout:" "$timeout" \
  "HTTP client:" "$seerr_http_client"

# Other commands stop at a missing or bad config file without showing
# anything, so check it only after showing the settings.
seerr_config_check
