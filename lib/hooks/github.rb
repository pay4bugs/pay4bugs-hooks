class Hook::Github < Hook
  string :owner, :repository
  password :token
  white_list :owner, :repository

  default_events :bug_approved


  def receive_bug_approved
    # make sure we have what we need
    raise_config_error "Missing 'token'" if data['token'].to_s == ''
    raise_config_error "Missing 'owner'" if data['owner'].to_s == ''
    raise_config_error "Missing 'repository'" if data['repository'].to_s == ''

    http.headers['X-Pay4Bugs-Event'] = event.to_s

  
    
      res = http_post "https://api.github.com/repos/#{data['owner']}/#{data['repository']}/issues" do |req|
        req.body = {'title' => payload["data"]["object"]["summary"], 'body' => payload["data"]["object"]["body"] }.to_json 
        req.headers["Authorization"] = "token #{data['token']}"
       
      end
      if res.status < 200 || res.status > 299
        raise_config_error
      end
  end
  
end
