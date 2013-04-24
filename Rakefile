require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

namespace :hooks do
  task :load do
    require File.expand_path("../config/load", __FILE__)
  end

  desc "Writes JSON config to FILE || config/hooks.json, Docs to DOCS"
  task :build => [:config, :docs]

  desc "Writes a JSON config to FILE || config/hooks.json"
  task :config => :load do
    file = ENV["FILE"] || default_hooks_config
    hooks = []
    Hook.load_hooks
    Hook.hooks.each do |svc|
      hooks << {:name => svc.hook_name, :events => svc.default_events, :supported_events => svc.supported_events,
        :title => svc.title, :schema => svc.schema}
    end
    hooks.sort! { |x, y| x[:name] <=> y[:name] }
    data = {
      :metadata => { :generated_at => Time.now.utc },
      :hooks => hooks
    }
    puts "Writing config to #{file}"
    File.open file, 'w' do |io|
      io << Yajl.dump(data, :pretty => true)
    end
  end

  desc "Writes Docs to DOCS"
  task :docs => :load do
    dir = ENV['DOCS'] || default_docs_dir
    docs = Dir[File.expand_path("../docs/*", __FILE__)]
    docs.each do |path|
      name = File.basename(path)
      next if P4bDocs.include?(name)
      new_name = dir.include?('{name}') ? dir.sub('{name}', name) : File.join(dir, name)
      new_dir = File.dirname(new_name)
      FileUtils.mkdir_p(new_dir)
      puts "COPY #{path} => #{new_name}"
      FileUtils.cp(path, new_name)
    end
  end

  require 'set'
  P4bDocs = Set.new(%w(payload_data))

  def base_p4b_path
    ENV['P4B_PATH'] || "#{ENV['HOME']}/git/pay4bugs"
  end

  def default_hooks_config
    "#{base_p4b_path}/config/hooks.json"
  end

  def default_docs_dir
    "#{base_p4b_path}/app/views/c/projects/hooks/_{name}.html.md"
  end
end
