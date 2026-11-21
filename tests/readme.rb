# frozen_string_literal: true

# Prints the README's code block that follows "<!-- NAME -->", exactly as printed:
#     ruby tests/readme.rb "example: pdfkit"
readme = File.read(File.expand_path("../README.md", __dir__), encoding: "utf-8")
marker = "<!-- #{ARGV.fetch(0)} -->"
at = readme.index(marker) or abort "README.md has no #{marker}"
block = readme[(at + marker.size)..][/\A\s*```[a-z]*\n(.*?)\n```/m, 1] or abort "README.md has no code block after #{marker}"
puts block
