module Hook::HelpersWithActions
  def action
    payload['action'].to_s
  end

  def submitted?
    action == 'submitted'
  end
  
  def approved?
    action == 'approved'
  end
end
