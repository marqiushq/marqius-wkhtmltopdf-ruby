#!/usr/bin/env bash
# wicked_pdf's and PDFKit's own test suites, unchanged, with this gem as their wkhtmltopdf:
#
#   bash tests/suites.sh LIBRARY WORK      LIBRARY: wicked_pdf or pdfkit
#
# Each library is fetched at the release and commit that github.com/marqiushq/wkhtmltopdf-library-tests
# tests, and its suite runs as there, with the same Ruby, the same Rails and the same allowances (the
# comments say each). The one change: the library's Gemfile also has the README's line,
# `gem "marqius-wkhtmltopdf"`, and no other wkhtmltopdf is on the machine. Each suite runs twice:
#   1. with the program the library finds by itself, which must be the gem's wkhtmltopdf command;
#   2. with MarqiusWkhtmltopdf.executable_path, named as the README shows.
# GEMS is the folder of the built gems, put in the bundle's vendor/cache, where Bundler chooses this
# machine's. Needs the Ruby the suite asks for (setup-ruby), git and, for wicked_pdf, libsqlite3-dev.
set -euo pipefail
lib=$1 work=$2
here=$(cd "$(dirname "$0")/.." && pwd)
src=$work/$lib
export CI=true
say() { printf '\n== %s\n' "$*"; }
fail() {
    echo "::error::$lib: $*" >&2
    exit 1
}
retry() { local n=$1 i=1; shift; until "$@"; do [ $i -ge "$n" ] && return 1; echo "retrying ($i): $*" >&2; sleep $((i * 10)); i=$((i + 1)); done; }

fetch() { # REPO COMMIT: the library at its release, by commit
    rm -rf "$src" && mkdir -p "$src" && cd "$src" && git init -q . &&
        git remote add origin "https://github.com/$1.git" &&
        retry 3 git fetch -q --depth 1 origin "$2" && git checkout -q FETCH_HEAD &&
        [ "$(git rev-parse HEAD)" = "$2" ] && echo "$1 at $2"
}

gemfile() { # GEMFILE: the README's line, and the built gems where Bundler looks for gems first
    ruby "$here/tests/readme.rb" install >> "$1"
    if [ -n "${GEMS:-}" ]; then
        mkdir -p "$(dirname "$1")/vendor/cache" && cp "$GEMS"/marqius-wkhtmltopdf-*.gem "$(dirname "$1")/vendor/cache/"
    fi
    tail -n 3 "$1"
}

found() { # the wkhtmltopdf the bundle's PATH gives the library: it must be the gem's, and the only one
    local p d
    p=$(bundle exec sh -c 'command -v wkhtmltopdf') || fail "no wkhtmltopdf on the bundle's PATH"
    grep -q "marqius-wkhtmltopdf" "$p" || fail "$p is not the gem's wkhtmltopdf"
    IFS=: read -r -a dirs <<< "$(bundle exec sh -c 'echo "$PATH"')"
    for d in "${dirs[@]}"; do
        if [ -x "$d/wkhtmltopdf" ] && ! grep -q "marqius-wkhtmltopdf" "$d/wkhtmltopdf"; then
            fail "another wkhtmltopdf is on the PATH: $d/wkhtmltopdf"
        fi
    done
    echo "$p"
}

expect() { # LOG PATTERN: the runner's summary line, which must match PATTERN
    local line
    line=$(grep -E "$2" "$1" | tail -n 1) || true
    [ -n "$line" ] || fail "the suite's summary is not $2: $(tail -n 3 "$1" | tr '\n' ' ')"
    echo "summary: $line"
}

