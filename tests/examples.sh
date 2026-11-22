#!/bin/sh
# Runs this README's lines exactly as printed, each library in a new project, and checks the PDFs.
#
#   tests/examples.sh WORK [LIBRARY ...]     LIBRARY: pdfkit, wicked_pdf, wicked_pdf-2.7 or plain
#
# For each library, in a new project with the library, the README's Gemfile line and the README's
# `bundle install` line:
#   1. nothing configured, as in most apps: the library finds the gem's wkhtmltopdf with Bundler by
#      itself (and no other wkhtmltopdf is there to find), and makes a PDF;
#   2. the README's lines that name MarqiusWkhtmltopdf.executable_path, and a PDF made with them;
#   3. the README's `bundle lock` line, which must lock the gem for Linux x86-64 and ARM64;
#   4. the README's `bundle update` line, after which Bundler keeps this machine's gem;
#   5. the README's `licence` line, which shows the trial or the licence.
# Each PDF must start with %PDF-, name marqius as its producer and, where pdftotext is, read
# Invoice 42. `plain` checks what the plain ruby gem says on a platform that has no gem.
#
# Before the gem is on RubyGems, set GEMS to the folder of the built gems: they go into each
# project's vendor/cache, where Bundler chooses this machine's gem as it would from RubyGems, and the
# Gemfile line runs as printed. PLATFORM, if set, is the gem that must be chosen (x86_64-linux, ...).
# ZERO_CONFIG=no leaves out step 1 (Windows: libraries there cannot start the gem's commands).
# HEROKU=yes installs as Heroku's Ruby buildpack does: once Gemfile.lock holds Linux (the README's
# lock line, as before a first deploy), a frozen install into vendor/bundle, its binstubs in
# vendor/bundle/bin; steps 1, 2 and 5 then run on that bundle (3 ran before it, 4 cannot run frozen).
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
work=$1
shift
libraries=${*:-pdfkit wicked_pdf wicked_pdf-2.7 plain}
say() { printf '\n== %s\n' "$*"; }
fail() {
    echo "FAIL $lib: $*" >&2
    exit 1
}
readme() { ruby "$here/tests/readme.rb" "$1"; }
retry() { # for what fetches gems from the network, never for the checks
    n=1
    until "$@"; do
        [ "$n" -ge 3 ] && return 1
        echo "retrying ($n): $*" >&2
        sleep $((n * 10))
        n=$((n + 1))
    done
}

