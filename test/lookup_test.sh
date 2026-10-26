#!/usr/bin/env bash
# Turning a title into a TMDB ID, as described under "Search and browse" in
# the README.
source approvals.bash
source helpers.sh

describe "title lookup"
  it "takes a number as a TMDB ID, without searching"
    approve "seerr movie 603"
    approve "sent" "sent_movie_603"

  it "prefers an exact title to the first result"
    # Two popular movies are called Dune. Without a terminal to ask in, the
    # first one wins.
    approve "seerr movie Dune"

  it "keeps only results from --year"
    approve "seerr movie Dune --year 1984"

  it "skips an exact title that few people have voted on"
    approve "seerr movie Matrix"

  it "searches for a number when --year is given"
    approve "seerr movie 1917 --year 2019"
    approve "sent" "sent_movie_1917_year"

  it "looks through more pages of results for --year"
    approve "seerr movie Hamlet --year 1948"
    approve "sent" "sent_movie_hamlet_1948"

  it "gives up after three pages"
    approve "seerr movie Hamlet --year 1921"
    expect_exit_code 1
    approve "sent" "sent_movie_hamlet_1921"
