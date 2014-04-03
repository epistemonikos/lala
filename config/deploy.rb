# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'lala'
set :repo_url, 'git@github.com:epistemonikos/lala.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/home/ubuntu/.rbenv/shims:/home/ubuntu/.rbenv/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

#set :rbenv_type, :user
set :rbenv_ruby, '2.1.0'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

#  after :restart, :clear_cache do
#    on roles(:web), in: :groups, limit: 3, wait: 10 do
#      # Here we can do anything such as:
#      within release_path do
#        execute :rake, 'cache:clear'
#      end
#    end
#  end

end

namespace :new_server do
  desc "Create deploy user"
  task :create_deploy_user do
    on roles(:sudo) do
      sudo "adduser --disabled-password --system --group --shell /bin/bash --home /home/deploy deploy"
    end
  end

  desc "Update apt-get sources"
  task :update_apt_get do
    on roles(:sudo) do
      sudo "apt-get update"
    end
  end

  desc "Update locales"
  task :update_locales do
    sudo "export LANGUAGE=en_US.UTF-8;export LANG=en_US.UTF-8;export LC_ALL=en_US.UTF-8;locale-gen en_US.UTF-8;dpkg-reconfigure locales"
  end
   
  desc "Install Needed Tools"
  task :install_needed_tools do
    on roles(:sudo) do
      sudo "apt-get install build-essential dialog libssl-dev curl git-core git-svn -y"
    end
  end
   
  desc "Install SQLite3"
  task :install_sqlite3 do
    on roles(:sudo) do
      sudo "apt-get install sqlite3 libsqlite3-ruby -y"
    end
  end

  desc "Install node"
  task :install_node do
    on roles(:sudo) do
      sudo "apt-get install python-software-properties python g++ make -y"
      sudo "add-apt-repository ppa:chris-lea/node.js -y"
      sudo "apt-get update -y"
      sudo "apt-get install nodejs -y"
    end
  end

  desc "Install rbenv"
  task :install_rbenv do
    on roles(:web) do
      execute "curl https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash > /dev/null"
      rbenv_in_profile = capture("grep 'rbenv init' ~/.bashrc | wc | awk '{print $1}'").to_i > 0
      unless rbenv_in_profile
        execute 'echo \'export PATH="$HOME/.rbenv/bin:$PATH"\' >> ~/.bashrc
                echo \'eval "$(rbenv init -)"\' >> ~/.bashrc'
        execute 'source ~/.bashrc'
      end
    end
  end

  desc "Install ruby"
  task :install_ruby do
    on roles(:web) do
      execute "echo $PATH"
      execute "/home/ubuntu/.rbenv/bin/rbenv install 2.1.0 -v"
      execute "/home/ubuntu/.rbenv/bin/rbenv global 2.1.0"
    end
  end

  desc "Install rails dependencies"
  task :install_rails_dependecies do
    on roles(:web) do
      execute "/home/ubuntu/.rbenv/shims/gem install bundler"
    end
  end

  desc "install nginx"
  task :install_nginx do
    on roles(:sudo) do 
      sudo "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62"
      sudo "echo 'echo \"deb http://nginx.org/packages/ubuntu/ precise nginx\" | sudo tee -a /etc/apt/sources.list' | sh"
      sudo "apt-get update"
      sudo "apt-get install nginx -y"
    end
  end

  desc "Prepare folders"
  task :prepare_folders do
    on roles(:sudo) do 
      sudo "mkdir -p /var/www/"
      sudo "chown ubuntu:ubuntu /var/www/"
    end
  end

  desc "Install requirements for a brand new server"
  task :install_all do
    invoke 'new_server:create_deploy_user'
    invoke 'new_server:update_apt_get'
    invoke 'new_server:install_needed_tools'
    invoke 'new_server:install_sqlite3'
    invoke 'new_server:install_node'
    invoke 'new_server:install_rbenv'
    invoke 'new_server:install_nginx'
    invoke 'new_server:install_ruby'
    invoke 'new_server:install_rails_dependecies'
    invoke 'new_server:prepare_folders'
  end
end

namespace :nginx do

  # after "deploy:install", "nginx:install"
  # desc "Install latest stable release of nginx."
  
  # task :install, roles: :web do
  
  # end

  %w[start stop restart reload].each do |command|
    desc "#{command} Nginx."
    task command do
      on roles(:sudo) do
        sudo "service nginx #{command}"
      end
    end
  end
end



# Number of workers (Rule of thumb is 2 per CPU)
# Just be aware that every worker needs to cache all classes and thus eat some
# of your RAM.
# set :unicorn_workers, 1

# Workers timeout in the amount of seconds below, when the master kills it and
# forks another one.
# set  :unicorn_workers_timeout, 30

# Workers are started with this user
# By default we get the user/group set in capistrano.
# set  :unicorn_user, nil

# The wrapped bin to start unicorn
# set  :unicorn_bin, 'bin/unicorn'
# set  :unicorn_socket, fetch(:app_server_socket)

# Defines where the unicorn pid will live.
# set :unicorn_pid, File.join(current_path, "tmp", "pids", "unicorn.pid")

# Preload app for fast worker spawn
# set :unicorn_preload, true

# set :unicorn_config_path, "#{shared_path}/config" 



# Unicorn
#------------------------------------------------------------------------------
# # Load unicorn tasks

set :linked_dirs, %w{bin log tmp/pids}

require 'capistrano3-unicorn'

#namespace :unicorn do
   #after "deploy:setup", "unicorn:setup"

 #  desc "Setup unicorn configuration for this application."
 #  task :setup do
 #    on roles(:app) do
 #      template "unicorn.erb", "/tmp/unicorn.rb"
 #      run "mv /tmp/unicorn.rb #{shared_path}/config/"
 #    end
 #  end

   
    #after "deploy:cold", "unicorn:start"
   #after 'deploy:restart', 'unicorn:restart'
#end
