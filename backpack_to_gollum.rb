#!/usr/bin/env ruby

## Fetch export.xml from <your-account>.backpackit.com/account/exports

require 'logger'
require 'erb'
require 'iconv'

require 'rubygems' unless defined? Gem
require 'bundler/setup'
require 'xmlsimple'
require 'pandoc-ruby'

@log = Logger.new(STDOUT)
@log.level = Logger::DEBUG

OUTPUT_DIR = 'notes'
Dir.mkdir(OUTPUT_DIR) unless File.exists?(OUTPUT_DIR)

to_ascii = Iconv.new("ASCII//TRANSLIT//IGNORE", "UTF-8")

def textile_to_markdown(text)
  PandocRuby.convert(text, :from => :textile, :to => :markdown)
end

def title_to_filename(text)
  text.gsub(" ", "_").gsub(/[^A-Za-z0-9]/, "_").gsub(/_+/, '_')
end

input = XmlSimple.xml_in(File.read('export.xml'))

pages = {}

def pluralize(text)
  if text =~ /y$/
    text = text.sub(/y$/, 'ies')
  else
    text += "s"
  end
  text
end

def get_by_id(page, type, id)
  outputs = page[pluralize(type)][0][type].select { |data| data['id'] == id }
  if outputs.size > 0
    outputs[0]
  else
    nil
  end
end

def fetch_content(belonging, page)
  widget_type = belonging['widget'][0]['type']
  widget_id   = belonging['widget'][0]['id']
  @log.info("\t#{widget_type} #{widget_id}")
  case widget_type
  when 'Note'
    output = get_by_id(page, 'note', widget_id)
    template = %Q{
<% unless output['title'].empty? %>
# <%= output['title'] %>
<% end %>

<%= textile_to_markdown(output['content']) %>
}
  ERB.new(template).result(binding)
  when 'Separator'
    output = get_by_id(page, 'separator', widget_id)
    if output.keys.include?('content') && ! output['content'].empty?
      template = %Q{
---
# <%= output['content'] %>
---
}
    else
      template = %Q{
---
}
    end
    ERB.new(template).result(binding)
  when 'List'
    data = get_by_id(page, 'list', widget_id)
    template = %Q{
<% unless data.nil? %>
# TODO <%= data['name'] %>
<% data['items'][0]['item'].each do |item| %><% if item['completed'] == 'true' %>
* [X] <%= item['content'] %><% else %>
* [] <%= item['content'] %><% end %><% end %><% end %>
}
    ERB.new(template).result(binding)
  when 'Asset'
    data = get_by_id(page, 'attachment', widget_id)
    template = %Q{
TBD file <%= data['file_name'] %>
}
    ERB.new(template).result(binding)
  when 'Email'
    data = get_by_id(page, 'email', widget_id)
    template = %Q{
TBD email <%= data['subject'] %>
}
    ERB.new(template).result(binding)
  when 'Gallery'
    data = get_by_id(page, 'gallery', widget_id)
    template = %Q{
# <%= data['name'] %>
<% data['images'][0]['image'].each do |image| %>
TBD <%= image['description'] %> ( <%= image['file_name'] %> )
<% end %>
}
    ERB.new(template).result(binding)
  when 'WriteboardLink'
    template = %Q{
TBD <%= widget_type %> <%= widget_id %> (There is no identifying information about the name of the Writeboard)
}
    ERB.new(template).result(binding)
  else
    @log.error("Haven't handled #{widget_type}")
  end
end

input['pages'][0]['page'].each do |page|
  @log.info("#{page['id']} #{page['title']}")
  filename = title_to_filename(page['title'])
  pages[page['title']] = filename

  File.open(File.join(OUTPUT_DIR, "#{filename}.md"), "w") do |file|
    file << %Q{
# #{page['title']}
}

    page['belongings'][0]['belonging'].each do |belonging|
      file << to_ascii.iconv(fetch_content(belonging, page))
    end
  end
end

File.open(File.join(OUTPUT_DIR, 'Home.md'), "w") do |file|
  pages.keys.sort.each do |page_name|
    page_file = pages[page_name]
    template = %Q{ * [[<%= page_file %>]]
}
    file << ERB.new(template).result(binding)
  end
end

Dir.chdir(OUTPUT_DIR)
%x|git init|
%x|git add .|
%x|git commit -m "Initial commit, ported via backpack_to_gollum.rb"|

@log.info("Done")
