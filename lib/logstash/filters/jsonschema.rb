# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "json-schema"


class LogStash::Filters::JsonSchema < LogStash::Filters::Base

  config_name "jsonschema"
  
  config :preload_schema_uris,
         :validate => :uri,
         :list => true,
         :required => false
  config :preload_schema_paths,
         :validate => :path,
         :list => true,
         :required => false
  config :schema_uri,
         :validate => :uri,
         :required => true
  config :event_base,
         :validate => :string,
         :required => true
  config :clear_cache_schemas,
         :validate => :boolean,
         :required => false,
         :default => false
  
  public
  def register
    # Add instance variables 
    JSON::Validator.schema_reader = JSON::Schema::Reader.new(:accept_uri => true, :accept_file => true)
    @schema_reader = JSON::Schema::Reader.new(
      :accept_uri => proc { |uri| /(thezebra.com|gist.githubusercontent.com)/i.match(uri.host) }
    )

  end

  public
  def filter(event)
    errors = validate_json_schema(event)
    if errors.any?
      event.set('_jsonschemafailure', "true")
    else 
      event.set('_jsonschemafailure', "false")
    end
    filter_matched(event)
  end

  public
  def validate_json_schema(event)
      event_schema_uri = event.sprintf(schema_uri)
      event_base_type = event.sprintf(event_base)
      clear_cache_schemas = event.sprintf(clear_cache_schemas)
      return JSON::Validator.fully_validate(
        event_schema_uri,
        event.get(event_base_type),
        :strict => true,
        :validate_schema => true,
        :record_errors => true,
        :clear_cache => clear_cache_schemas,
        :schema_reader => @schema_reader,
      )
  end

end # class LogStash::Filters::JsonSchema