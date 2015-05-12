#!/usr/bin/env ruby

require "octokit"
require "yaml"
require "pp"

def debugging?
  ENV['DEBUG'] && ENV['DEBUG'] != ''
end


organization = ARGV.shift
raise "usage: #{$0} <organization github username>" unless organization

creds = YAML.load(File.read(File.expand_path('~/.github.yml')))
access_token = creds["token"]

client = Octokit::Client.new(:access_token => access_token)
puts "Current octokit rate limit: #{client.rate_limit.inspect}" if debugging?

# Fetch private repositories for the organization
private_repos = client.organization_repositories(organization, { :type => 'private', :per_page => 100 })

last_response = client.last_response
until last_response.rels[:next].nil?
  last_response = last_response.rels[:next].get
  private_repos.concat last_response.data
  puts "Fetched more repositories. Running total: #{private_repos.size}" if debugging?
end

puts "Number of private repos: #{private_repos.size}" if debugging?


# For each private repository, look for a `LICENSE` or `COPYING` file in the root directory
licensed = []
private_repos.each do |repo|

  full_name = repo[:full_name]
  default_branch = repo[:default_branch]

  puts "Looking for license information for repository [#{full_name}] on default branch [#{default_branch}]..."
  begin
    branch = client.branch(repo[:full_name], default_branch)
  rescue Octokit::NotFound => exception
    puts "Warning: repository #{full_name} is missing its default branch (#{default_branch})!  Skipping..."
    next
  end


  commit_sha = branch[:commit][:sha]
  tree_sha = branch[:commit][:commit][:tree][:sha]
  puts "Found commit [#{commit_sha}] with tree [#{tree_sha}]" if debugging?
  puts "Fetching file list for tree [#{tree_sha}]..." if debugging?

  tree = client.tree(full_name, tree_sha)

  if tree[:tree].any? { |blob| blob[:type] == 'blob' && %w(LICENSE COPYING).include?(blob[:path]) }
    puts "Private repository [#{full_name}] at https://github.com/#{full_name}/ DOES appear to have a potentially open-source license." if debugging?
    licensed << full_name
  else
    puts "Private repository [#{full_name}] at https://github.com/#{full_name}/ does not appear to have a license." if debugging?
  end
end

puts "\nPrivate repositories which appear to have a license:\n"

if licensed.empty?
  puts "None."
else
  licensed.each do |repo|
    puts "#{repo}\thttps://github.com/#{repo}/"
  end
end
