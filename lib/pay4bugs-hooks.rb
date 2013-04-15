# stdlib
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'socket'
require 'xmlrpc/client'
require 'openssl'
require 'cgi'
require 'sinatra'
#~ require 'date' # This is needed by the CIA service in ruby 1.8.7 or later

# bundled
require 'addressable/uri'
require 'mime/types'
require 'active_resource'

# for classifying Strings
require 'active_support/core_ext/string'
require 'yajl/json_gem'
require 'rubyforge'
require 'oauth'

require 'addressable/uri'
require 'faraday'
require 'ostruct'
require File.expand_path("../hook/structs", __FILE__)

class Addressable::URI
  attr_accessor :validation_deferred
end

module Faraday
  def Connection.URI(url)
    uri = if url.respond_to?(:host)
      url
    elsif url =~ /^https?\:\/\/?$/
      ::Addressable::URI.new
    elsif url.respond_to?(:to_str)
      ::Addressable::URI.parse(url)
    else
      raise ArgumentError, "bad argument (expected URI object or URI string)"
    end
  ensure
    if uri.respond_to?(:validation_deferred)
      uri.validation_deferred = true
      uri.port ||= uri.inferred_port
    end
  end
end

module Pay4bugsHooks
  VERSION = '1.0.0'

  # The SHA1 of the commit that was HEAD when the process started. This is
  # used in production to determine which version of the app is deployed.
  #
  # Returns the 40 char commit SHA1 string.
  def self.current_sha
    @current_sha ||=
      `cd #{root}; git rev-parse HEAD 2>/dev/null || echo unknown`.
      chomp.freeze
  end
end

require File.expand_path('../hook', __FILE__)
Hook.load_hooks
require File.expand_path('../app', __FILE__)
