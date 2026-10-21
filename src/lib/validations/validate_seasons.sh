## Used by `validate: seasons` in bashly.yml.
validate_seasons() {
  if [[ $1 != all && ! $1 =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo "must be 'all' or comma-separated season numbers, e.g. 1,2,3"
  fi
}