case $lib in
wicked_pdf)
    # wicked_pdf 2.7.0, as library-tests runs it: Ruby 3.2 with Rails 7.0, the newest its CI ran.
    # Rails 7.0 starts only with logger loaded first (RUBYOPT=-rlogger, for today's concurrent-ruby)
    # and with minitest older than 5.25. Its tests take the program from WKHTMLTOPDF_BIN, as its CI
    # gives them its distribution's /usr/bin/wkhtmltopdf.
    fetch mileszs/wicked_pdf edcd80e7a96b5fe79476f7984e5ff8f3765f220d
    export RUBYOPT=-rlogger BUNDLE_GEMFILE=$src/gemfiles/7.0.gemfile
    printf "\ngem 'minitest', '~> 5.24.0'\n" >> "$BUNDLE_GEMFILE"
    gemfile "$BUNDLE_GEMFILE"
    retry 3 bundle install --jobs 4
    bundle exec rake dummy_generate > /dev/null && [ -f test/dummy/config/environment.rb ]
    bundle exec ruby -e 'print Gem.loaded_specs.fetch("marqius-wkhtmltopdf").full_name'; echo
    gem_cmd=$(found)
    by_itself=$(bundle exec ruby -e 'require "wicked_pdf"; print WickedPdf::Binary.new(nil).path')
    [ "$by_itself" = "$gem_cmd" ] || fail "wicked_pdf finds $by_itself by itself, not the gem's $gem_cmd"
    named=$(bundle exec ruby -e 'require "marqius-wkhtmltopdf"; print MarqiusWkhtmltopdf.executable_path')
    for bin in "$by_itself" "$named"; do
        say "wicked_pdf's tests with WKHTMLTOPDF_BIN=$bin"
        WKHTMLTOPDF_BIN=$bin bundle exec rake setup_and_run_tests TESTOPTS=-v 2>&1 | tee "$work/$lib.log"
        [ "${PIPESTATUS[0]}" = 0 ] || fail "wicked_pdf's tests failed with $bin"
        expect "$work/$lib.log" '^[0-9]+ runs, [0-9]+ assertions, 0 failures, 0 errors'
    done
    ;;
pdfkit)
    # PDFKit v0.8.7.3, as library-tests runs it: Ruby 3.1 with Rails 7.0, its CI's newest pair;
    # `rake` is rspec. Its tests find wkhtmltopdf themselves (`bundle exec which wkhtmltopdf`), or
    # take it from spec/custom_wkhtmltopdf_path.rb, which its spec helper loads when it is there.
    fetch pdfkit/pdfkit 762b366e9420f8d2b9fc50a372b51094a0247dd4
    export RUBYOPT=-rlogger RAILS_VERSION='~> 7.0.0'
    gemfile Gemfile
    retry 3 bundle install --jobs 4
    bundle exec ruby -e 'print Gem.loaded_specs.fetch("marqius-wkhtmltopdf").full_name'; echo
    gem_cmd=$(found)
    by_itself=$(bundle exec ruby -e 'require "pdfkit"; print PDFKit.configuration.wkhtmltopdf')
    [ "$by_itself" = "$gem_cmd" ] || fail "PDFKit finds $by_itself by itself, not the gem's $gem_cmd"
    say "PDFKit's tests, finding wkhtmltopdf themselves ($by_itself)"
    bundle exec rspec 2>&1 | tee "$work/$lib.log"
    [ "${PIPESTATUS[0]}" = 0 ] || fail "PDFKit's tests failed with $by_itself"
    expect "$work/$lib.log" '^[0-9]+ examples, 0 failures'
    say "PDFKit's tests with MarqiusWkhtmltopdf.executable_path, in spec/custom_wkhtmltopdf_path.rb"
    {
        echo 'require "marqius-wkhtmltopdf"'
        ruby "$here/tests/readme.rb" "example: pdfkit"
    } > spec/custom_wkhtmltopdf_path.rb
    cat spec/custom_wkhtmltopdf_path.rb
    bundle exec rspec 2>&1 | tee "$work/$lib.log"
    [ "${PIPESTATUS[0]}" = 0 ] || fail "PDFKit's tests failed with MarqiusWkhtmltopdf.executable_path"
    expect "$work/$lib.log" '^[0-9]+ examples, 0 failures'
    rm spec/custom_wkhtmltopdf_path.rb
    ;;
*)
    fail "no such library"
    ;;
esac
say "$lib: its own tests pass with marqius-wkhtmltopdf, found by itself and named by executable_path"
