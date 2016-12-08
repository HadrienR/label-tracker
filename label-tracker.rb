#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'json'
require 'rest-client'
require 'terminal-table'

program :name, 'tracker-label'
program :version, '0.0.1'
program :description, 'Help track velocity per label on a Pivotal Tracker project.'

command :decribe do |c|
  c.syntax = 'test describe [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Test::Commands::Blob
  end
end

def init
  puts 'welcome to Label Tracker'
  api_key = ask("Please insert your API Key:  ") { |q| q.echo = "*" }
  find_iterations(api_key)
end

class Velocity
  $total_velocity = 0
  $ios = 0
  $android = 0
  $push = 0
end

def find_iterations (api_key)
  url = 'https://www.pivotaltracker.com/services/v5/projects/1860385/iterations/?limit=10&offset=1'
  head = {:'x-trackertoken'=> api_key}
  response = RestClient.get(url, headers = head)
  r = JSON.parse(response.body)
  index = r.length
  last_three_iterations = [r[index - 1], r[index - 2], r[index - 3]]
  find_velocity (last_three_iterations)
end

def find_velocity (last_three)

  last_three.each_with_index do |item, i|
    sum_points(item["stories"], item["team_strength"])
  end

rows = []
rows << ['RUNNING Velocity', $total_velocity / 3]
rows << ['adjusted iOS velocity', $ios / 3]
rows << ['adjusted Android velocity', $android / 3]
rows << ['adjusted Push velocity', $push / 3]
table = Terminal::Table.new :rows => rows
puts table

end

def sum_points(stories, ts)
  iteration_velocity = 0
  stories.each_with_index do |item, i|
    if item["story_type"] == 'feature'
      $total_velocity += item["estimate"]
      iteration_velocity += item["estimate"]
      platform_estimate(item, ts)
    end
  end
  #puts ts
  $total_velocity += iteration_velocity * (1 - ts)
end

def platform_estimate(story, ts)
  estimate = story['estimate'] + story['estimate'] * (1-ts)
  story['labels'].each_with_index do |item, i|
    if item['name'] == 'ios'
      $ios += estimate
    elsif item['name'] == 'android'
      $android += estimate
    elsif item['name'] == 'push server'
      $push += estimate
    end
  end
end

init
