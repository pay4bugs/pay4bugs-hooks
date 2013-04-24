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
    "https://www.pay4bugs.com/c/projects/show/#{payload["project"]["id"]}"
  end
  
  def bug_url
    "https://www.pay4bugs.com/c/bugs/view/#{payload["bug"]["id"]}"
  end
  
  
  def self.sample_payload
    {
      "type" => "bug",
      "action" => "submitted",
      "project" => {
        "name" => "Bizy",
        "id" => "123"
      },
      "performer" => "buggy",
      "bug" => 
      {"id" => "999",
      "summary" => "The Bizy Bee Doesn't Buzz",
      "action_performed" => "Some clicking",
      "expected_result" => "A Buzzing Bee",
      "actual_result" => "A Barking Bee"},
      "assignment" => {
        "name" => "Function Issues",
        "id" => "888"
      }
      
    }
  end
end

