#!/usr/bin/env bash
# Reading and writing the config file, and which setting wins.
source approvals.bash
source helpers.sh

unset SEERR_URL SEERR_API_KEY

describe "config show"
  it "shows what isn't set"
    approve "seerr config show"

  it "reads the config file"
    write_config <<'YAML'
url: https://file.example
api_key: abcd1234efgh
YAML
    approve "seerr config show" "config_show_file"

  it "prefers environment variables to the config file"
    approve "SEERR_URL=https://env.example seerr config show"

  it "prefers flags to environment variables"
    approve "SEERR_URL=https://env.example seerr -u https://flag.example config show"

  it "shows the settings, then fails, when --config doesn't exist"
    approve "seerr -c ~/missing.yaml config show"
    expect_exit_code 1

describe "reading the config file"
  it "takes a value out of quotes"
    write_config <<'YAML'
url: "https://quoted.example"
http_client: 'wget'
YAML
    approve "seerr config show" "config_read_quotes"

  it "keeps a # that has no space before it"
    write_config <<<'url: https://hash.example/#top'
    approve "seerr config show" "config_read_hash"

  it "reads Windows line endings"
    printf 'url: https://crlf.example\r\ntimeout: 9\r\n' | write_config
    approve "seerr config show" "config_read_crlf"

  it "ignores indented and unknown keys, and a missing final newline"
    printf -- '---\n  url: https://indented.example\nurl_old: https://old.example\nurl: https://top.example' | write_config
    approve "seerr config show" "config_read_ignored"

  it "shows the settings, then fails, when a value is bad"
    write_config <<<'timeout: soon'
    approve "seerr config show" "config_show_bad_value"
    expect_exit_code 1
    approve "seerr status" "config_bad_value_other_command"
    expect_exit_code 1

describe "config set"
  rm ~/.config/seerr/seerr-cli.yaml

  it "creates the config file, readable only by you"
    approve "seerr config set url https://seerr.example.com"
    approve "printf 'abcd1234efgh\n' | seerr config set api_key"
    approve 'cat ~/.config/seerr/seerr-cli.yaml' "config_set_created_file"
    approve 'ls -l ~/.config/seerr/seerr-cli.yaml | cut -c1-10' "config_set_permissions"

  it "replaces a setting, and keeps comments and other settings"
    write_config <<'YAML'
# My server
url: https://old.example
api_key: abcd1234efgh
url: https://duplicate.example
YAML
    approve "seerr config set url https://new.example"
    approve 'cat ~/.config/seerr/seerr-cli.yaml' "config_set_replaced_file"

  it "writes the file named by --config, even when it doesn't exist yet"
    approve "seerr -c ~/other.yaml config set timeout 60"

  it "writes under XDG_CONFIG_HOME"
    approve "XDG_CONFIG_HOME=~/xdg seerr config set timeout 60"

  it "warns when an environment variable overrides the setting"
    approve "SEERR_TIMEOUT=10 seerr config set timeout 60"

  it "rejects bad values"
    approve "seerr config set url ftp://seerr.example.com"
    expect_exit_code 1
    approve "seerr config set timeout 0"
    expect_exit_code 1
    approve "seerr config set api_key \$'abcd\n1234'"
    expect_exit_code 1
    approve "seerr config set api_key </dev/null"
    expect_exit_code 1
