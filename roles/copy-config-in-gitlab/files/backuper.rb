require 'optparse'
require 'fileutils'

=begin
  Парсинг аргументов коммандной строки.
=end

options = {}

OptionParser.new do |opts|
  opts.banner = 'Usage of batya configs backuper: backuper.rb [options]

Example:
backuper.rb --source-dir=/etc --source-dir=/usr/local/etc --dest-dir=/backup/configs --git-path=/usr/bin/git

'

  # Исходные директории, которые нужно бэкапить.
  opts.on('-s', '--source-dir DIRECTORY', 'Source directories for backup. Param can be set few times.') do |source_dir|
    options[:source_dir] ||= []
    options[:source_dir] << source_dir
  end

  # Директория, в которую складываются резервные копии.
  opts.on('-d', '--dest-dir DIRECTORY', 'Destination directory for backup.') do |dest_dir|
    options[:dest_dir] = dest_dir
  end

  # Директория, в которую складываются резервные копии.
  opts.on('-g', '--git-path PATH', 'Path to git.') do |git_path|
    options[:git_path] = git_path
  end

  # Адрес репозитория для пуша.
  opts.on('-r', '--git-repo REPO', 'GIT repository to push changes after commit.') do |repo|
    options[:repo] = repo
  end

  # Сообщение для коммита в GIT.
  opts.on('-m', '--message MESSAGE', 'Message to commit. If empty, will be replaced by auto-generated message.') do |message|
    options[:message] = message
  end

  # Показывать ли отладочные сообщения на экран и в файл.
  opts.on('-v', '--[no-]verbose', 'Run verbosely.') do |verbose|
    options[:verbose] = verbose
  end
end.parse!

=begin
  Присваиваю переменные из словаря, что б попроще было.
=end

source_dirs = options[:source_dir]
dest_dir = options[:dest_dir]
git_path = options[:git_path]
repo = options[:repo]
message = options[:message]
verbose = options[:verbose]

=begin
  Проверка, что все аргументы были переданы.
=end

# исходная директория
if source_dirs.nil? || source_dirs.empty?
  puts 'Source dir empty.'

  exit 1
end

# директория назначения
if dest_dir.nil?
  puts 'Dest dir empty.'

  exit 1
end

# путь к GIT
if git_path.nil? || !File.exist?(git_path)
  puts 'GIT path not specified or file not exists.'

  exit 1
end

# адрес репозитория для пуша.
if repo.nil?
  puts 'GIT repository for push after commit not specified.'

  exit 1
end

# сообщение
message = "Autocommit at #{Time.now}" if message.nil?

=begin
  Начало работы.
=end

Dir.chdir(dest_dir)

puts "Batya's config backuper. Running at #{Time.now}\r\n\r\n"
puts "Current working dir #{Dir.pwd}"

=begin
  Создаю каталог для бекапа, если не существует, или удаляю содержимое
  каталога dest_dir, кроме ".", ".." и ".git", если он присутствует.
=end

if !Dir.exist?(dest_dir)
  puts "Seems like destination directory does not exists - #{dest_dir}. Creating..." if verbose

  Dir.mkdir(dest_dir)
else
  puts "Clean destination directory - #{dest_dir}" if verbose

  Dir.entries(dest_dir).each do |e|
    next if %w(. .. .git).include?(e)

    dir_element = File.join(dest_dir, e)
    puts "Deleting #{dir_element}..." if verbose
    FileUtils.rm_rf(dir_element)
  end
end

=begin
  Копирование новых файлов.
=end

puts "\r\n"
puts 'Starting copy source directories...' if verbose

source_dirs.each do |x|
  # если Windows, то удаляем [drive_letter]:\ из пути.
  if x.include? ':\\' then
    separator = '\\'
    path = x[3..-1]
    # если линупс - то первый слеш.
  else
    separator = '/'
    path = x[1..-1]
  end

  # создаю полный путь - директория на значения, и структура каталогов от
  # текущего source_dir.
  path = dest_dir + separator + path.split(separator).join(separator)
  puts "Creating directory #{path}..." if verbose
  FileUtils.mkdir_p(path)

  # и копирую файлы
  puts "Copying #{x} -> #{dest_dir}..." if verbose
  FileUtils.copy_entry(x, path)
end

=begin
  Делаю коммиты.
=end

puts "\r\n"
puts 'Starting working with GIT...' if verbose

# лямбда для вызова GIT.
git = -> (p) { system "#{git_path} #{p}" }
#git = -> (p) { system "echo git #{p}" }
git.("add *")
git.("commit -m '#{message}'")
git.("push #{repo}")

exit 0
