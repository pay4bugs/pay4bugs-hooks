class Hook::Trello < Hook
  string :list_id
  password :consumer_token
  white_list :list_id

  default_events :bug


  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'consumer_token'" if data['consumer_token'].to_s == ''
    raise_config_error "Missing 'list_id'" if data['list_id'].to_s == ''

    http.headers['X-Pay4Bugs-Event'] = event.to_s

  
    
      res = http_post "https://api.hipchat.com/v1/rooms/message",
        auth_token: data['auth_token'],
        room_id: room_id,
        from: "Pay4Bugs",
        notify: data['notify'] ? 1 : 0,
        message: approved? ? approved_message() : submitted_message()
      if res.status < 200 || res.status > 299
        raise_config_error
      end
  end
  
    def receive_pull_request
    return unless opened?

    assert_required_credentials :pull_request
    
    create_card :pull_request, name_for_pull(pull), desc_for_pull(pull)
  end

  def name_for_pull(pull)
    pull.title
  end

  def desc_for_pull(pull)
    "Author: %s\n\n%s\n\nDescription: %s" % [
      pull.user.login,
      pull.html_url,
      pull.body || '[no description]'
    ]
  end


  private

  def create_card(event, name, description)
    http.url_prefix = "https://api.trello.com/1"
    http_post "cards",
      :name => name,
      :desc => description,
      :idList => list_id(event),
      :key => application_key,
      :token => consumer_token
  end
    

  def create_cards(event)
    payload['commits'].each do |commit|
      next if ignore_commit? commit
      create_card event, name_for_commit(commit), desc_for_commit(commit)
    end
  end

  def ignore_commit? commit
    ignore_regex && ignore_regex.match(commit['message'])
  end

  def truncate_message(message)
    message.length > message_max_length ? message[0...message_max_length] + "..." : message
  end

  def name_for_commit commit
    truncate_message commit['message']
  end

  def desc_for_commit commit
    author = commit['author'] || {}

    "Author: %s\n\n%s\n\nRepo: %s\n\nBranch: %s\n\nCommit Message: %s" % [
      author['name'] || '[unknown]',
      commit['url'],
      repository,
      branch_name,
      commit['message'] || '[no description]'
    ]
  end

  def consumer_token
    data['consumer_token'].to_s
  end



  def application_key
    "8ba5b2a1da13cdc8080d437494366224"
  end

  def message_max_length
    80
  end
  
end
