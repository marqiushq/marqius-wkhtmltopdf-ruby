# frozen_string_literal: true

# The plain ruby gem as it stands; build.rb makes the gem for each platform from it, each carrying
# the program for its platform.
require_relative "lib/marqius_wkhtmltopdf"

Gem::Specification.new do |spec|
  spec.name = "marqius-wkhtmltopdf"
  spec.version = MarqiusWkhtmltopdf::VERSION
  spec.authors = ["Simple AI LLC"]
  spec.email = ["hello@marqius.com"]
  spec.summary = "The wkhtmltopdf gem for Rails, wicked_pdf and PDFKit: a maintained drop-in " \
                 "replacement for wkhtmltopdf-binary that works on Heroku-24 and Debian 13 " \
                 "(commercial, 30-day trial)"
  spec.description = "Add one line to your Gemfile and wicked_pdf or PDFKit keep making PDFs on " \
                     "Heroku-24, Debian 13, Alpine and macOS, with no other change; it runs on " \
                     "Windows too. It replaces the wkhtmltopdf-binary gem and fixes \"wkhtmltopdf " \
                     "not found\" and \"libssl.so.1.1\" errors. Each platform's gem carries the " \
                     "program, so nothing else is downloaded. Personal, teaching and open-source " \
                     "use is free with a Community licence."
  spec.homepage = "https://marqius.com/wkhtmltopdf/"
  spec.license = "LicenseRef-marqius-wkhtmltopdf"
  spec.metadata = {
    "homepage_uri" => "https://marqius.com/wkhtmltopdf/",
    "source_code_uri" => "https://github.com/marqiushq/marqius-wkhtmltopdf-ruby",
    "documentation_uri" => "https://marqius.com/download/developer-manual.pdf",
    "changelog_uri" => "https://github.com/marqiushq/marqius-wkhtmltopdf/releases",
    "bug_tracker_uri" => "https://github.com/marqiushq/marqius-wkhtmltopdf-ruby/issues",
  }
  spec.required_ruby_version = ">= 2.7"
  spec.files = %w[
    LICENSE.md README.md
    exe/marqius-wkhtmltopdf exe/wkhtmltoimage exe/wkhtmltopdf
    lib/marqius-wkhtmltopdf.rb lib/marqius_wkhtmltopdf.rb
  ]
  spec.bindir = "exe"
  spec.executables = %w[wkhtmltopdf wkhtmltoimage marqius-wkhtmltopdf]
  spec.require_paths = ["lib"]
end
