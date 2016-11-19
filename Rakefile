require 'rspec/core/rake_task'
require 'yaml'

desc 'The reality of RSpec'
RSpec::Core::RakeTask.new(:spec_run)

desc 'Run RSpec test with checking env bot needs'
task :spec do |t|
  envs = ['TWITTER_BEARER_TOKEN', 'DEVIANTART_ID', 'DEVIANTART_SECRET']
  if envs.reject(&ENV.method(:include?)).size == 0
    Rake::Task[:spec_run].invoke
  else
    puts "Read README.mkd for setting env bot needs: #{envs.join(', ')}"
    puts "You can use default setting; bundle exec rake spec_with_env"
  end
end

desc 'Run RSpec test with using env what is in .travis.yml'
task :spec_with_env do |t|
  yaml = YAML.load_file('.travis.yml')
  yaml['env']['global'].each do |e|
    key, value = e.split(?=)
    ENV[key] = value.gsub(/^'(.+)'$/, '\1')
  end
  Rake::Task[:spec_run].invoke
end

task :default => :spec
