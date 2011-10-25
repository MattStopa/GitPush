class GitParse
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
end