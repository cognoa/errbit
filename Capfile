# Load DSL and Setup Up Stages
require "capistrano/setup"
require "capistrano/deploy"

# Use Git
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Other Plugins
require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/rails"
require "capistrano/puma"
require "capistrano/nginx"
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Workers
install_plugin Capistrano::Puma::Monit
install_plugin Capistrano::Puma::Nginx

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob("lib/capistrano/tasks/*.cap").each { |r| import r }
