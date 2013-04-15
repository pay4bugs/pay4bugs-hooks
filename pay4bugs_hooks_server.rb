require File.expand_path('../config/load', __FILE__)

Hook::App.set :run => true,
  :environment => :production,
  :port        => ARGV.first || 8080,
  :logging     => true

begin
  require 'mongrel'
  Hook::App.set :server, 'mongrel'
rescue LoadError
  begin
    require 'thin'
    Hook::App.set :server, 'thin'
  rescue LoadError
    Hook::App.set :server, 'webrick'
  end
end

Hook::App.run!
