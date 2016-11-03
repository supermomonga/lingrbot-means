require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :spec_check do |t|
  envs = ['TWITTER_BEARER_TOKEN', 'DEVIANTART_ID', 'DEVIANTART_SECRET']
  if envs.reject(&ENV.method(:include?)).size == 0
    invoke :spec
  else
    puts "Read README.mkd for setting env bot needs: #{envs.join(', ')}"
  end
end

task :default => :spec_check
