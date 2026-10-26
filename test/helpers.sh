# shellcheck shell=bash
# Functions for the *_test.sh files, which test/approve runs.

# The tests write config files in your home directory, so refuse to run
# unless test/approve has pointed HOME at a temporary directory.
if [[ -z ${SEERR_TEST_DIR:-} || $HOME != "$SEERR_TEST_DIR"/* ]]; then
  echo "Run the tests with test/approve." >&2
  exit 1
fi

# Run the seerr script in this checkout, with stderr included in the output.
# The fake server's URL shows as http://seerr.test and the home directory as
# ~, so the output is the same on every run. The HTTP client's own error text
# shows as CLIENT ERROR, because it differs between curl and wget and between
# their versions.
seerr() {
  local output status=0

  : >"$SEERR_TEST_DIR/requests"
  output=$("$SEERR_TEST_ROOT/seerr" "$@" 2>&1) || status=$?
  output=${output//"$SEERR_TEST_URL"/"http://seerr.test"}
  output=${output//"$HOME"/"~"}
  sed -E 's/^(seerr: could not reach [^ ]+): .*/\1: CLIENT ERROR/' <<<"$output"
  return "$status"
}

# Print the requests that the last seerr command sent to the fake server.
# They're sorted, because title lookups run in parallel.
sent() {
  sort "$SEERR_TEST_DIR/requests"
}

# Write stdin to the default config file.
write_config() {
  mkdir -p "$HOME/.config/seerr"
  cat >"$HOME/.config/seerr/seerr-cli.yaml"
}
