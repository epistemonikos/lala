# Set server stages
set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

# Server-side information.
set :application, "lala"
set :user,        "deploy"
set :deploy_to,   "/home/#{user}/applications/#{application}"

# Repository (if any) configuration.
set :deploy_via, :remote_cache
set :repository, "git@github.com:dperezrada/lala.git"
# set :git_enable_submodules, 1

# Database
# set :migrate_env,    "migration"

# Unicorn
set :unicorn_workers, 1

# Cleanup after deploy
set :keep_releases, 3
after "deploy", "deploy:cleanup"