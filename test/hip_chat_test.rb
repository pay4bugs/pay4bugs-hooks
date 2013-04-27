require File.expand_path('../helper', __FILE__)

class HipChatTest < Hook::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_bug_approved
    payload = {'a' => 1, 'ref' => 'refs/heads/master'}
    @stubs.post "/v1/webhooks/" do |env|
      form = Rack::Utils.parse_query(env[:body])
      assert_equal payload, JSON.parse(form['payload'])
      assert_equal 'a', form['auth_token']
      assert_equal 'r', form['room_id']
      [200, {}, '']
    end

    svc = hook(
      {'auth_token' => 'a', 'room' => 'r'}, payload)
    svc.receive_event
  end

  def hook(*args)
    super Hook::HipChat, *args
  end
end

