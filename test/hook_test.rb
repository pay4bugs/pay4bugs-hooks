require File.expand_path('../helper', __FILE__)

class HookTest < Hook::TestCase
  class TestHook < Hook
    def receive_bug
    end
  end

  class TestCatchAllHook < Hook
    def receive_event
    end
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @hook = hook(:bug, 'data', 'payload')
  end

  def test_receive_valid_event
    assert TestHook.receive :bug, {}, {}
  end

  def test_specific_event_method
    assert_equal 'receive_bug', TestHook.new(:bug, {}, {}).event_method
  end

  def test_catch_all_event_method
    assert_equal 'receive_event', TestCatchAllHook.new(:push, {}, {}).event_method
  end


  def test_http_callback
    @stubs.post '/' do |env|
      [200, {'x-test' => 'booya'}, 'ok']
    end

    @hook.http.post '/'

    @hook.http_calls.each do |env|
      assert_equal '/', env[:request][:url]
      assert_equal '0', env[:request][:headers]['Content-Length']
      assert_equal 200, env[:response][:status]
      assert_equal 'booya', env[:response][:headers]['x-test']
      assert_equal 'ok', env[:response][:body]
    end

    assert_equal 1, @service.http_calls.size
  end

  def test_ssl_check
    http = @hook.http
    def http.post
      raise OpenSSL::SSL::SSLError
    end

    @stubs.post "/" do |env|
      raise "This stub should not be called"
    end

    assert_raises Hook::ConfigurationError do
      @hook.http_post 'http://abc'
    end
  end

  def service(*args)
    super TestService, *args
  end
end
