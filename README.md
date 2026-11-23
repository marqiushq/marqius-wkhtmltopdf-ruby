# marqius-wkhtmltopdf: the wkhtmltopdf gem for Rails, wicked_pdf and PDFKit

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, as a Ruby gem.** Add one line to your Gemfile, and wicked_pdf or PDFKit keep making PDFs on Heroku-24, Debian 13, Alpine and macOS, with no other change. It replaces the `wkhtmltopdf-binary` gem, and it runs on Windows too. It prints Arabic, Hebrew, Hindi, Thai, Chinese, Japanese and Korean as well as English.

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

## Which languages can it print?

All of these, even on one page. Each one is tested on real invoices, letters and receipts, and the PDF keeps the words as text, so you can search and copy them.

| Language | On a Linux server | On a Mac or Windows |
|---|---|---|
| English, French, German, Spanish and other languages in Latin letters; Greek; Russian | Works with the fonts most servers have | Works |
| Arabic and Hebrew, from right to left | Works: the fonts are built in | Works |
| Hindi and Thai | Install `fonts-noto-core` | Works |
| Chinese, Japanese and Korean | Install `fonts-noto-cjk` | Works |

On Debian or Ubuntu, this one line installs the fonts for every language above:

<!-- fonts: debian -->
```bash
sudo apt-get update && sudo apt-get install -y fonts-noto-core fonts-noto-cjk
```

In a Dockerfile, put the same line after `RUN`, without `sudo`. On Alpine, Fedora, Red Hat or Arch, the program tells you the line for your system ([see below](#why-do-letters-show-as-boxes-or-blanks-in-my-pdf)).

Then one invoice can carry them all, here with PDFKit:

<!-- example: languages -->
```ruby
html = <<~HTML
  <!doctype html>
  <meta charset="utf-8">
  <h1>Invoice 42</h1>
  <p lang="ar" dir="rtl">فاتورة 42</p>
  <p lang="he" dir="rtl">חשבונית 42</p>
  <p lang="hi">चालान 42</p>
  <p lang="th">ใบแจ้งหนี้ 42</p>
  <p lang="zh">发票 42</p>
  <p lang="ja">請求書 42</p>
  <p lang="ko">청구서 42</p>
HTML

PDFKit.new(html).to_file("invoice.pdf")
```

With wicked_pdf, the same page works: `File.binwrite("invoice.pdf", WickedPdf.new.pdf_from_string(html))`.

For a page all in Arabic or Hebrew, put `dir="rtl"` on its `<html>` tag. The page then reads from the right, and its tables and lists turn to match.

## Why do letters show as boxes or blanks in my PDF?

The computer that makes the PDF has no font for them. On Linux, install the fonts [above](#which-languages-can-it-print). To see what is missing, convert your page with the program itself:

<!-- check -->
```bash
bundle exec wkhtmltopdf page.html page.pdf
```

It names each letter it could not print, then gives the one line that installs fonts for them on your system: `apt-get` on Debian and Ubuntu, `apk` on Alpine, `dnf` on Fedora and Red Hat, `pacman` on Arch.

## Why can't I search or copy Arabic, Chinese or Hindi text in my wkhtmltopdf PDF?

wkhtmltopdf often stores these scripts as shapes, not words. The public parity suite prints the same pages with both programs:

- **Arabic:** from wkhtmltopdf's invoice, 2 of its 56 words read back as written; from marqius-wkhtmltopdf's, 48.
- **Hebrew:** wkhtmltopdf splits many words into single letters (28 of 48 read back); marqius-wkhtmltopdf gives back 43.
- **Chinese:** wkhtmltopdf puts look-alike signs in place of some characters, so a search for the company's name finds nothing. marqius-wkhtmltopdf keeps the real characters.
- **Hindi and Thai:** wkhtmltopdf loses letters and splits off marks. marqius-wkhtmltopdf's text reads back clean.

The pages themselves look the same. [See every page and score](https://github.com/marqiushq/wkhtmltopdf-parity).

## Why are accented letters garbled, like Ã© for é?

Your page does not say that it is UTF-8, so wkhtmltopdf reads it as an old Western character set. marqius-wkhtmltopdf prints é, € and ü as written anyway. To make every program agree, put `<meta charset="utf-8">` at the top of your page.

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

Anything done by or for a business, including internal tools and client work, needs a paid plan once the trial ends. [See the plans and prices](https://marqius.com/licence/marqius-wkhtmltopdf).

Your PDFs never stop. Without a licence after the trial, each page carries one line, "Prepared by Marqius, Purchase Licence". [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

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
- the install steps and examples on this page, the eight-language invoice among them, on Linux, macOS and Windows.

## How do I update it?

Each version of this gem carries the marqius-wkhtmltopdf release with the same number. To move to the newest:

<!-- update -->
```bash
bundle update marqius-wkhtmltopdf
```

This gem's own Ruby files are under the MIT licence: [LICENSE.md](LICENSE.md).
