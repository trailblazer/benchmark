
puts `BUNDLE_GEMFILE=gemfiles/Gemfile.2.1 bundle install`
puts `BUNDLE_GEMFILE=gemfiles/Gemfile.3.0-master bundle install`

`rm results.json`
puts `BUNDLE_GEMFILE=gemfiles/Gemfile.2.1 bundle exec ruby lib/benchmark.rb`
puts `BUNDLE_GEMFILE=gemfiles/Gemfile.3.0-master VERSION=3 bundle exec ruby lib/benchmark.rb`
