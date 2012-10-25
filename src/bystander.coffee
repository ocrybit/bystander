# * The ultimate development automation tool that does nothing but watch
#  directory trees and boardcasts file changes.
#  It, however, lets many handy plagins listen to file state change events
#  and automates every aspect of a development cycle.

# ### Require Dependencies

# #### Standard Node Modules
fs = require('fs')
path = require('path')
EventEmitter = require('events').EventEmitter
util = require('util')

# #### Third Party Modules
_ = require('underscore')
minimatch = require('minimatch')
colors = require('colors')
FSWatchr = require('fswatchr')
async = require('async')

# ---

# ## Bystander Class
module.exports = class Bystander extends FSWatchr

  # ### Class Properties
  # `@rgoot (String)` : the path to the root directory to watch   
  # `@opts (Objects)` : some options  
  # `@nolog (Bool)` : `true` to suppress stdout messages  
  # `@ignoreFiles (Array)` : glob `String` patterns to ignore files and directories  
  # `@configFile (String)` : a path to the configuration file
 
  # #### constructor
  # `@root` : see *Class Properties* section  
  # `@opts` : see *Class Properties* section
 
  constructor: (@root = process.cwd(), @opts = {}) ->
    # @root
    @opts.root = path.resolve(@root)
    @root = @opts.root

    # @nolog
    @opts.nolog ?= false

    # @configFile
    @configFile = @opts?.configFile ? path.join(@root, '.bystander')

    # ignoreFiles
    @ignoreFiles = @opts.ignore ? []
    if @opts?.ignorePatterns?
      @setIgnoreFiles(@opts.ignorePatterns)

    # plugin options
    unless @opts.by? and typeof(@opts.by) is 'object' and util.isArray(@opts.by) is false
      @opts.by = {}
    # plugins
    @by = {}

    # FSWatchr constructor
    super(@root)

  # ---

  # ### Private Methods
 
  # #### Read a .bystander file
  # `dir (String)` : a path to a directory  
  # `cb (Function)` : a callback function  
  _readConfigFile: (p, cb) ->
    # resolve the config file path
    if not p? or typeof(p) is 'function'
      cb = p
      p = path.join(@root,".bystander")
    else if not p?
      p = path.join(@root,".bystander")
    p = path.resolve(p)
    # read the config file
    fs.readFile(p, 'utf8', (err, body) =>
      if not err
        try
          config = JSON.parse(body)

          # set ignore patterns to @ignoreFiles
          patterns = config.ignore
          if patterns?
            @setIgnoreFiles(patterns)
          if @opts.plugins?.length is 0 and config.plugins?.length isnt 0
            @opts.plugins = config.plugins
          if config.by? and typeof(config.by) is 'object' and util.isArray(config.by) is false
            @opts.by = _.extend(config.by,@opts.by)
          @opts = _.extend(config,@opts)
  
        catch e
          console.log("ERROR! - coudn't parse config file #{p}".red + '\n')

      # callback
      cb(@ignoreFiles)
    )

  # #### set plugins to @by
  _requirePlugins: ->
    if @opts.plugins?
      for v, i in @opts.plugins
        try
          r = require(v)
          @by[path.basename(v).replace(/^by-/i,'')] = new r(@opts)
        catch e
          console.log("ERROR! - #{v} plugin not found!".red + '\n')
          @emit('plugin error', v, "#{v} plugin not found!")

  # #### execute _init method, if any,  for each plugins
  _init: (cb) ->
    async.forEach(
      _(@by).toArray(),
      (v, callback) =>
        if v._init?
          v._init.call(v, ()->
            callback()
          )
        else
          callback()
      =>
        cb()
    )

  # ### execute _init method, if any,  for each plugins
  _setListeners: (cb) ->
    for k, v of @by
      if v._setListeners?
        v._setListeners.call(v, this)
  
  # #### check if the given file should be ignored
  # `dir (String)` : a path to a file
  _isIgnore: (file) ->
    for v in @ignoreFiles
      if minimatch(file, v, {dot : true})
        return true
    return false

  # ---

  # ### Public API

  # #### Add patterns to @ignoreFile
  # `newFiles (Array)` : glob `String`s to add to `@ignoreFile`  
  setIgnoreFiles: (newFiles) ->
    @ignoreFiles = _(@ignoreFiles).union(newFiles)


  # #### Unset ignore patterns for the given directory
  # `dir (String)` : a directory path  
  unsetIgnoreFiles: (patterns) ->
    if patterns?
      @ignoreFiles = _(@ignoreFiles).reject((v) ->
        return patterns.indexOf(v) isnt -1
      )
    return @ignoreFiles

  # #### Run CoffeeStand
  run: ->
    @_readConfigFile(@configFile, =>
      @_requirePlugins()
      @_init(() =>
        @_setListeners()
        # Then get .csmapper
        @setFilter((dir, path)=>
          return @_isIgnore(dir)
        )
        @watch()
      )
    )
