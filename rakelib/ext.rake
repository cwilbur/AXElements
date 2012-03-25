module ExtHelpers
  def macruby?
    defined? MACRUBY_REVISION
  end

  def cruby?
    RUBY_ENGINE == 'ruby'
  end

  def needs_regeneration? source, bundle
    return true unless File.exists? bundle
    return true unless File.mtime(bundle) > File.mtime(source)
    return true if macruby? && ext_platform(bundle) == :cruby
    return true if cruby?   && ext_platform(bundle) == :macruby
  end

  def ext_platform bundle
    return :macruby if `otool -L #{bundle}`.match /MacRuby/
    return :cruby
  end
end


namespace :ext do
  extend ExtHelpers

  desc 'Compile C extensions'
  task :key_coder do
    dir = 'ext/accessibility/key_coder'
    ext = "#{dir}/key_coder"
    if needs_regeneration? "#{ext}.c", "#{ext}.bundle"
      Rake::Task['clobber:key_coder'].execute
      Dir.chdir(dir) do
        ruby 'extconf.rb'
        sh   'make'
      end
      cp "#{ext}.bundle", 'lib/accessibility'
    end
  end
end


desc 'Remove files generated by compiling key_coder'
task :clobber_key_coder do
  Dir.glob('{lib,ext}/**/key_coder{.bundle,.o}').each do |file|
    $stdout.puts "rm #{file}"
    rm_f file
  end
  file = 'rm ext/accessibility/key_coder/Makefile'
  $stdout.puts file
  rm_f file
end

desc 'Remove files generated by compiling extensions'
task :clobber_ext => [:clobber_key_coder]


if RUBY_ENGINE == 'macruby'
  require 'rake/compiletask'
  Rake::CompileTask.new
end
