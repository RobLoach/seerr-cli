## Used by `validate: url` in bashly.yml, and by `config set url`.
## An empty value counts as unset, so it passes.
validate_url() {
  if [[ -n $1 && ! $1 =~ ^https?:// ]]; then
    echo "must start with http:// or https://, e.g. https://seerr.example.com"
  fi
}
