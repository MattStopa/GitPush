require './git_parse.rb'
require './git_commit.rb'
require './git_stats.rb'

class GitPush
  attr_accessor :commits, :file_stats

  def initialize
    @commits = {}
    @file_stats = {}

    if ARGV.first == "stats"
      generate_stats
    else
      process_file
      display_output
    end
  end

  def generate_stats
    file_path = "./"
    self.file_stats = GitStats.get_file_stats(file_path, file_stats)
    file_stats.each do |key, item|
      puts "Extension: #{key}, #{item[:code]}, #{item[:empty]}, #{item[:comments]}"
    end
  end

  def process_file
    author_line, changed_line = nil, nil

    File.open("./portal.txt").each do |line|
      author_line = line if line =~ /Author/
      changes_line = line if line =~ /files changed/

      if changes_line != nil
        add_commit(GitParse.extract_commit_info(author_line, changes_line))
        author_line, changes_line = nil, nil
      end
    end
  end

  def display_output
    rank = 1
    rank_commits.each do |name, commit|
      puts "RANK #{rank}, #{commit.amount} commits, #{commit.total} total, #{commit.inserts} additions, #{commit.deletes} deletions by #{name} "
      rank += 1
    end

    amounts, totals, inserts, deletes, sum = 0, 0, 0, 0, 0

    rank_commits.each do |name, commit|
      argv = ARGV.inject { |str, element| str += "|" + element }

      if name =~ /#{argv}/
        amounts += commit.amount
        totals += commit.total
        inserts += commit.inserts
        deletes += commit.deletes
      end
    end
    puts "#{amounts} commits, #{totals} total, #{inserts} additions, #{deletes} deletions"
  end

  def rank_commits
    last_name = nil
    ranked = []
    commits.each do |name, commit|
      num = commit.amount
      position = new_position(ranked, commit, :amount)
      ranked.insert(position, [name, commit])
    end
    ranked
  end

  def new_position(ranked, commit, sort_by = :amount)
    return 0 if ranked == []
    ranked.each_with_index do |rank, index|
      if index == ranked.size.pred
        return rank.last.send(sort_by) < commit.send(sort_by) ? index : index + 1
      elsif rank.last.send(sort_by) < commit.send(sort_by)
        return index
      end
    end
  end

  def add_commit(commit)
    committer = commit[:author]
    c = commits[committer].nil? ? Commit.new : commits[committer]
    c.update_commits(commit[:inserts], commit[:deletes])
    commits[committer] = c
  end
end

GitPush.new