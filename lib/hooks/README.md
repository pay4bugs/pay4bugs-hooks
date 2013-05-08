# Hooks

This is the directory that all Hooks go.  Creating a Hook is
simple:

```ruby
class Hook::MyService < Hook
  def receive_bug_approved
  end
end
```

Inside the method, you can access the configuration data in a hash named
`data`, and the payload data in a Hash named `payload`.

Note: A hook can respond to more than one event.

The payload has information about the event and it's type and an object or objects associated with the event.

For example, a bug event, will have an object representing the bug.

```ruby
#get the bug object
  @bug = payload["data"]["object"] if payload["type"] ==  "bug"

```

## Tip: Check configuration data early.

```ruby
class Hook::MyService < Hook
  def receive_bug_approved
    if data['username'].to_s.empty?
      raise_config_error "Needs a username"
    end
  end
end
```

## Tip: Use `http` helpers to make HTTP calls easily.

```ruby
class Hook::MyService < Hook
  def receive_bug_approved
    # Sets this basic auth info for every request.
    http.basic_auth(data['username'], data['password'])

    # Every request sends JSON.
    http.headers['Content-Type'] = 'application/json'

    # Uses this URL as a prefix for every request.
    http.url_prefix = "https://my-service.com/api"

    payload['commits'].each do |commit|

      # POST https://my-service.com/api/create_new_issues.json
      http_post "commits.json", bug.to_json

    end
  end
end
```

## Tip: Test your service like a bossk.

```ruby
class MyServiceTest < Hook::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/create.json" do |env|
      assert_equal 'my-service.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      assert_equal basic_auth("user", "pass"),
        env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service :push,
      {'username' => 'user', 'password' => 'pass'}, payload
    svc.receive_push
  end

  def service(*args)
    super Hook::MyService, *args
  end
end
```

## Documentation

Each Hook needs to have documentation aimed at end users in /docs.
See existing Hooks for the format.  This documentation will be parsed with markdown and displayed to users on the site. It should explain to the users what the configuration options for your hook mean.
