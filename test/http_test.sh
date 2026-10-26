#!/usr/bin/env bash
# Sending requests and handling failures. Every test runs with curl and then
# wget, and both must match the same approved output.
source approvals.bash
source helpers.sh

for client in curl wget; do
  export SEERR_HTTP_CLIENT=$client

  describe "requests with $client"
    it "prints the response"
      approve "seerr status"

    it "sends JSON bodies"
      approve "seerr api POST /echo --data '{\"username\": \"alice\"}'"
      approve "seerr api PUT /echo --data @fixtures/user.json"
      approve "echo '{\"username\": \"carol\"}' | seerr api PATCH /echo --data -"

    it "keeps the query string, and takes a path that starts with /api/v1"
      approve "seerr api GET '/api/v1/echo?page=2&genre=18'"

    it "accepts an empty response"
      approve "seerr request delete 12"

  describe "failures with $client"
    it "explains a rejected API key"
      approve "seerr -k wrong-key status"
      expect_exit_code 1

    it "shows the server's message"
      approve "seerr api GET /missing"
      expect_exit_code 1

    it "doesn't follow redirects"
      approve "seerr api GET /redirect"
      expect_exit_code 1

    it "rejects a response that isn't JSON"
      approve "seerr api GET /html"
      expect_exit_code 1

    it "explains a server that can't be reached"
      approve "seerr -u http://127.0.0.1:1 status"
      expect_exit_code 1

    it "explains a timeout"
      approve "SEERR_TIMEOUT=1 seerr api GET /slow"
      expect_exit_code 1
done

describe "api --data"
  it "rejects JSON that isn't valid, without sending it"
    approve "seerr api POST /echo --data '{nope'"
    expect_exit_code 1
    approve "sent" "sent_api_invalid_json"

  it "fails when the file doesn't exist"
    approve "seerr api POST /echo --data @missing.json"
    expect_exit_code 1
