# marqius-wkhtmltopdf for Ruby

**marqius-wkhtmltopdf** is the maintained drop-in replacement for wkhtmltopdf. This gem puts it in your Ruby or Rails app in place of `wkhtmltopdf-binary`: keep wicked_pdf or PDFKit, your templates and your PDF calls. It runs on Linux (x86-64 and ARM64, glibc and musl, Heroku-24 and Debian 13 included), Apple silicon Macs and Windows (x64), and needs no X server, Qt or system libraries.

## Install

In your Gemfile, in place of `gem "wkhtmltopdf-binary"`:

<!-- install -->
```ruby
gem "marqius-wkhtmltopdf"
```

Then run `bundle install`. Bundler installs the gem for your platform, which carries the program itself: nothing is downloaded at install or when your code runs, so it works in CI and on servers without internet access.

If you work on a Mac and deploy to Linux, add Linux to your `Gemfile.lock` once:

<!-- lock -->
```bash
bundle lock --add-platform x86_64-linux aarch64-linux
```

## wicked_pdf and PDFKit

On Linux and macOS, wicked_pdf and PDFKit find the gem's `wkhtmltopdf` as they found wkhtmltopdf-binary's: nothing else changes.

If your code names the program, for instance with `Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")` or `/usr/local/bin/wkhtmltopdf`, name `MarqiusWkhtmltopdf.executable_path` instead. On Windows, always name it.

### wicked_pdf

In `config/initializers/wicked_pdf.rb`:

<!-- example: wicked_pdf -->
```ruby
WickedPdf.configure do |config|
  config.exe_path = MarqiusWkhtmltopdf.executable_path
end
```

wicked_pdf 2.7 and earlier have no `WickedPdf.configure`. There, write:

<!-- example: wicked_pdf 2.7 -->
```ruby
WickedPdf.config[:exe_path] = MarqiusWkhtmltopdf.executable_path
```

### PDFKit

<!-- example: pdfkit -->
```ruby
PDFKit.configure do |config|
  config.wkhtmltopdf = MarqiusWkhtmltopdf.executable_path
end
```

## Proof

wicked_pdf and PDFKit pass their own test suites with marqius-wkhtmltopdf, on GitHub's machines, for every release: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests). Before each version of this gem is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-ruby/blob/main/.github/workflows/release.yml) runs both suites again with the gem itself, on Linux (x86-64 and ARM64), and the lines above on Linux, macOS and Windows.

## Updates

Each version of this gem carries the marqius-wkhtmltopdf release with the same number. To move to the newest:

```bash
bundle update marqius-wkhtmltopdf
```

## Licence

marqius-wkhtmltopdf is commercial software from Simple AI LLC, free for 30 days from its first run. After the trial, without a licence, each page carries one line, "Prepared by Marqius, Purchase Licence". Personal, teaching and open-source use is free with a Community licence. For business use, Starter is $290 USD a year for organisations of up to 10 people, and Business $990 USD a year, plus applicable taxes. [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

Give the program your licence in the `MARQIUS_LICENCE` environment variable, the way for Heroku, containers and CI, or store it with `bundle exec marqius-wkhtmltopdf licence add licence.txt`. `bundle exec marqius-wkhtmltopdf licence` shows the trial's days left.

This gem's own Ruby files are under the MIT licence: [LICENSE.md](LICENSE.md).
