# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.

require 'wit'

if ARGV.length == 0
  puts("usage: #{$0} <wit-access-token>")
  exit 1
end

access_token = ARGV[0]
ARGV.shift

# Celebrities example
# See https://wit.ai/aleka/wit-example-celebrities/

def first_entity_resolved_value(entities, entity)
  return nil unless entities.has_key? entity
  val = entities[entity][0]['resolved']['values'][0]
  return nil if val.nil?
  return val
end

def first_trait_value(traits, trait)
  return nil unless traits.has_key? trait
  val = traits[trait][0]['value']
  return nil if val.nil?
  return val
end

def handle_message(response)
  greetings = first_trait_value(response['traits'], 'wit$greetings')
  celebrity = first_entity_resolved_value(response['entities'], 'wit$notable_person:notable_person')

  case
  when celebrity
    return wikidata_description(celebrity)
  when greetings
    return "Hi! You can say something like 'Tell me about Beyonce'"
  else
    return "Um. I don't recognize that name. " \
            "Which celebrity do you want to learn about?"
  end
end

def wikidata_description(celebrity)
  return "I recognize #{celebrity['name']}" unless celebrity.dig('external', 'wikidata')
  wikidata_id = celebrity.fetch('external').fetch('wikidata')
  api = URI("https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&ids=#{wikidata_id}&props=descriptions&languages=en")
  rsp = Net::HTTP.get_response(api)
  wikidata = JSON.parse(rsp.body)
  description = wikidata['entities'][wikidata_id]['descriptions']['en']['value']
  return "ooo yes I know #{celebrity['name']} -- #{description}"
end

client = Wit.new(access_token: access_token)
client.interactive(method(:handle_message))
