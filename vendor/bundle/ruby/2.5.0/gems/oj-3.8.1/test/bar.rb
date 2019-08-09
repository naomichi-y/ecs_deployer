#!/usr/bin/env ruby
# encoding: UTF-8

$: << File.dirname(__FILE__)
$oj_dir = File.dirname(File.expand_path(File.dirname(__FILE__)))
%w(lib ext).each do |dir|
  $: << File.join($oj_dir, dir)
end

require 'oj'

#Oj.load_file(ARGV[0], mode: :strict) { |obj|
#  puts Oj.dump(obj, indent: 2)
#}

data = open('invalid_unicode.data').read

puts data

puts Oj.dump(data)

Oj.mimic_JSON
puts Oj.dump(data, escape_mode: :json)

puts Oj.default_options
