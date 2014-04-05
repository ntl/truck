require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs << 'test'
end

desc "Update ctags"
task :ctags do
  `ctags -R --languages=Ruby --totals -f tags`
end

task default: 'test'
