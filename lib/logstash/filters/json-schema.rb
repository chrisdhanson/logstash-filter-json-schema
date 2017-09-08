# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "json-schema"





# This  filter will replace the contents of the default 
# message field with whatever you specify in the configuration.
#
# It is only intended to be used as an .
class LogStash::Filters::JsonSchema < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #    {
  #     message => "My message..."
  #   }
  # }
  #
  config_name "json_schema"
  
  # Replace the message with this value.
  #config :message, :validate => :string, :default => "Hello World!"
  config :preload_schema_uris,
         :validate => :uri,
         :list => true,
         :required => false
  config :preload_schema_paths,
         :validate => :path,
         :list => true,
         :required => false
  #config :schema_uri,
         #:validate => :uri,
         #:required => true,
         ##:default => "https://gist.githubusercontent.com/anonymous/10c69e67e78100818ba528897ec343d1/raw/cce9290a7806699463af074627202a974ebad842/schema",
  #config :schema_json,
         #:validate => :string,
         #:required => false,
  

  public
  def register
    # Add instance variables 
    JSON::Validator.schema_reader = JSON::Schema::Reader.new(:accept_uri => true, :accept_file => true)
    @schema_reader = JSON::Schema::Reader.new(
      :accept_uri => proc { |uri| /(thezebra.com|gist.githubusercontent.com)/i.match(uri.host) }
    )

    #schema_uri = "https://gist.githubusercontent.com/anonymous/10c69e67e78100818ba528897ec343d1/raw/cce9290a7806699463af074627202a974ebad842/schema"

    @document2 = {
      "foo" => 12345,
      "bar" => "a",
      "baz" => "a"
    }
  end

  public
  def filter(event)

    #if @message
    #  event.set("message", @message)
    #end
    #return unless filter?(event)

    if not validate(event)
      event.add_tag('_jsonschemafailure')
      event.cancel
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end

  private
  def validate_json_schema(event)
      field_schema_uri = event.sprintf("schema_uri")
      field_json_document = event.sprintf("json_document")
      #JSON::Validator.fully_validate(
      return JSON::Validator.validate(
        schema_uri,
        document2,
        :strict => true,
        :insert_defaults => true,
        :clear_cache => true,
        :schema_reader => schema_reader,
      )
  end

end # class LogStash::Filters::JsonSchema

# vim: ft=ruby ts=2 sw=2

