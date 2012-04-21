_path           = require 'path'
Pathfinder      = require 'pathfinder'
File            = Pathfinder.File

class Listener
  constructor: (options, callback) ->
    @root         = options.root
    @ignored      = options.ignore || []
    @directories  = directories = {}
    @files        = files       = {}
    paths         = File.glob(@root)
    self          = @
    initialized   = []
    
    for source in paths
      continue unless File.exists(source)
      stat        = File.stat(source)
      path        = _path.join(root, source.replace(root, ""))
      unless stat.isDirectory()
        files[path]       = stat
        initialized.push File.relativePath(path)
        #try
        #  callback.call(self, File.relativePath(path), action: "initialize")
        #catch error
        #  console.log error.stack
      else
        directories[path] = File.entries(path)
    
    try
      callback.call self, initialized, action: "initialize"
    catch error
      console.log error.stack
        
  ignore: (path) ->
    for ignoredPath in @ignored
      return true if path.indexOf(ignoredPath) == 0
    return false
  
  changed: (path, callback) ->
    entries     = File.entries(path)
    action      = null
    timestamp   = new Date
    directories = @directories
    files       = @files
    base        = @root
    return if @ignore(path)
    if directories[path] && entries.length < directories[path].length
      directories       = @directories
      action            = "destroy"
      deleted           = directories[path].filter (i) -> !(entries.indexOf(i) > -1)
      directories[path] = entries
      relativePath      = File.join(path, deleted[0]).replace(base + '/', '')
      
      @log relativePath, action: action, timestamp: timestamp, callback
      
      return
    
    directories[path] = entries
    
    for entry in entries
      continue if entry == '.' || entry == '..'
      
      absolutePath  = File.join(path, entry)
      current       = File.stat(absolutePath)
      
      continue if current.isDirectory()
      
      previous    = files[absolutePath]
      changed     = !(previous && current.size == previous.size && current.mtime.getTime() == previous.mtime.getTime())
      
      continue unless changed
      
      files[absolutePath] = current
      
      if !previous
        action ||= "create"
      else
        action ||= "update"
      
      relativePath  = absolutePath.replace(base.toString() + '/', '')
      
      @log relativePath, action: action, timestamp: timestamp, previous: previous, current: current, callback
  
  log: (path, options = {}, callback) ->
    name = if options.action == "destroy" then "deleted" else "#{options.action}d"
    _console.info "#{name} #{path}" # #{options.timestamp.toLocaleTimeString()} - 
    try
      callback.call(@, path, options)
    catch error
      console.log error.stack
  
require './listener/mac'
require './listener/polling'
require './listener/windows'
require './listener/linux'

module.exports = Listener
