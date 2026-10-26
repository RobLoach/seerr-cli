#!/usr/bin/env bash
# Tables, requests, and issues.
source approvals.bash
source helpers.sh

describe "search"
  it "shows movies and TV shows with their status"
    approve "seerr search Dune"

describe "tv"
  it "shows the show and each season's status"
    approve "seerr tv 1399"

describe "request list"
  it "looks up the title of each request"
    approve "seerr request list"
    approve "sent" "sent_request_list"

  it "skips the title lookups with --json"
    approve "seerr request list --json | jq '.results | length'"
    approve "sent" "sent_request_list_json"

describe "request create"
  it "requests a movie"
    approve "seerr request create movie 603"
    approve "sent" "sent_request_create_movie"

  it "requests some seasons of a TV show in 4K"
    approve "seerr request create tv 1399 --seasons 1,2 --4k"
    approve "sent" "sent_request_create_tv"

  it "fails when Seerr doesn't create a request"
    # Seerr answers 202 with only a message when no seasons are left to
    # request. See https://github.com/RobLoach/seerr-cli/issues/1
    approve "seerr request create tv 79063"
    expect_exit_code 1

  it "rejects --seasons for a movie"
    approve "seerr request create movie 603 --seasons 1"
    expect_exit_code 1

describe "request approve"
  it "names the title it approved"
    approve "seerr request approve 12"

describe "issue create"
  it "reports a problem with a movie"
    approve "seerr issue create movie 603 'Audio is out of sync' --problem audio"
    approve "sent" "sent_issue_create"

  it "fails for a movie that isn't in Seerr"
    approve "seerr issue create movie 841 'No sound'"
    expect_exit_code 1
