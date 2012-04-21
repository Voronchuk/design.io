require 'rubygems'
require 'rb-inotify'

notifier    = INotify::Notifier.new
STDOUT.sync = true
io          = STDOUT
directory   = ARGV[0]

#directory   = STDIN.read
notifier.watch directory, :modify, :recursive do |event|
  # Eliminate the file name
  path = File.dirname(event.absolute_name) + '/'
  io.write [path].inspect
end
notifier.run
