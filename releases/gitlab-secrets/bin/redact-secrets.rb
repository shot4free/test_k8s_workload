#!/usr/bin/env ruby

# Usage:
#
# mkdir releases/gitlab-secrets/private
# cd !$
# <chef-repo>/bin/gkms-vault-pull gitlab-omnibus-secrets gstg
# mv gitlab-omnibus-secrets-gstg.json secrets.json
# ../bin/redact-secrets.rb secrets.json

require 'json'
require 'base64'

path = ARGV[0]

def redact_value(key, value)
  ret = 'TODO'
  ret = Base64.encode64(ret) if key.end_with?('base64')
  ret
end

def redact_values(node)
  case node
  when String
  when NilClass
  when Hash
    node.each do |k, v|
      node[k] = redact_value(k, v) if v.class == String
      redact_values(v)
    end
  when Array
    node.each_with_index do |e, i|
      node[i] = 'TODO' if e.class == String
      redact_values(e)
    end
  else
    raise "Unsupported type: #{node.class}: #{node.inspect}"
  end
end

secrets = JSON.parse(File.read(path))
redact_values(secrets)
File.write(path, JSON.pretty_generate(secrets))
