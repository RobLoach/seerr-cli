key=${args[key]}
value=${args[value]:-}
file=${seerr_config_file:-$(seerr_config_candidates | head -n 1)}

if [[ -z ${args[value]+set} ]]; then
  if [[ -t 0 ]]; then
    case $key in
      api_key)
        read -r -s -p "API key: " value
        echo >&2
        ;;
      url) read -r -p "Seerr URL: " value ;;
      timeout) read -r -p "Timeout in seconds: " value ;;
      http_client) read -r -p "HTTP client (curl or wget): " value ;;
    esac
  else
    read -r value || true
  fi
fi

if [[ -z $value ]]; then
  seerr_die "no value given for $key"
fi
if [[ $value == *$'\n'* ]]; then
  seerr_die "$key cannot contain a line break"
fi
error=$(seerr_config_validate "$key" "$value")
if [[ -n $error ]]; then
  seerr_die "$key: $error"
fi

seerr_config_write "$file" "$key" "$value"
echo "Saved $key to $file"

env_var=SEERR_${key^^}
if [[ -n ${!env_var:-} ]]; then
  echo "Note: $env_var is set, and it overrides the config file." >&2
fi
