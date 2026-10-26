## Resolve the settings from flags, environment variables, and the config
## file, in that order of precedence, falling back to defaults.
##
## Sets these globals:
##   seerr_config_file                  config file in use, or empty
##   seerr_url                          server URL
##   seerr_api_key                      API key
##   seerr_timeout                      seconds to wait for each request
##   seerr_http_client                  curl or wget
##
## Usage: seerr_settings_resolve [lenient]
##   lenient is for `config set`, which may create the config file or fix a
##   bad value in it, so neither a missing file nor a bad value stops it.
seerr_settings_resolve() {
  local key var error

  seerr_config_locate "${1:-}"
  seerr_config_url=""
  seerr_config_api_key=""
  seerr_config_timeout=""
  seerr_config_http_client=""
  if [[ -f $seerr_config_file ]]; then
    seerr_config_read "$seerr_config_file"
  fi

  # Bashly checks flags and environment variables, but not the config file.
  if [[ ${1:-} != lenient ]]; then
    for key in url timeout http_client; do
      var=seerr_config_$key
      error=$(seerr_config_validate "$key" "${!var}")
      if [[ -n $error ]]; then
        seerr_die "$key in $seerr_config_file: $error"
      fi
    done
  fi

  # The first value that isn't empty wins: flag, then environment, then file.
  seerr_url=${args[--url]:-${SEERR_URL:-$seerr_config_url}}
  seerr_api_key=${args[--api-key]:-${SEERR_API_KEY:-$seerr_config_api_key}}
  seerr_timeout=${SEERR_TIMEOUT:-${seerr_config_timeout:-30}}
  seerr_http_client=${SEERR_HTTP_CLIENT:-${seerr_config_http_client:-${deps[http_client]##*/}}}

  seerr_url=${seerr_url%/}
  seerr_url=${seerr_url%/api/v1}
}

## Print why VALUE isn't valid for config KEY, or nothing when it is. An empty
## value is valid, because it means the key isn't set.
## Usage: seerr_config_validate KEY VALUE
seerr_config_validate() {
  if [[ -z $2 ]]; then
    return
  fi

  case $1 in
    url) validate_url "$2" ;;
    timeout) validate_positive_integer "$2" ;;
    http_client) validate_http_client "$2" ;;
  esac
}

## Find the config file and store its path in seerr_config_file, or leave it
## empty when there is none. A --config or SEERR_CONFIG path must exist
## unless MODE is lenient; the default locations are optional.
## Usage: seerr_config_locate [lenient]
seerr_config_locate() {
  local mode=${1:-}
  local explicit=${args[--config]:-${SEERR_CONFIG:-}}
  local candidate

  seerr_config_file=""
  if [[ -n $explicit ]]; then
    if [[ ! -f $explicit && $mode != lenient ]]; then
      seerr_die "config file not found: $explicit"
    fi
    seerr_config_file=$explicit
    return
  fi

  while IFS= read -r candidate; do
    if [[ -f $candidate ]]; then
      seerr_config_file=$candidate
      return
    fi
  done < <(seerr_config_candidates)
}

## Print the default config file locations, in the order they are searched.
seerr_config_candidates() {
  local base=${XDG_CONFIG_HOME:-$HOME/.config}

  printf '%s\n' "$base/seerr/seerr-cli.yaml" "$base/seerr-cli.yaml" "$HOME/.seerr-cli.yaml"
}

## Read the settings from a YAML config file into seerr_config_url,
## seerr_config_api_key, seerr_config_timeout, and seerr_config_http_client.
## Only top-level "key: value" lines are read, the same lines that
## seerr_config_write writes. As in YAML, a value may be in single or double
## quotes, and a # after a space starts a comment. Values are assigned as
## plain strings and never evaluated, so the file cannot run code. Unknown
## keys are ignored.
seerr_config_read() {
  local line key value
  local double_quoted='^[[:space:]]*"([^"]*)"[[:space:]]*(#.*)?$'
  local single_quoted="^[[:space:]]*'([^']*)'[[:space:]]*(#.*)?\$"

  [[ -r $1 ]] || seerr_die "cannot read config file: $1"

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ ! $line =~ ^([a-z_]+)[[:space:]]*:(.*)$ ]]; then
      continue
    fi
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}

    if [[ $value =~ $double_quoted || $value =~ $single_quoted ]]; then
      value=${BASH_REMATCH[1]}
    else
      value=${value%%[[:space:]]#*}
      value=${value#"${value%%[![:space:]]*}"}
      value=${value%"${value##*[![:space:]]}"}
    fi

    case $key in
      url) seerr_config_url=$value ;;
      api_key) seerr_config_api_key=$value ;;
      timeout) seerr_config_timeout=$value ;;
      http_client) seerr_config_http_client=$value ;;
    esac
  done <"$1"
}

## Set a top-level KEY to VALUE in a YAML config file, replacing an existing
## KEY line or appending one. Other lines, including comments, are kept.
## The file is created if needed, and made readable only by you before
## anything is written, because it holds the API key.
## Usage: seerr_config_write FILE KEY VALUE
seerr_config_write() {
  local file=$1 key=$2 value=$3
  local line found="" lines=()

  if [[ -f $file ]]; then
    while IFS= read -r line || [[ -n $line ]]; do
      if [[ $line =~ ^${key}[[:space:]]*: ]]; then
        if [[ -n $found ]]; then
          continue
        fi
        line="$key: $value"
        found=1
      fi
      lines+=("$line")
    done <"$file"
  fi

  if [[ -z $found ]]; then
    lines+=("$key: $value")
  fi

  (
    umask 077
    mkdir -p "$(dirname "$file")"
    : >>"$file"
  )
  chmod 600 "$file"
  printf '%s\n' "${lines[@]}" >"$file"
}
