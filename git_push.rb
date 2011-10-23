class GitPush
  attr_accessor :commits


  def initialize
    @commits = {}
    process_file
    display_output
  end

  def self.extract_commit_info(author_line, changes_line)
      author_email = extract_author_name(author_line)
      changed = extract_lines_changed(changes_line)
      { :author =>  author_email, :inserts => changed.first, :deletes => changed.last }
  end

  def self.extract_author_name(author_line)
      email_start = author_line.index("<")
      email_stop = author_line.index("\n")
      author_line[email_start + 1, email_stop - email_start - 2]
  end

  def self.extract_lines_changed(changes_line)
      comma_one = changes_line.index(",")
      insertions = changes_line.index("insertions")
      comma_two = changes_line.index(",", comma_one.succ)
      deletions = changes_line.index("deletions")

      insert_count = changes_line[comma_one.succ, insertions - comma_one.succ].strip.to_i
      delete_count = changes_line[comma_two.succ, deletions - comma_two.succ].strip.to_i
      [insert_count, delete_count]
  end

  def process_file

    author_line = nil
    changed_line = nil

    File.open("./small_sample.txt").each do |line|
      author_line = line if line =~ /Author/
      changes_line = line if line =~ /files changed/

      if changes_line != nil
        add_commit(GitPush.extract_commit_info(author_line, changes_line))
        author_line, changes_line = nil, nil
      end
    end
  end

  def display_output
    commits.each do |name, commit|
      puts "#{commit.total} total, #{commit.inserts} additions,#{commit.deletes} deletions by #{name} "
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
  attr_accessor :inserts, :deletes

  def initialize
    self.inserts = 0
    self.deletes = 0
  end

  def total
    inserts + deletes
  end

  def update_commits(inserts, deletes)
    self.inserts += inserts
    self.deletes += deletes
  end
end

GitPush.new