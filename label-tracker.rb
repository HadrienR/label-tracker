#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'json'
require 'rest-client'
require 'terminal-table'

program :name, 'tracker-label'
program :version, '0.0.1'
program :description, 'Help track velocity per label on a Pivotal Tracker project.'

class Velocity
  $total_velocity = 0
  $labels_velocity = {}
end

class Me
  $api_key = 0
end

def init
  puts 'Welcome to Label Tracker'
  $api_key = ask("Please insert your API Token:  ") { |q| q.echo = "*" }
  find_projects
end

def tracker_get (url)
  head = {:'x-trackertoken'=> $api_key}
  response = RestClient.get(url, headers = head)
  return JSON.parse(response.body)
end

def find_projects
  url = "https://www.pivotaltracker.com/services/v5/projects/"
  projects = tracker_get(url)
  rows = []
  projects.each_with_index do |project, i|
    rows << [i, project['name'], project['id']]
  end
  table = Terminal::Table.new :headings => ['#', 'Name', 'id'], :rows => rows
  puts table
  puts 'Please select the project you want to analyze by typing the relevant number #, (ex: "0")'
  project_number = ask("Project # ?", Integer) { |q| q.in = 0..999 }
  find_iterations(rows[project_number][2])
end

def find_iterations (project_id)
  url = "https://www.pivotaltracker.com/services/v5/projects/#{project_id}/iterations/?limit=10&offset=1"
  r = tracker_get(url)
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
  rows << :separator

  $labels_velocity.each do |key, value|
    rows << [key, value]
  end

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
    if $labels_velocity[item['name']].is_a? Numeric
        $labels_velocity[item['name']] += estimate
    else
      $labels_velocity[item['name']] = estimate
    end

  end
end

init
