# frozen_string_literal: true

# The plain ruby gem as it stands; build.rb makes the gem for each platform from it, each carrying
# the program for its platform.
require_relative "lib/marqius_wkhtmltopdf"

Gem::Specification.new do |spec|
  spec.name = "marqius-wkhtmltopdf"
  spec.version = MarqiusWkhtmltopdf::VERSION
  spec.authors = ["Simple AI LLC"]
  spec.email = ["hello@marqius.com"]
  spec.summary = "marqius-wkhtmltopdf, the maintained drop-in replacement for wkhtmltopdf, " \
                 "for wicked_pdf and PDFKit (commercial, 30-day trial)"
  spec.description = "The maintained drop-in replacement for wkhtmltopdf, in place of the " \
                     "wkhtmltopdf-binary gem: wicked_pdf and PDFKit find it with no change. Each " \
                     "platform's gem carries the program, so nothing is downloaded at install or " \
                     "when your code runs."
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
