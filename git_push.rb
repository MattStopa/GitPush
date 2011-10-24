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

  def self.count_lines_of_code(file_name)
    empty = 0
    code = 0
    comments = 0
    puts file_name
    File.open(file_name).each do |line|
        if !(line =~ /[a-z]/)
          empty += 1
        elsif line.strip[0] == '#'
          comments += 1
        else
          code += 1
        end
    end
    { :empty => empty, :code => code, :comments => comments }
  end

  def self.extract_commit_info(author_line, changes_line)
      author_email = extract_author_name(author_line)
      changed = extract_lines_changed(changes_line)
      { :author =>  author_email, :inserts => changed.first, :deletes => changed.last }
  end

  def self.extract_author_name(author_line)
      email_start = author_line.index("<")
      email_stop = author_line.index("\n")
      return "unknown" if email_start.nil?
      author_line[email_start + 1, email_stop - email_start - 2]
  end

  def self.extract_lines_changed(changes_line)
      comma_one = changes_line.index(",")
      insertions = changes_line.index("insertions")
      comma_two = changes_line.index(",", comma_one.succ)
      deletions = changes_line.index("deletions")

      insert_amount = changes_line[comma_one.succ, insertions - comma_one.succ].strip.to_i
      delete_amount = changes_line[comma_two.succ, deletions - comma_two.succ].strip.to_i
      [insert_amount, delete_amount]
  end

  def generate_stats
    file_path = "./"
    get_file_stats(file_path)
    file_stats.each do |key, item|
      puts "Extension: #{key}, #{item[:code]}, #{item[:empty]}, #{item[:comments]}"
    end
  end

  def get_file_stats(file_path)
    Dir.foreach(file_path) do |entry|
      next if (entry == '.' || entry == '..' || entry[0] == '.')
      if File.directory?(file_path + entry)
        next if entry == "lib"
        get_file_stats(file_path + entry + "/")
      else
        if entry.include?('.')
          index = entry.size - entry.reverse.index('.')
          extenstion = entry[index, entry.size]
          extenstion = "none" if extenstion == "" || extenstion == nil

          next if extenstion == 'log'

          begin
            loc = GitPush.count_lines_of_code(file_path + entry)
          rescue
            next
          end
          if file_stats[extenstion] == nil
            file_stats[extenstion] = loc
          else
            file_stats[extenstion] = { :empty => file_stats[extenstion][:empty] + loc[:empty],
                                       :code => file_stats[extenstion][:code] + loc[:code],
                                       :comments => file_stats[extenstion][:comments] + loc[:comments] }
          end
        end
      end
    end
  end

  def process_file
    author_line, changed_line = nil, nil

    File.open("./portal.txt").each do |line|
      author_line = line if line =~ /Author/
      changes_line = line if line =~ /files changed/

      if changes_line != nil
        add_commit(GitPush.extract_commit_info(author_line, changes_line))
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

class Commit
  attr_accessor :inserts, :deletes, :amount

  def initialize
    self.inserts = 0
    self.deletes = 0
    self.amount = 0
  end

  def total
    inserts + deletes
  end

  def update_commits(inserts, deletes)
    self.inserts += inserts
    self.deletes += deletes
    self.amount += 1
  end
end

GitPush.new