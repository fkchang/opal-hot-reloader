require "bundler/gem_tasks"
require 'opal'
require 'opal-rspec'
require 'opal_hot_reloader'     # load this server side to setup opal paths
require 'opal/sprockets/environment'
require 'opal/rspec/rake_task'

require "rspec/core/rake_task"


Opal.append_path File.expand_path('../spec-opal', __FILE__)
Opal::RSpec::RakeTask.new("opal:spec") do |server, task|
  task.files = FileList['spec-opal/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
