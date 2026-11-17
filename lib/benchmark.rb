require "bundler/setup"
require "benchmark/ips"
# require "some_gem"

# puts "Ruby #{RUBY_VERSION} | Gemfile: #{ENV['BUNDLE_GEMFILE']}"

require_relative "sample_operation"

def invoke_operation
  admin = User.new("alice", true)
  # guest = User.new("bob", false)
  valid = { song: { title: "Roxanne", length: 190 } }

  result      = Song::Create.(params: valid, current_user: admin)
end

raise unless invoke_operation.success? # smoke test

Benchmark.ips do |x|
  x.config(time: 2, warmup: 2)

  x.report(ENV.fetch("BUNDLE_GEMFILE")) do
    invoke_operation
  end

  x.save!("results.json")  # each process adds its result to this file
  x.compare!
end
