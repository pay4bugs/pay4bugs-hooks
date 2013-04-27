class Hook::HipChat < Hook
  string :auth_token, :room
  boolean :notify
  white_list :room

  default_events :bug_submitted, :bug_approved

  def approved_message
    "#{payload["performer"]} approved the following bug report for <a href='#{project_url}'>#{payload["project"]["name"]}</a>:<br>-<a href='#{bug_url}'>#{payload["bug"]["summary"]}</a>"
  end

  def submitted_message
    "#{payload["performer"]} submitted the following bug report for <a href='#{project_url}'>#{payload["project"]["name"]}</a>:<br>-<a href='#{bug_queue_url}'>#{payload["bug"]["summary"]}</a>"
  end


  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

    http.headers['X-Pay4Bugs-Event'] = event.to_s

    rooms = data['room'].to_s.split(",")
    room_ids = if rooms.all? { |room_id| Integer(room_id) rescue false }
      rooms
    else
      [data['room'].to_s]
    end
    
    room_ids.each do |room_id|
      p "payload: #{payload}"
      p "@payload: #{@payload}"
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
  end
end
