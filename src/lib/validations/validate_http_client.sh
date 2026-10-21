## Used by `validate: http_client` in bashly.yml, and for the config file.
## An empty value counts as unset, so it passes.
validate_http_client() {
  if [[ -z $1 ]]; then
    return
  fi

  if [[ $1 != curl && $1 != wget ]]; then
    echo "must be curl or wget"
  elif ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is not installed"
  fi
}
