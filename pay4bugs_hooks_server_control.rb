require 'daemons'
options = {}
if ARGV[1] && File.directory?(ARGV[1])
  options = {dir_mode: :normal, dir: ARGV[1]}
else
  p "No valid PID directory given"
end
Daemons.run('pay4bugs_hooks_server.rb', options)