project() { # a new project: the library, then the README's Gemfile line, as printed
    dir=$work/$lib
    rm -rf "$dir"
    mkdir -p "$dir"
    cd "$dir"
    printf 'source "https://rubygems.org"\n\n%s\n' "$1" >Gemfile
    readme install >>Gemfile
    if [ -n "${GEMS:-}" ]; then
        mkdir -p vendor/cache
        cp "$GEMS"/marqius-wkhtmltopdf-*.gem vendor/cache/
    fi
    cat Gemfile
    line=$(readme bundle)
    say "$line"
    retry sh -c "$line" >bundle.log 2>&1 || { cat bundle.log; fail "$line"; }
    if [ "${HEROKU:-no}" = yes ]; then
        lock
        bundle config set --local deployment true
        bundle config set --local path vendor/bundle
        bundle config set --local bin vendor/bundle/bin
        bundle config set --local without development:test
        retry bundle install >>bundle.log 2>&1 || { cat bundle.log; fail "bundle install, frozen, into vendor/bundle"; }
        at=$(bundle exec ruby -e 'print Gem.loaded_specs.fetch("marqius-wkhtmltopdf").full_gem_path')
        case $at in */vendor/bundle/*) echo "installed as Heroku installs: $at" ;; *) fail "the gem is at $at, not in vendor/bundle" ;; esac
    fi
    chosen=$(bundle exec ruby -e 'print Gem.loaded_specs.fetch("marqius-wkhtmltopdf").platform')
    echo "Bundler chose marqius-wkhtmltopdf for $chosen"
    [ "$chosen" != ruby ] || fail "Bundler chose the plain ruby gem"
    [ -z "${PLATFORM:-}" ] || [ "$chosen" = "$PLATFORM" ] || fail "Bundler chose $chosen, not $PLATFORM"
}

check() { # a PDF made by marqius-wkhtmltopdf that reads Invoice 42
    [ -s "$1" ] || fail "no $1"
    [ "$(head -c 5 "$1")" = "%PDF-" ] || fail "$1 is not a PDF"
    grep -q 'pdf:Producer>marqius ' "$1" || fail "$1 was not made by marqius-wkhtmltopdf"
    if command -v pdftotext >/dev/null 2>&1; then
        pdftotext "$1" - | grep -q 'Invoice 42' || fail "$1 does not read Invoice 42"
    fi
    echo "ok $lib: $1 ($(wc -c <"$1" | tr -d ' ') bytes)"
}

zero() { # step 1: nothing configured; $1 is Ruby that makes zero.pdf and prints the program it ran
    [ "${ZERO_CONFIG:-yes}" = no ] && return
    found=$(bundle exec sh -c 'command -v wkhtmltopdf') || fail "no wkhtmltopdf on the bundle's PATH"
    grep -q "marqius-wkhtmltopdf" "$found" || fail "$found is not the gem's wkhtmltopdf"
    path=$(bundle exec sh -c 'echo "$PATH"')
    old_ifs=$IFS
    IFS=:
    for d in $path; do
        [ -x "$d/wkhtmltopdf" ] && ! grep -q "marqius-wkhtmltopdf" "$d/wkhtmltopdf" && fail "another wkhtmltopdf is on the PATH: $d/wkhtmltopdf"
    done
    IFS=$old_ifs
    ran=$(bundle exec ruby -e "require 'bundler/setup'; Bundler.require; $1")
    echo "$lib found $ran by itself"
    [ "$ran" = "$found" ] || fail "$lib ran $ran, not the gem's $found"
    check zero.pdf
}

readme_lines() { # step 2: the README's lines for the library, then $2, which makes invoice.pdf
    { echo 'require "bundler/setup"'; echo 'Bundler.require'; readme "$1"; echo "$2"; } >render.rb
    cat render.rb
    bundle exec ruby render.rb
    check invoice.pdf
}

lock() { # step 3: the README's bundle lock line, as printed
    line=$(readme lock)
    say "$line"
    sh -c "$line" >lock.log 2>&1 || { cat lock.log; fail "$line"; }
    for p in x86_64-linux aarch64-linux; do
        grep -q "^    marqius-wkhtmltopdf (.*-$p)$" Gemfile.lock || fail "Gemfile.lock has no marqius-wkhtmltopdf for $p"
    done
    echo "ok $lib: Gemfile.lock holds marqius-wkhtmltopdf for x86_64-linux and aarch64-linux"
}

update() { # step 4: the README's bundle update line, as printed
    line=$(readme update)
    say "$line"
    retry sh -c "$line" >update.log 2>&1 || { cat update.log; fail "$line"; }
    after=$(bundle exec ruby -e 'print Gem.loaded_specs.fetch("marqius-wkhtmltopdf").platform')
    [ "$after" = "$chosen" ] || fail "after $line, Bundler chose $after, not $chosen"
    echo "ok $lib: after $line, Bundler keeps marqius-wkhtmltopdf for $after"
}

after_heroku() { # steps 3 and 4, except on a frozen Heroku-style bundle (3 ran before it)
    [ "${HEROKU:-no}" = yes ] && return
    lock
    update
}

for lib in $libraries; do
    say "$lib ($(ruby -e 'print RUBY_DESCRIPTION'); RubyGems $(gem --version); $(bundle --version))"
    case $lib in
    pdfkit)
        project 'gem "pdfkit"'
        zero 'PDFKit.new("<h1>Invoice 42</h1>").to_file("zero.pdf"); print PDFKit.configuration.wkhtmltopdf'
        readme_lines "example: pdfkit" '
PDFKit.new("<h1>Invoice 42</h1>").to_file("invoice.pdf")
abort "PDFKit runs #{PDFKit.configuration.wkhtmltopdf}" unless PDFKit.configuration.wkhtmltopdf == MarqiusWkhtmltopdf.executable_path'
        after_heroku
        ;;
    wicked_pdf | wicked_pdf-2.7)
        if [ "$lib" = wicked_pdf ]; then
            project 'gem "wicked_pdf"'
        else
            project 'gem "wicked_pdf", "~> 2.7.0"'
        fi
        zero 'File.binwrite("zero.pdf", WickedPdf.new.pdf_from_string("<h1>Invoice 42</h1>")); print WickedPdf::Binary.new(nil).path'
        readme_lines "example: $(echo "$lib" | sed 's/-/ /')" '
File.binwrite("invoice.pdf", WickedPdf.new.pdf_from_string("<h1>Invoice 42</h1>"))
abort "wicked_pdf runs #{WickedPdf.config[:exe_path]}" unless WickedPdf.config[:exe_path] == MarqiusWkhtmltopdf.executable_path'
        after_heroku
        ;;
    plain)
        # the plain ruby gem, as Bundler installs it where no platform gem fits the lockfile
        [ -n "${GEMS:-}" ] || continue
        dir=$work/plain
        rm -rf "$dir"
        mkdir -p "$dir"
        GEM_HOME=$dir GEM_PATH=$dir gem install --local --no-document "$GEMS"/marqius-wkhtmltopdf-[0-9]*[0-9].gem
        said=$(GEM_HOME=$dir GEM_PATH=$dir ruby -e 'require "marqius-wkhtmltopdf"
begin
  MarqiusWkhtmltopdf.executable_path
rescue MarqiusWkhtmltopdf::Error => e
  abort e.message
end' 2>&1) && fail "no error"
        echo "$said"
        echo "$said" | grep -q 'bundle lock --add-platform ' || fail "the message does not say how to add the platform"
        [ "$(echo "$said" | wc -l | tr -d ' ')" = 1 ] || fail "the message is more than one line"
        said=$(GEM_HOME=$dir GEM_PATH=$dir "$dir/bin/wkhtmltopdf" -V 2>&1) && fail "wkhtmltopdf ran"
        echo "$said" | grep -q '^marqius-wkhtmltopdf: Bundler installed' || fail "wkhtmltopdf said: $said"
        echo "ok plain: one line, naming the command that adds the platform"
        continue
        ;;
    *)
        fail "no such library"
        ;;
    esac
    bundle exec marqius-wkhtmltopdf --version | grep '^marqius-wkhtmltopdf [0-9]' || fail "marqius-wkhtmltopdf --version"
    bundle exec ruby -e 'Bundler.require; system(MarqiusWkhtmltopdf.executable_path, "-V", exception: true)' | grep "compatible; marqius-wkhtmltopdf" || fail "executable_path -V"
    line=$(readme licence) # step 5, as printed
    said=$(sh -c "$line" 2>&1) || { echo "$said"; fail "$line"; }
    echo "$said" | head -n 2
    echo "$said" | grep -q -i -E 'trial|licen' || fail "$line said: $said"
done
say "all passed: $libraries"
