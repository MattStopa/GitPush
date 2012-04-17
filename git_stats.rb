class GitStats

  def self.get_file_stats(file_path, file_stats)
    Dir.foreach(file_path) do |entry|
      next if nativation_element?(entry)
      extenstion = get_extension(entry)

      if File.directory?(file_path + entry)
        next if directory_to_ignore?(entry)
        get_file_stats(file_path + entry + "/")
      elsif extenstion_valid?(extenstion)
        stats = compile_statistics(file_path, entry)
        assign_statistics(file_stats, extenstion, stats)
      end

    end
    file_stats
  end

  def self.nativation_element?(dir)
    (dir == '.' || dir == '..' || dir[0] == '.')
  end

  def self.empty?(line)
    !(line =~ /[a-z]/)
  end

  def self.directory_to_ignore?(directory)
    ["lib"].include?(directory?)
  end

  def self.ignore_extenstion?(extenstion)
    ['log'].include?(extenstion)
  end

  def self.get_extension(entry)
    return 'none' if !entry.include?('.')
    index = entry.size - entry.reverse.index('.')
    entry[index, entry.size]
  end

  def self.extenstion_valid?(ext)
    ext != nil && !ignore_extenstion?(ext)
  end

  def self.compile_statistics(file_path, entry)
    begin
      count_lines_of_code(file_path + entry)
    rescue
      return nil
    end
  end

  def self.count_lines_of_code(file_name)
    empty, code, comments = 0, 0, 0
    puts file_name
    File.open(file_name).each do |line|
      if empty?(line)
        empty += 1
      elsif line.strip[0] == '#'
        comments += 1
      else
        code += 1
      end
    end
    { :empty => empty, :code => code, :comments => comments }
  end

  def self.assign_statistics(file_stats, extenstion, loc)
    return file_stats if loc == nil
    if file_stats[extenstion] == nil
      file_stats[extenstion] = loc
    else
      file_stats[extenstion] = { :empty => file_stats[extenstion][:empty] + loc[:empty],
                                 :code => file_stats[extenstion][:code] + loc[:code],
                                 :comments => file_stats[extenstion][:comments] + loc[:comments] }
    end
    file_stats
  end
end