require 'test/unit'
require 'pp'
require File.expand_path('../../config/load', __FILE__)
Hook.load_hooks

class Hook::TestCase < Test::Unit::TestCase
  ALL_HOOKS = Hook.hooks.dup

  def test_default
  end

  def hook(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :bug_approved
    end

    hook = klass.new(event, data, payload)
    hook.http :adapter => [:test, @stubs]
    hook
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end
  
  def bug_approved_payload
    Hook::BugHelpers.sample_payload
  end
  
end

