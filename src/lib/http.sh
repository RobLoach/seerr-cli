## Send a request to the Seerr API and print the response body. Exits with an
## error when the server cannot be reached, returns a non-2xx status, or
## returns something other than JSON, such as a proxy's login page.
## Usage: seerr_api METHOD PATH [JSON_BODY]
seerr_api() {
  seerr_require_settings
  seerr_request "$@"

  case $seerr_status in
    2??)
      if [[ -z $seerr_body ]]; then
        return
      fi
      if ! jq empty <<<"$seerr_body" 2>/dev/null; then
        seerr_die "$seerr_url did not answer with JSON. Check that the URL points at Seerr itself, not a login page or another service."
      fi
      printf '%s\n' "$seerr_body"
      ;;
    000) seerr_die "$(seerr_connect_error)" ;;
    *) seerr_die "$(seerr_http_error)" ;;
  esac
}

## Exit with an error unless JSON has an id, as everything Seerr creates
## does. Seerr answers some refusals with a 2xx status and only a message,
## such as 202 "No seasons available to request". HINT goes under the error.
## Usage: seerr_require_id JSON WHAT [HINT]
seerr_require_id() {
  local message

  if jq -e '.id != null' >/dev/null 2>&1 <<<"$1"; then
    return
  fi

  message=$(seerr_message "$1")
  seerr_die "no $2 created: ${message:-the response had no ID}${3:+$'\n'$3}"
}

## Send a request to the Seerr API without exiting on failure.
## Sets seerr_status (HTTP status, or 000 when the server could not be
## reached), seerr_body, and seerr_error (the HTTP client's error text).
## Usage: seerr_request METHOD PATH [JSON_BODY]
seerr_request() {
  local method=$1 path=$2 body=${3:-}
  local tmp

  tmp=$(mktemp -d)
  # shellcheck disable=SC2064 # expand $tmp now; it is local to this function
  trap "rm -rf '$tmp'" EXIT
  if [[ -n $body ]]; then
    printf '%s' "$body" >"$tmp/request"
  fi

  if [[ $seerr_http_client == wget ]]; then
    seerr_request_wget "$method" "$seerr_url/api/v1$path" "$tmp"
  else
    seerr_request_curl "$method" "$seerr_url/api/v1$path" "$tmp"
  fi

  seerr_body=""
  if [[ -f $tmp/body ]]; then
    seerr_body=$(<"$tmp/body")
  fi
  rm -rf "$tmp"
  trap - EXIT
}

## The API key and request body are passed through files rather than the
## command line, so the key does not show up in `ps` output and large bodies
## do not hit the argument length limit.
seerr_request_curl() {
  local method=$1 url=$2 tmp=$3
  local options=(-sS -X "$method" -o "$tmp/body" -w '%{http_code}' --max-time "$seerr_timeout" -H 'Accept: application/json')

  if [[ -f $tmp/request ]]; then
    options+=(-H 'Content-Type: application/json' --data-binary "@$tmp/request")
  fi

  seerr_status=$(curl "${options[@]}" -H @<(printf 'X-Api-Key: %s\n' "$seerr_api_key") "$url" 2>"$tmp/error") || true
  seerr_error=$(<"$tmp/error")
  seerr_error=${seerr_error#curl: (*) }
}

## wget reads its config file twice, so the API key goes in a temporary
## wgetrc inside the private temp directory instead of a pipe.
## wget retries up to 20 times by default, which could send a POST twice, so
## it gets one try.
seerr_request_wget() {
  local method=$1 url=$2 tmp=$3
  local options=(-nv -S -O "$tmp/body" --content-on-error --max-redirect=0 --tries=1 --timeout="$seerr_timeout" --method="$method" --header='Accept: application/json')

  if [[ -f $tmp/request ]]; then
    options+=(--header='Content-Type: application/json' --body-file="$tmp/request")
  fi

  printf 'header = X-Api-Key: %s\n' "$seerr_api_key" >"$tmp/wgetrc"
  wget --config="$tmp/wgetrc" "${options[@]}" "$url" 2>"$tmp/error" || true

  seerr_status=$(sed -n 's/^ *HTTP\/[0-9.]* \([0-9][0-9][0-9]\).*/\1/p' "$tmp/error" | tail -n 1)
  seerr_status=${seerr_status:-000}
  seerr_error=$(grep -v '^ ' "$tmp/error" | tail -n 1) || true
}

## Print the message in a response from Seerr, or nothing when it has none.
## Most errors use "message", but authentication errors use "error".
seerr_message() {
  jq -r '.message // .error // empty' <<<"$1" 2>/dev/null || true
}

## Describe a failed response, using the server's message when it sent one.
seerr_http_error() {
  local message

  message=$(seerr_message "$seerr_body")
  printf 'HTTP %s%s' "$seerr_status" "${message:+: $message}"

  case $seerr_status in
    401 | 403) printf '\nCheck that your API key is correct (seerr config show).' ;;
    3??) printf '\nThe server redirected the request. Check the URL, e.g. http vs https.' ;;
  esac
}

## Describe a request that got no response at all.
seerr_connect_error() {
  printf 'could not reach %s%s' "$seerr_url" "${seerr_error:+: $seerr_error}"

  if [[ ${seerr_error,,} == *"timed out"* ]]; then
    printf '\nGave up after %ss. To wait longer, set SEERR_TIMEOUT or run: seerr config set timeout SECONDS' "$seerr_timeout"
  fi
}

## Exit with setup instructions when the URL or API key is missing.
seerr_require_settings() {
  if [[ -z $seerr_url ]]; then
    seerr_die "no Seerr URL set. Use --url, SEERR_URL, or 'url:' in the config file (see seerr --help)."
  fi
  if [[ -z $seerr_api_key ]]; then
    seerr_die "no API key set. Use --api-key, SEERR_API_KEY, or 'api_key:' in the config file (see seerr --help)."
  fi
}

## Build a URL query string from key/value pairs, skipping empty values.
## Usage: seerr_query take 20 filter pending   # prints ?take=20&filter=pending
seerr_query() {
  local query="" separator="?"

  while (($# >= 2)); do
    if [[ -n $2 ]]; then
      query+="$separator$1=$(jq -rn --arg value "$2" '$value | @uri')"
      separator="&"
    fi
    shift 2
  done

  printf '%s' "$query"
}

## Convert --page and --take into the number of results to skip.
seerr_skip() {
  echo $(((${args[--page]} - 1) * ${args[--take]}))
}
