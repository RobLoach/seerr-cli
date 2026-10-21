## Used by `validate: positive_integer` in bashly.yml.
validate_positive_integer() {
  if ! [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    echo "must be a whole number greater than 0"
  fi
}
