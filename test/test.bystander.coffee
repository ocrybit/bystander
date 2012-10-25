fs = require('fs')
path = require('path')

async = require('async')
_ = require('underscore')
rimraf = require('rimraf')
mkdirp = require('mkdirp')
coffee = require('coffee-script')
chai = require('chai')
should = chai.should()

Bystander = require('../lib/bystander')

describe('Bystander', ->
  GOOD_CODE = 'foo = 1'
  BAD_CODE = 'foo ==== 1'
  TMP = "#{__dirname}/tmp"
  FOO = "#{TMP}/foo"
  SRC = "#{TMP}/src"
  MILK = "#{SRC}/milk.coffee"
  TEST = "#{TMP}/test"
  MILKTEST = "#{TEST}/test.milk.coffee"
  FOO2 = "#{TMP}/foo2"
  NODIR = "#{TMP}/nodir"
  NOFILE = "#{TMP}/nofile.coffee"
  HOTCOFFEE = "#{TMP}/hot.coffee"
  BLACKCOFFEE = "#{TMP}/black.coffee"
  LINTJSON = "#{TMP}/.coffeelint"
  AMERICANCOFFEE = "#{FOO2}/american.coffee"
  ICEDCOFFEE = "#{FOO}/iced.coffee"
  TMP_BASE = path.basename(TMP)
  FOO_BASE = path.basename(FOO)
  FOO2_BASE = path.basename(FOO2)
  NODIR_BASE = path.basename(NODIR)
  NOFILE_BASE = path.basename(NOFILE)
  HOTCOFFEE_BASE = path.basename(HOTCOFFEE)
  BLACKCOFFEE_BASE = path.basename(BLACKCOFFEE)
  ICEDCOFFEE_BASE = path.basename(ICEDCOFFEE)
  IGNORE_PATTERNS = ["**/foo", "**/black.coffee"]
  BY = {coffeescript : {test : true}}
  CONFIG = {"ignore" : IGNORE_PATTERNS, by : BY}
  CONFIG_FILE = "#{TMP}/.bystander"
  CONFIG_FILE2 = "#{FOO}/.bystander"
  MAPPER_RURES = {'**/src/**' : [/\/src\//, '/lib/']}
  CSIGNORE = "#{TMP}/.csignore"
  CSMAPPER = "#{TMP}/.csmapper"
  DEFAULT_IGNOREFILES = ['**/.*', '**/node_modules']
  LINT_CONFIG = {"no_tabs" : {"level" : "error"}}
  SAMPLE_PLUGIN = coffee.compile([
    "EventEmitter = require('events').EventEmitter",
    "module.exports = class Plugin extends EventEmitter",
    "  _init : (callback) ->",
    "    @emit('_init successful')",
    "    callback()",
    "  _setListeners : (@bystander) ->",
    "    @emit('_setListeners successful')",
  ].join('\n'))
  PLUGIN = "#{TMP}/plugin"
  bystander = new Bystander()
  stats = {}

  beforeEach((done) ->
    mkdirp(FOO, (err) ->
      async.forEach(
        [HOTCOFFEE, ICEDCOFFEE],
        (v, callback) ->
          fs.writeFile(v, GOOD_CODE, (err) ->
            async.forEach(
              [FOO, HOTCOFFEE,ICEDCOFFEE,BLACKCOFFEE],
              (v, callback2) ->
                fs.stat(v, (err,stat) ->
                  stats[v] = stat
                  callback2()
                )
              ->
                callback()
            )
          )
        ->
          bystander = new Bystander(TMP)
          done()
      )
    )
  )

  afterEach((done) ->
    rimraf(TMP, (err) ->
      bystander.removeAllListeners()
      done()
    )
  )

  describe('#constructor', ->
    it('init test', ->
      Bystander.should.be.a('function')
    )
    it('should instanciate', ->
      bystander.should.be.a('object')
      
    )
    it('should set @root to  cwd when not defined', ->
      bystander = new Bystander()
      bystander.root.should.equal(process.cwd())
    )
    it('should set @root', ->
      bystander = new Bystander(TMP)
      bystander.root.should.equal(TMP)
    )
    it('should set @opt.nolog', () ->
      bystander.opts.nolog.should.not.be.ok
      bystander = new Bystander(TMP,{nolog : true})
      bystander.opts.nolog.should.be.ok
    )
    it('should set @configFile', () ->
      bystander.configFile.should.equal("#{TMP}/.bystander")
      bystander = new Bystander(TMP,{configFile : CONFIG_FILE})
      bystander.configFile.should.equal(CONFIG_FILE)
    )
    it('should set ignoreFiles', () ->
      bystander.ignoreFiles.should.be.empty
      bystander = new Bystander(TMP,{ignore : IGNORE_PATTERNS})
      bystander.ignoreFiles.should.eql(IGNORE_PATTERNS)
    )
    it('should set @opts.by', () ->
      bystander.by.should.be.empty
      bystander = new Bystander(TMP,CONFIG)
      bystander.opts.by.should.eql(BY)
      bystander = new Bystander(TMP,{by : 3})
      bystander.opts.by.should.be.empty
      bystander = new Bystander(TMP,{by : IGNORE_PATTERNS})
      bystander.opts.by.should.be.empty
    )
  )
  describe('_requirePlugins', ->
    it('should require plugins', (done) ->
      bystander.opts.plugins = [PLUGIN]
      bystander.once('plugin error', (plugin, message) =>
        plugin.should.equal(PLUGIN)
        fs.writeFile(PLUGIN, SAMPLE_PLUGIN, (err) ->
          bystander._requirePlugins()
          should.exist(bystander.by.plugin)
          done()
        )
      )
      bystander._requirePlugins()
    )  
  )
  describe('_init', ->
    it('should execute _init of each plugin', (done) ->
      bystander.opts.plugins = [PLUGIN]
      count = 0
      fs.writeFile(PLUGIN, SAMPLE_PLUGIN, (err) ->
        bystander._requirePlugins()
        should.exist(bystander.by.plugin)
        bystander.by.plugin.on('_init successful',()->
          count += 1
        )
        bystander._init(()->
          count.should.equal(1)
          done()
        )
      )
    )  
  )

  describe('_setListeners', ->
    it('should execute _setListeners of each plugin', (done) ->
      bystander.opts.plugins = [PLUGIN]
      count = 0
      fs.writeFile(PLUGIN, SAMPLE_PLUGIN, (err) ->
        bystander._requirePlugins()
        should.exist(bystander.by.plugin)
        bystander.by.plugin.on('_setListeners successful',()->
          done()
        )
        bystander._setListeners()
      )
    )  
  )

  describe('_isIgnore', () ->
    it("check if a directory should be ignored", () ->
      bystander = new Bystander(
        TMP,
        {
          ignorePatterns : ['**/foo', '**/foo2', '**/hoo*', "#{TMP}/my.coffee"]
        }
      )
      truthys = ['foo', 'hoo2', '/dir/foo2', "#{TMP}/my.coffee"]
      falsey = ['foo3', 'fool', 'my.coffee']
      for v in truthys
        bystander._isIgnore(v).should.be.ok
      for v in falsey
        bystander._isIgnore(v).should.not.be.ok
    )
  )

  describe('setIgnoreFiles', ->
    it('add to ignoreFiles', ->
      bystander.setIgnoreFiles(IGNORE_PATTERNS)
      bystander.ignoreFiles
        .should.be.eql(IGNORE_PATTERNS)
    )
  )

  describe('_readConfigFile', ->
    it('read config from .bystander) file',(done)->
      fs.writeFile(CONFIG_FILE2, JSON.stringify(CONFIG), (err) ->
        fs.exists(CONFIG_FILE2, (exist) ->
          exist.should.be.ok
          bystander._readConfigFile(CONFIG_FILE2, ()=>
            bystander.ignoreFiles
              .should.eql(IGNORE_PATTERNS)
            done()
          )
        )
      )
    )
  )

  describe('unsetIgnoreFiles', ->
    it('unset ignore patterns', () ->
      bystander.setIgnoreFiles(IGNORE_PATTERNS)
      bystander.ignoreFiles
        .should.be.eql(IGNORE_PATTERNS)
      bystander.unsetIgnoreFiles(IGNORE_PATTERNS)
      bystander.ignoreFiles.should.be.empty
    )
  )

  describe('watch', ->
    it('watch dir for file creation', (done) ->
      bystander.once('watchset', (dirname)->
        bystander.once('File created', (file) ->
          file.should.equal(BLACKCOFFEE)
          done()
        )
        fs.writeFile(BLACKCOFFEE,GOOD_CODE)
      )
      bystander.watch()
    )
    it('watch dir for file removal', (done) ->
      bystander.once('watchset', (dirname)->
        bystander.once('File removed', (file) ->
          file.should.equal(HOTCOFFEE)
          done()
        )
        fs.unlink(HOTCOFFEE)
      )
      bystander.watch()
    )
    it('watch dir for file change', (done) ->
      bystander.once('watchset', (dirname)->
        bystander.once('File changed', (file) ->
          file.should.equal(HOTCOFFEE)
          done()
        )
        fs.utimes(HOTCOFFEE, Date.now(), Date.now())
      )
      bystander.watch()
    )
  )

  describe('#run', ->
    it('should watch a newly created sub directory', (done) ->
      bystander.once('watchset', (data)->
        bystander.on('watchset', (file) ->
          if file is FOO2
            bystander.once('File created', (file) ->
              done()
            )
            fs.writeFile(AMERICANCOFFEE, GOOD_CODE)
        )
        fs.mkdir(FOO2)
      )
      bystander.run()
    )
  )
)
