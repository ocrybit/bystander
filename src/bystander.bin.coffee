#!/usr/bin/env coffee

program = require('commander')

Bystander = require('../lib/bystander')

program
  .option('-c, --config <path>', 'a path to a configuration file', '.bystander')
  .option('-i, --ignore <patterns>', 'comma separated ignore patterns (glob)')
  .option('-p, --plugins <plugin names>', 'comma separated plugin names to use')
  .option('--nolog', 'no stdout log messages')
  .option('-b --by <json string>', 'hard code json formatted options for a quick hack')

program
  .parse(process.argv)

dir = program.args[0] ? './'
configFile = program.config
ignorePatterns = program.ignore?.split?(',') ? []
plugins = program.plugins?.split?(',') ? []
nolog = program.nolog ? false

if program.by?
  try
    b = JSON.parse(@opts.by)
    unless @opts.by? and typeof(@opts.by) is 'object' and util.isArray(@opts.by) is false
      b = {}
  catch e
    b = {}

bystander = new Bystander(
  dir,
  {
    configFile: configFile,
    ignorePatterns: ignorePatterns,
    nolog: nolog,
    plugins: plugins,
    by : b
  }
)

bystander.run()
