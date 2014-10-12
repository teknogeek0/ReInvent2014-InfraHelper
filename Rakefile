#!/usr/bin/env rake

desc "run rubocop linter on code"
task :lintme do

 sh "rubocop -l *.rb ./lib/*.rb ./flow/*.rb"

end

task :default => :lintme
