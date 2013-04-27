# This is a set of common helpers for Bug events.
module Hook::BugHelpers

  def approved?
    payload["action"] == "approved"
  end
  
  def submitted?
    payload["action"] == "submitted"
  end
  
  def bug_queue_url
    "https://www.pay4bugs.com/c/bugs/queue"
  end
 
  def project_url
    "https://www.pay4bugs.com/c/projects/show/#{payload["data"]["object"]["project"]["id"]}"
  end
  
  def bug_url
    "https://www.pay4bugs.com/c/bugs/view/#{payload["data"]["object"]["id"]}"
  end
  
  
  def self.sample_payload
    {
      "type="=>"bug", 
      "action"=>"approved",
      "performer"=>"larrysalibra",
      "created_at"=>"2013-04-27T09:26:52Z", 
      "data"=>
      {
        "object"=>
        {
            "id"=>888, 
            "summary"=>"Bizy Bee Not Buzzing",
            "submitter"=>
            {
              "name"=>"Precise", 
              "ip_address"=>"88.88.88.88", 
              "user_agent"=>"Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.100 Safari/534.30"
            },
            "action_performed"=>"Bought a Bizy Bee",
            "expected_result"=>"Expected Bizy Bee to Buzz", 
            "actual_result"=>"Bizy Bee is dead", 
            "assignment"=>"Find Bizy Bee Bugs", 
            "project"=>
            {
              "id"=>888, 
              "name"=>"Bizy Bee"
            }, 
            "body"=>"hi"
        }
      }
    } 
  end
end

