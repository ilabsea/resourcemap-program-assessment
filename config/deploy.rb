require 'rvm/capistrano'
require 'bundler/capistrano'

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

set :rvm_ruby_string, '1.9.3-p545'
set :rvm_type, :system
set :application, "resourcemap_wfp"
set :repository,  "https://github.com/ilabsea/resourcemap-program-assessment"
set :scm, :git
set :user, 'ilab'
set :use_sudo, false
set :group, 'ilab'
set :deploy_via, :remote_cache
set :branch, 'wfp_staging'

server '192.168.1.220', :app, :web, :db, primary: true

default_run_options[:pty] = true
default_environment['TERM'] = ENV['TERM']

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :whenever do
    run "cd #{release_path} && RAILS_ENV=production bundle exec whenever --update-crontab resource_map "
  end

  task :symlink_configs, :roles => :app do
    %W(settings.yml google_maps.key nuntium.yml aws.yml recaptcha.yml database.yml).each do |file|
      run "ln -nfs #{shared_path}/#{file} #{release_path}/config/"
    end
  end

  task :symlink_photo_field, :roles => :app do
    run "ln -nfs #{shared_path}/photo_field #{release_path}/public/photo_field"
  end

  task :symlink_print_pdf, :roles => :app do
    run "ln -nfs #{shared_path}/print #{release_path}/public/print"
  end

  task :symlink_tinymce_photo, :roles => :app do
    run "ln -nfs #{shared_path}/tinymce_photo #{release_path}/public/tinymce_photo"
  end

  task :symlink_production_env, :roles => :app do
    run "ln -nfs #{shared_path}/environments/production.rb #{release_path}/config/environments/production.rb"
  end

  task :generate_revision_and_version do
    run "cd #{current_path} && rake deploy:generate_revision_and_version RAILS_ENV=production"
  end
end

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export, :roles => :app do
    sudo "whoami"
    run "echo -e \"PATH=$PATH\\nGEM_HOME=$GEM_HOME\\nGEM_PATH=$GEM_PATH\\nRAILS_ENV=production\" >  #{current_path}/.env"
    run "cd #{current_path} && rvmsudo bundle exec foreman export upstart /etc/init -f #{current_path}/Procfile -a #{application} -u #{user} --concurrency=\"resque=1,resque_scheduler=1\""
  end

  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end
end

before "deploy:start", "deploy:migrate"
before "deploy:restart", "deploy:migrate"

after "deploy:update_code", "deploy:symlink_configs"

after "deploy:update_code", "deploy:symlink_photo_field"

after "deploy:update_code", "deploy:symlink_print_pdf"

after "deploy:update_code", "deploy:symlink_tinymce_photo"

after "deploy:update_code", "deploy:symlink_production_env"

after "deploy:update", "foreman:export"    # Export foreman scripts

after "deploy:update", "deploy:generate_revision_and_version"
after 'deploy:update_code', 'deploy:whenever'

after "deploy:restart", "foreman:restart"   # Restart application scripts
