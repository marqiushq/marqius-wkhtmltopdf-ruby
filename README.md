# marqius-wkhtmltopdf: the wkhtmltopdf gem for Rails, wicked_pdf and PDFKit

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, as a Ruby gem.** Add one line to your Gemfile, and wicked_pdf or PDFKit keep making PDFs on Heroku-24, Debian 13, Alpine and macOS, with no other change. It replaces the `wkhtmltopdf-binary` gem, and it runs on Windows too.

## How do I install wkhtmltopdf in a Rails app?

Add the gem to your Gemfile:

<!-- install -->
```ruby
gem "marqius-wkhtmltopdf"
```

Then install it:

<!-- bundle -->
```bash
bundle install
```

That's all. Bundler picks the gem for your computer, and that gem carries the program, so nothing else is downloaded, at install or when your app runs. It works in CI too. For a server that cannot reach the internet, install from `bundle cache --all-platforms`.

Do you work on a Mac and deploy to Linux? Add Linux to your `Gemfile.lock` once:

<!-- lock -->
```bash
bundle lock --add-platform x86_64-linux aarch64-linux
```

## What replaces the wkhtmltopdf-binary gem?

marqius-wkhtmltopdf does. In your Gemfile, replace `gem "wkhtmltopdf-binary"` with `gem "marqius-wkhtmltopdf"`, then run `bundle install`. On Linux and macOS, wicked_pdf and PDFKit find the new program by themselves.

wkhtmltopdf-binary is a 450 MB download of wkhtmltopdf builds made for older systems. Each marqius-wkhtmltopdf gem is about 9 MB and carries one maintained program, for your platform.

## How do I use wkhtmltopdf with wicked_pdf on Heroku-24 or Debian 13?

Install the gem. On Linux and macOS, wicked_pdf finds it by itself, so you change nothing else.

Your code may name the program, for example with `Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")` or `/usr/local/bin/wkhtmltopdf`. If so, point it at the gem instead; on Windows, always do this. In `config/initializers/wicked_pdf.rb`:

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

## How do I use wkhtmltopdf with PDFKit?

Install the gem. On Linux and macOS, PDFKit finds it by itself. To name it yourself, as on Windows:

<!-- example: pdfkit -->
```ruby
PDFKit.configure do |config|
  config.wkhtmltopdf = MarqiusWkhtmltopdf.executable_path
end
```

## Why do I get "wkhtmltopdf not found" errors?

Your library cannot find a wkhtmltopdf program:

- wicked_pdf says "Location of wkhtmltopdf unknown" or "Bad wkhtmltopdf's path".
- PDFKit says "No wkhtmltopdf executable found".

Install this gem. On Linux and macOS, both libraries then find the program by themselves. If your code names a path, or you are on Windows, point it at `MarqiusWkhtmltopdf.executable_path`, as shown above.

## Why does wkhtmltopdf fail with "libssl.so.1.1: cannot open shared object file"?

Your wkhtmltopdf was built for an older system. It needs OpenSSL 1.1, which Heroku-24 (Ubuntu 24.04) and Debian 13 no longer include. marqius-wkhtmltopdf needs no system libraries, so it runs there as it is.

## Which systems does marqius-wkhtmltopdf run on?

It runs on:

- Linux on x86-64 and ARM64, with glibc or musl (so Alpine too);
- Macs with Apple silicon;
- Windows on x64.

Bundler installs the right gem for each. It needs no X server, Qt or system libraries. In a slim or Alpine image without fonts, the program says so and prints the one line that installs them.

## Is marqius-wkhtmltopdf free?

You can try it free for 30 days. Personal, teaching and open-source use is free with a [Community licence](https://marqius.com/wkhtmltopdf-buy/#community): sign in with Google and your free key is waiting in your account.

Anything done by or for a business, including internal tools and client work, needs Starter or above once the trial ends. Starter is $290 USD a year for organisations of up to 10 people, and Business $990 USD a year, plus applicable taxes.

Your PDFs never stop. Without a licence after the trial, each page carries one line, "Prepared by Marqius, Purchase Licence". [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## How do I add my licence key?

Set the `MARQIUS_LICENCE` environment variable to your licence; that is the way for Heroku, containers and CI. Or save it as `licence.txt` and run `bundle exec marqius-wkhtmltopdf licence add licence.txt`.

To see the trial's days left, or the licence in force:

<!-- licence -->
```bash
bundle exec marqius-wkhtmltopdf licence
```

## Does it pass wicked_pdf's and PDFKit's own tests?

Yes. wicked_pdf and PDFKit pass their own test suites with marqius-wkhtmltopdf: all 45 of wicked_pdf's tests, and PDFKit's with no failures. The results are public: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests).

Before each version of this gem is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-ruby/blob/main/.github/workflows/release.yml) runs:

- both suites again, with the gem itself, on Linux (x86-64 and ARM64);
- the install steps and examples on this page, on Linux, macOS and Windows.

## How do I update it?

Each version of this gem carries the marqius-wkhtmltopdf release with the same number. To move to the newest:

<!-- update -->
```bash
bundle update marqius-wkhtmltopdf
```

This gem's own Ruby files are under the MIT licence: [LICENSE.md](LICENSE.md).
