class Hook::Github < Hook
  string :owner, :repository
  password :token
  white_list :owner, :repository

  default_events :bug


  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'token'" if data['token'].to_s == ''
    raise_config_error "Missing 'owner'" if data['owner'].to_s == ''
    raise_config_error "Missing 'repository'" if data['repository'].to_s == ''

    http.headers['X-Pay4Bugs-Event'] = event.to_s

  
    
      res = http_post "https://api.github.com/repos/#{data['owner']}/#{data['repository']}/issues",
        title: payload["bug"]["summary"],
        body: body
      if res.status < 200 || res.status > 299
        raise_config_error
      end
  end
  
   


  private

  def body 
    payload["bug"]["action_performed"] + payload["bug"]["expected_result"] + payload["bug"]["actual_result"] + payload["bug"]["user_agent"] + payload["bug"]["ip_address"]
  end

  
end
