#!/usr/bin/env ruby
# frozen_string_literal: true

# Builds the gems of one release of marqius-wkhtmltopdf: one per platform, and the plain ruby gem.
#
#     ruby build.rb VERSION BUILDS OUT
#
# BUILDS holds the release's programs, checked by `.github/release.py fetch` (its SHA256SUMS is
# checked again here). Each platform gem carries the program for its platform, the MarqiusWkhtmltopdf
# module and the wkhtmltopdf, wkhtmltoimage and marqius-wkhtmltopdf commands. The Linux programs are
# static, so each Linux gem serves glibc and musl alike. The plain ruby gem carries no program: it is
# what Bundler installs on a platform with no gem of its own, and it says so when the program is
# asked for. The gems are reproducible: the same programs make the same files. Only Ruby's standard
# library is used.
require "digest"
require "fileutils"
require "rubygems/package"
require "tmpdir"

HERE = __dir__
# program in the release -> RubyGems platform
PLATFORMS = {
  "linux-x86_64" => "x86_64-linux",
  "linux-arm64" => "aarch64-linux",
  "macos-arm64" => "arm64-darwin",
  "windows-x86_64.exe" => "x64-mingw-ucrt",
}.freeze
EPOCH = "1767225600" # 2026-01-01: every file's date in the gems, so that gems are reproducible

# Unix: a few lines of sh start the program as wkhtmltopdf, for MarqiusWkhtmltopdf.executable_path
LAUNCHER = <<~'SH'
  #!/bin/sh
  # Runs marqius-wkhtmltopdf as wkhtmltopdf, for libraries given this file's path by
  # MarqiusWkhtmltopdf.executable_path. marqius-wkhtmltopdf is commercial software with a 30-day free
  # trial: marqius.com/wkhtmltopdf
  self=$0
  while [ -h "$self" ]; do
      link=$(readlink "$self")
      case $link in /*) self=$link ;; *) self=${self%/*}/$link ;; esac
  done
  case $self in */*) here=${self%/*} ;; *) here=. ;; esac
  exec "$here/marqius-wkhtmltopdf" wkhtmltopdf "$@"
SH

def put(dir, name, data, executable)
  path = File.join(dir, name)
  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, data)
  File.chmod(executable ? 0o755 : 0o644, path) # the gem keeps each file's mode
end

# One gem: the module and commands, with VERSION set, and the program for +platform+ (none for ruby)
def build_gem(version, platform, program, out)
  spec = Dir.chdir(HERE) { Gem::Specification.load("marqius-wkhtmltopdf.gemspec") }&.dup or abort "no gemspec"
  Dir.mktmpdir do |dir|
    spec.files.each do |name|
      data = File.binread(File.join(HERE, name))
      if name == "lib/marqius_wkhtmltopdf.rb"
        n = 0
        data = data.gsub(/^  VERSION = "[^"]*"$/) { n += 1; %(  VERSION = "#{version}") }
        abort "#{name} has no single VERSION line" unless n == 1
      end
      put(dir, name, data, name.start_with?("exe/"))
    end
    spec.version = version
    if platform
      windows = platform.include?("mingw")
      exe = windows ? "libexec/marqius-wkhtmltopdf.exe" : "libexec/marqius-wkhtmltopdf"
      put(dir, exe, program, true)
      spec.files += [exe]
      unless windows
        put(dir, "libexec/wkhtmltopdf", LAUNCHER, true)
        spec.files += ["libexec/wkhtmltopdf"]
      end
      spec.platform = Gem::Platform.new(platform)
    end
    file = Dir.chdir(dir) { Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) { Gem::Package.build(spec) } }
    FileUtils.mv(File.join(dir, file), File.join(out, file))
    File.join(out, file)
  end
end

abort "usage: ruby build.rb VERSION BUILDS OUT" unless ARGV.size == 3
version, builds, out = ARGV
abort "not a version: #{version}" unless version.match?(/\A\d+(\.\d+)+\z/)
ENV["SOURCE_DATE_EPOCH"] = EPOCH
FileUtils.mkdir_p(out)
out = File.expand_path(out)
sums = File.readlines(File.join(builds, "SHA256SUMS")).to_h { |line| line.split.reverse }
PLATFORMS.each do |build, platform|
  name = "marqius-wkhtmltopdf-#{build}"
  program = File.binread(File.join(builds, name))
  abort "#{name} does not match SHA256SUMS" unless sums[name] == Digest::SHA256.hexdigest(program)
  made = build_gem(version, platform, program, out)
  puts "#{File.basename(made)} (#{File.size(made).to_s.reverse.scan(/\d{1,3}/).join(',').reverse} bytes)"
end
made = build_gem(version, nil, nil, out)
puts "#{File.basename(made)} (#{File.size(made)} bytes)"
