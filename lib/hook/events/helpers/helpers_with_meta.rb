module Hook::HelpersWithMeta
  def project
    @repo ||= self.class.objectify(payload['project'])
  end

  def tester
    @sender ||= self.class.objectify(payload['tester'])
  end

  
  def self.sample_payload
    {
      "project" => {
        "name"  => "bizy",
        "id"   => "12",
        "client" => { "name" => "Appartisan Limited" }
      },
      "tester" => { "username" => 'buggy' }
    }
  end
end
