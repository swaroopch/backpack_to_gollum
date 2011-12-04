#!/usr/bin/env ruby

## Follow instructions at [[http://help.37signals.com/highrise/questions/16-can-i-export-notes-deals-or-cases-from-highrise]] to get a zip file
## Then copy this file to the contacts folder and run it to get a simplified version of the ugly YAML files that 37Signals gives us.

require 'logger'
require 'yaml'
require 'erb'
require 'rubygems' if not defined? Gem

@log = Logger.new(STDOUT)
@log.level = Logger::DEBUG

OUTPUT_DIR = "people"
Dir.mkdir(OUTPUT_DIR) unless File.exists?(OUTPUT_DIR)

def title_to_filename(text)
  text.gsub(" ", "_").gsub(/[^A-Za-z0-9]/, "_").gsub(/_+/, '_')
end

@template = %Q{
<% input.each do |data| %>
  <% if data.include?('Name') %>
# <%= data['Name'] %>
  <% elsif data.include?('Contact') %>
    <% if ! data['Contact'][0].nil? && ! data['Contact'][0][1].nil? %>
      <% data['Contact'][0][1].each do |address| %>
Address: <%= address %>
      <% end %>
    <% end %>
    <% if ! data['Contact'][1].nil? && ! data['Contact'][1][1].nil? %>
      <% data['Contact'][1][1].each do |phone| %>
Phone: <%= phone %>
      <% end %>
    <% end %>
  <% elsif data.include?('Background') %>
Background:
<%= data['Background'] %>
  <% elsif data.size > 0 # assume notes %>
    <% data.each do |note_data| %>
      <% if note_data.keys.join("") =~ /note/i %>
        <% note_data.values[0].each do |node_datum| %>
          <% if node_datum.include?('Written') %>
## <%= node_datum['Written'] %>
          <% end %>
        <% end %>
        <% note_data.values[0].each do |node_datum| %>
          <% if node_datum.include?('Body') %>
<%= node_datum['Body'] %>
          <% end %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
}

Dir['*.txt'].each do |file|
  output_filename = File.join(OUTPUT_DIR, title_to_filename(file.gsub(/\.txt$/, ''))) + ".md"
  @log.info("Writing to #{output_filename}")
  input = YAML.load_file(file)
  File.open(output_filename, "w") do |output|
    output << ERB.new(@template).result(binding)
  end
end

