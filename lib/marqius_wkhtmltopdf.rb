# frozen_string_literal: true

# marqius-wkhtmltopdf for Ruby's wkhtmltopdf libraries.
#
# MarqiusWkhtmltopdf.executable_path gives the installed program's path, to give wicked_pdf, PDFKit
# or another library where it asks for wkhtmltopdf:
#
#     WickedPdf.configure { |config| config.exe_path = MarqiusWkhtmltopdf.executable_path }
#
# Most apps need not: the gem's wkhtmltopdf command, which those libraries find with Bundler as they
# found wkhtmltopdf-binary's, starts the same program. The gem Bundler installs for each platform
# carries the program itself. marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a
# 30-day free trial: https://marqius.com/licence/marqius-wkhtmltopdf
module MarqiusWkhtmltopdf
  VERSION = "0.12.17"

  # The platforms with a gem that carries the program, in RubyGems' names. The Linux programs are
  # static, so each Linux gem serves glibc and musl (Alpine) alike.
  PLATFORMS = %w[x86_64-linux aarch64-linux arm64-darwin x64-mingw-ucrt].freeze

  # Raised when the gem installed here carries no program: the plain ruby gem.
  class Error < StandardError; end

  LIBEXEC = File.expand_path("../libexec", __dir__)
  WINDOWS = Gem.win_platform?
  private_constant :LIBEXEC, :WINDOWS

  # The installed program's path, as wkhtmltopdf: give it where a library asks for wkhtmltopdf.
  def self.executable_path
    exe = program
    return File.join(LIBEXEC, "wkhtmltopdf") unless WINDOWS # a few lines of sh that start it as wkhtmltopdf

    windows_name(exe, "wkhtmltopdf")
  end

  # The program under its own name, marqius-wkhtmltopdf, for the gem's commands. Not public API.
  def self.program # :nodoc:
    exe = File.join(LIBEXEC, WINDOWS ? "marqius-wkhtmltopdf.exe" : "marqius-wkhtmltopdf")
    return exe if File.file?(exe)

    here = Gem::Platform.local
    ours = PLATFORMS.find { |platform| Gem::Platform.new(platform) === here }
    raise Error, "marqius-wkhtmltopdf has no program for #{here}: it runs on #{PLATFORMS.join(', ')}; " \
                 "for another platform, write to hello@marqius.com" unless ours

    raise Error, "marqius-wkhtmltopdf: Bundler installed the gem without the program; add #{ours} to " \
                 "Gemfile.lock with `bundle lock --add-platform #{ours}`, then run `bundle install` " \
                 "(with Bundler's force_ruby_platform off)"
  end

  # On Windows the program answers to wkhtmltopdf.exe by its file name: a hard link beside it, made
  # once (a copy in the temporary folder where the gem's folder cannot be written).
  def self.windows_name(exe, name)
    require "tmpdir"
    size = File.size(exe)
    [LIBEXEC, File.join(Dir.tmpdir, "marqius-wkhtmltopdf-#{VERSION}")].each do |place|
      to = File.join(place, "#{name}.exe")
      return to if File.file?(to) && File.size(to) == size

      begin
        Dir.mkdir(place) unless File.directory?(place)
        File.delete(to) if File.exist?(to)
        begin
          File.link(exe, to)
        rescue SystemCallError, NotImplementedError
          File.binwrite(to, File.binread(exe))
        end
        return to
      rescue SystemCallError
        next # this folder cannot be written: try the next
      end
    end
    raise Error, "marqius-wkhtmltopdf cannot be given the name #{name}.exe: " \
                 "neither #{LIBEXEC} nor #{Dir.tmpdir} can be written"
  end
  private_class_method :windows_name
end
