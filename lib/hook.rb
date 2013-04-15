# Represents a single triggered Hook call.  Each Hook tracks the event
# type, the configuration data, and the payload for the current call.
class Hook
  class Contributor < Struct.new(:value)
    def self.contributor_types
      @contributor_types ||= []
    end

    def self.inherited(contributor_type)
      contributor_types << contributor_type
      super
    end

    def self.create(type, keys)
      klass = contributor_types.detect { |struct| struct.contributor_type == type }
      if klass
        Array(keys).map do |key|
          klass.new(key)
        end
      else
        raise ArgumentError, "Invalid Contributor type #{type.inspect}"
      end
    end

    def to_contributor_hash(key)
      {:type => self.class.contributor_type, key => value}
    end
  end

  class EmailContributor < Contributor
    def self.contributor_type
      :email
    end

    def to_hash
      to_contributor_hash(:address)
    end
  end

  class GitHubContributor < Contributor
    def self.contributor_type
      :github
    end

    def to_hash
      to_contributor_hash(:login)
    end
  end

  class TwitterContributor < Contributor
    def self.contributor_type
      :twitter
    end

    def to_hash
      to_contributor_hash(:login)
    end
  end

  class WebContributor < Contributor
    def self.contributor_type
      :web
    end

    def to_hash
      to_contributor_hash(:url)
    end
  end

  dir = File.expand_path '../hook', __FILE__
  Dir["#{dir}/events/helpers/*.rb"].each do |helper|
    require helper
  end
  Dir["#{dir}/events/*.rb"].each do |helper|
    require helper
  end

  ALL_EVENTS = %w[
    bug 
  ].sort

  class << self
    attr_accessor :root, :env, :host

    %w(development test production staging fi).each do |m|
      define_method "#{m}?" do
        env == m
      end
    end

    # The SHA1 of the commit that was HEAD when the process started. This is
    # used in production to determine which version of the app is deployed.
    #
    # Returns the 40 char commit SHA1 string.
    def current_sha
      @current_sha ||=
        `cd #{root}; git rev-parse HEAD 2>/dev/null || echo unknown`.
        chomp.freeze
    end

    attr_writer :current_sha

    # Returns the Hook instance if it responds to this event, or nil.
    def receive(event, data, payload = nil)
      new(event, data, payload).receive
    end

    def load_hooks
      path = File.expand_path("../hooks/**/*.rb", __FILE__)
      Dir[path].each { |lib| require(lib) }
    end

    # Tracks the defined services.
    #
    # Returns an Array of Hook Classes.
    def hooks
      @hooks ||= []
    end

    # Gets the default events that this Hook will listen for.  This defines
    # the default event configuration when Hooks are created on Pay4Bugs.  By
    # default, Pay4Bugs Hooks will only send `bug` events.
    #
    # Returns an Array of Strings (or Symbols).
    def default_events(*events)
      if events.empty?
        @default_events ||= [:bug]
      else
        @default_events = events
      end
    end

    # Gets a list of events support by the service. Should be a superset of
    # default_events.
    def supported_events
      return ALL_EVENTS.dup if method_defined? :receive_event
      ALL_EVENTS.select { |event| method_defined? "receive_#{event}" }
    end

    # Gets the current schema for the data attributes that this Hook
    # expects.  This schema is used to generate the Pay4Bugs project hooks admin
    # interface.  The attribute types loosely to HTML input elements.
    #
    # Example:
    #
    #   class FooHook < Hook
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # Returns an Array of [Symbol attribute type, Symbol attribute name] tuples.
    def schema
      @schema ||= []
    end

    # Public: Adds the given attributes as String attributes in the Hook's
    # schema.
    #
    # Example:
    #
    #   class FooHook < Hook
    #     string :token
    #   end
    #
    #   FooHook.schema
    #   # => [[:string, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def string(*attrs)
      add_to_schema :string, attrs
    end

    # Public: Adds the given attributes as Password attributes in the Hook's
    # schema.
    #
    # Example:
    #
    #   class FooHook < Hook
    #     password :token
    #   end
    #
    #   FooHook.schema
    #   # => [[:password, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def password(*attrs)
      add_to_schema :password, attrs
    end

    # Public: Adds the given attributes as Boolean attributes in the Hook's
    # schema.
    #
    # Example:
    #
    #   class FooHook < Hook
    #     boolean :digest
    #   end
    #
    #   FooHook.schema
    #   # => [[:boolean, :digest]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def boolean(*attrs)
      add_to_schema :boolean, attrs
    end

    # Public: get a list of attributes that are approved for logging.  Don't
    # add things like tokens or passwords here.
    #
    # Returns an Array of String attribute names.
    def white_listed
      @white_listed ||= []
    end

    def white_list(*attrs)
      attrs.each do |attr|
        white_listed << attr.to_s
      end
    end


    # Adds the given attributes to the Hook's data schema.
    #
    # type  - A Symbol specifying the type: :string, :password, :boolean.
    # attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def add_to_schema(type, attrs)
      attrs.each do |attr|
        schema << [type, attr.to_sym]
      end
    end

    # Gets the official title of this Hook.  This is used in any
    # user-facing documentation regarding the Hook.
    #
    # Returns a String.
    def title(value = nil)
      if value
        @title = value
      else
        @title ||= begin
          hook = name.dup
          hook.sub! /.*:/, ''
          hook
        end
      end
    end

    # Sets the official title of this Hook.
    #
    # title - The String title.
    #
    # Returns nothing.
    attr_writer :title

    # Gets the name that identifies this Hook type.  This is a
    # short string that is used to uniquely identify the service internally.
    #
    # Returns a String.
    def hook_name(value = nil)
      if value
        @hook_name = value
      else
        @hook_name ||= begin
          hook = name.dup
          hook.downcase!
          hook.sub! /.*:/, ''
          hook
        end
      end
    end

    # Sets the uniquely identifying name for this Hook type.
    #
    # hook_name - The String name.
    #
    # Returns a String.
    attr_writer :hook_name

    attr_reader :url, :logo_url

    def url(value = nil)
      if value
        @url = value
      else
        @url
      end
    end

    def logo_url(value = nil)
      if value
        @logo_url = value
      else
        @logo_url
      end
    end

    def supporters
      @supporters ||= []
    end

    def maintainers
      @maintainers ||= []
    end

    def supported_by(values)
      values.each do |contributor_type, value|
        supporters.push(*Contributor.create(contributor_type, value))
      end
    end

    def maintained_by(values)
      values.each do |contributor_type, value|
        maintainers.push(*Contributor.create(contributor_type, value))
      end
    end

    # Public: Gets the Hash of secret configuration options.  These are set on
    # the Pay4Bugs servers and never committed to git.
    #
    # Returns a Hash.
    def secrets
      @secrets ||= begin
        jabber = ENV['SERVICES_JABBER'].to_s.split("::")
        twitter = ENV['SERVICES_TWITTER'].to_s.split("::")

        { 'jabber' => {'user' => jabber[0], 'password' => jabber[1] },
          'boxcar' => {'apikey' => ENV['SERVICES_BOXCAR'].to_s},
          'twitter' => {'key' => twitter[0], 'secret' => twitter[1]},
          'bitly' => {'key' => ENV['SERVICES_BITLY'].to_s}
        }
      end
    end

    # Public: Gets the Hash of email configuration options.  These are set on
    # the Pay4Bugs servers and never committed to git.
    #
    # Returns a Hash.
    def email_config
      @email_config ||= begin
        hash = (File.exist?(email_config_file) && YAML.load_file(email_config_file)) || {}
        EMAIL_KEYS.each do |key|
          env_key = "EMAIL_SMTP_#{key.upcase}"
          if value = ENV[env_key]
            hash[key] = value
          end
        end
        hash
      end
    end
    EMAIL_KEYS = %w(address port domain authentication user_name password
                    enable_starttls_auto openssl_verify_mode enable_logging
                    noreply_address)

    # Gets the path to the secret configuration file.
    #
    # Returns a String path.
    def secret_file
      @secret_file ||= File.expand_path("../../config/secrets.yml", __FILE__)
    end

    # Gets the path to the email configuration file.
    #
    # Returns a String path.
    def email_config_file
      @email_config_file ||= File.expand_path('../../config/email.yml', __FILE__)
    end

    def objectify(hash)
      struct = OpenStruct.new
      hash.each do |key, value|
        struct.send("#{key}=", value.is_a?(Hash) ? objectify(value) : value)
      end
      struct
    end

    # Sets the path to the secrets configuration file.
    #
    # secret_file - String path.
    #
    # Returns nothing.
    attr_writer :secret_file

    # Sets the default private configuration data for all Hooks.
    #
    # secrets - Configuration Hash.
    #
    # Returns nothing.
    attr_writer :secrets

    # Sets the path to the email configuration file.
    #
    # email_config_file - The String path.
    #
    # Returns nothing.
    attr_writer :email_config_file

    # Sets the default email configuration data for all Hooks.
    #
    # email_config - Email configuration Hash.
    #
    # Returns nothing.
    attr_writer :email_config

    # Binds the current Hook to the Sinatra App.
    #
    # Returns nothing.
    def inherited(svc)
      Hook.hooks << svc
      super
    end
    
    def setup_for(app)
      app.hook(self)
    end
  end

  # Determine #root from this file's location
  self.root ||= File.expand_path('../..', __FILE__)
  self.host ||= `hostname -s`.chomp

  # Determine #env from the environment
  self.env ||= ENV['RACK_ENV'] || ENV['GEM_STRICT'] ? 'production' : 'development'

  # Public: Gets the configuration data for this Hook instance.
  #
  # Returns a Hash.
  attr_reader :data

  # Public: Gets the unique payload data for this Hook instance.
  #
  # Returns a Hash.
  attr_reader :payload

  # Public: Gets the identifier for the Hook's event.
  #
  # Returns a Symbol.
  attr_reader :event

  # Sets the Faraday::Connection for this Hook instance.
  #
  # http - New Faraday::Connection instance.
  #
  # Returns a Faraday::Connection.
  attr_writer :http

  # Sets the private configuration data.
  #
  # secrets - Configuration Hash.
  #
  # Returns nothing.
  attr_writer :secrets

  # Sets the email configuration data.
  #
  # email_config - Email configuration Hash.
  #
  # Returns nothing.
  attr_writer :email_config

  # Sets the path to the SSL Certificate Authority file.
  #
  # ca_file - String path.
  #
  # Returns nothing.
  attr_writer :ca_file

  attr_reader :event_method

  attr_reader :http_calls

  attr_reader :remote_calls

  def initialize(event = :bug, data = {}, payload = nil)
    helper_name = "#{event.to_s.classify}Helpers"
    if Hook.const_defined?(helper_name)
      @helper = Hook.const_get(helper_name)
      extend @helper
    end

    @event = event.to_sym
    @data = data || {}
    @payload = payload || sample_payload
    @event_method = ["receive_#{event}", "receive_event"].detect do |method|
      respond_to?(method)
    end
    @http = @secrets = @email_config = nil
    @http_calls = []
    @remote_calls = []
  end

  def respond_to_event?
    !@event_method.nil?
  end

  # Public: Shortens the given URL with git.io.
  #
  # url - String URL to be shortened.
  #
  # Returns the String URL response from git.io.
  def shorten_url(url)
    raise Exception.new("Pay4Bugs doesn't have url shortening yet")
    res = http_post("http://git.io", :url => url)
    if res.status == 201
      res.headers['location']
    else
      url
    end
  rescue TimeoutError
    url
  end

  # Public: Makes an HTTP GET call.
  #
  # url     - Optional String URL to request.
  # params  - Optional Hash of GET parameters to set.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_get("http://pay4bugs.com")
  #   # => <Faraday::Response>
  #
  #   # GET http://pay4bugs.com?page=1
  #   http_get("http://pay4bugs.com", :page => 1)
  #   # => <Faraday::Response>
  #
  #   http_get("http://pay4bugs.com", {:page => 1},
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_get "http://pay4bugs.com" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1
  #     req.headers['Accept'] = 'application/json'
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
    end
  end

  # Public: Makes an HTTP POST call.
  #
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_post("http://pay4bugs.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_post("http://pay4bugs.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_post "http://pay4bugs.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://pay4bugs.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_post(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :post, url, body, headers, &block
  end

  # Public: Makes an HTTP call.
  #
  # method  - Symbol of the HTTP method.  Example: :put
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_method(:put, "http://pay4bugs.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_method(:put, "http://pay4bugs.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_method :put, "http://pay4bugs.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://pay4bugs.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_method(method, url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?

    check_ssl do
      http.send(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        block.call req if block
      end
    end
  end

  # Public: Lazily loads the Faraday::Connection for the current Hook
  # instance.
  #
  # options - Optional Hash of Faraday::Connection options.
  #
  # Returns a Faraday::Connection instance.
  def http(options = {})
    @http ||= begin
      self.class.default_http_options.each do |key, sub_options|
        sub_hash = options[key] ||= {}
        sub_options.each do |sub_key, sub_value|
          sub_hash[sub_key] ||= sub_value
        end
      end
      options[:ssl][:ca_file] ||= ca_file

      Faraday.new(options) do |b|
        b.use HttpReporter, self
        b.request :url_encoded
        b.adapter *(options[:adapter] || :net_http)
      end
    end
  end

  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 10, :open_timeout => 5},
      :ssl => {:verify_depth => 5},
      :headers => {}
    }
  end

  # Passes HTTP response debug data to the HTTP callbacks.
  def receive_http(env)
    @http_calls << env
  end

  # Passes raw debug data to remote call callbacks.
  def receive_remote_call(text)
    @remote_calls << text
  end

  def receive(timeout = nil)
    return unless respond_to_event?
    timeout_sec = (timeout || 20).to_i
    Hook::Timeout.timeout(timeout_sec, TimeoutError) do
      send(event_method)
    end

    self
  rescue Hook::ConfigurationError, Errno::EHOSTUNREACH, Errno::ECONNRESET, SocketError, Net::ProtocolError => err
    if !err.is_a?(Hook::Error)
      err = ConfigurationError.new(err)
    end
    raise err
  end

  # Public: Checks for an SSL error, and re-raises a Hooks configuration error.
  #
  # Returns nothing.
  def check_ssl
    yield
  rescue OpenSSL::SSL::SSLError => e
    raise_config_error "Invalid SSL cert"
  end

  # Public: Builds a log message for this Hook request.  Respects the white
  # listed attributes in the Hook schema.
  #
  # Returns a String.
  def log_message(status = 0)
    "[%s] %03d %s/%s %s" % [Time.now.utc.to_s(:db), status,
      self.class.hook_name, @event, JSON.generate(log_data)]
  end

  # Public: Builds a sanitized Hash of the Data hash without passwords.
  #
  # Returns a Hash.
  def log_data
    @log_data ||= self.class.white_listed.inject({}) do |hash, key|
      if value = data[key]
        hash.update key => sanitize_log_value(value)
      else
        hash
      end
    end
  end

  # Attempts to sanitize passwords out of URI strings.
  #
  # value - The String attribute value.
  #
  # Returns a sanitized String.
  def sanitize_log_value(value)
    string = value.to_s
    string.strip!
    if string =~ /^[a-z]+\:\/\//
      uri = Addressable::URI.parse(string)
      uri.password = "*" * uri.password.size if uri.password
      uri.to_s
    else
      string
    end
  rescue Addressable::URI::InvalidURIError
    string
  end

  # Public: Gets the Hash of secret configuration options.  These are set on
  # the GitHub servers and never committed to git.
  #
  # Returns a Hash.
  def secrets
    @secrets || Hook.secrets
  end

  # Public: Gets the Hash of email configuration options.  These are set on
  # the GitHub servers and never committed to git.
  #
  # Returns a Hash.
  def email_config
    @email_config || Hook.email_config
  end

  # Public: Raises a configuration error inside a service, and halts further
  # processing.
  #
  # Raises a Hook;:ConfigurationError.
  def raise_config_error(msg = "Invalid configuration")
    raise ConfigurationError, msg
  end

  def raise_missing_error(msg = "Remote endpoint not found")
    raise MissingError, msg
  end

  # Gets the path to the SSL Certificate Authority certs.  These were taken
  # from: http://curl.haxx.se/ca/cacert.pem
  #
  # Returns a String path.
  def ca_file
    @ca_file ||= File.expand_path('../../config/cacert.pem', __FILE__)
  end

  # Generates a sample payload for the current Hook instance.
  #
  # Returns a Hash payload.
  def sample_payload
    @helper ? @helper.sample_payload : {}
  end

  # Raised when an unexpected error occurs during service hook execution.
  class Error < StandardError
    attr_reader :original_exception
    def initialize(message, original_exception=nil)
      original_exception = message if message.kind_of?(Exception)
      @original_exception = original_exception
      super(message)
    end
  end

  class TimeoutError < Timeout::Error
  end

  # Raised when a service hook fails due to bad configuration. Hooks that
  # fail with this exception may be automatically disabled.
  class ConfigurationError < Error
  end

  class MissingError < Error
  end

  class HttpReporter < Faraday::Response::Middleware
    def initialize(app, service = nil)
      super(app)
      @service = service
      @time = Time.now
    end

    def on_complete(env)
      ms = ((Time.now - @time) * 1000).round
      @service.receive_http(
        :request => {
          :url => env[:url].to_s,
          :headers => env[:request_headers]
        }, :response => {
          :status => env[:status],
          :headers => env[:response_headers],
          :body => env[:body].to_s,
          :duration => "%.02fs" % [Time.now - @time]
        }
      )
    end
  end
end

require 'timeout'
Hook::Timeout = Timeout
