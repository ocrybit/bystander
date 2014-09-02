Bystander
=========

 The ultimate development automation tool that does nothing but watch 
directory trees and boardcasts file changes.
It, however, lets many handy plugins listen to file state change events 
and automates every aspect of a development cycle.
  
The simplest way to automate your entire project from the command-line is run `bystander` in the project root directory with `.bystander` configuration file.

    bystander

Features
--------
* Written in pure [CoffeeScript](http://coffeescript.org/), runs on [Node.js](http://nodejs.org/), acsessible both from command line and node scripts.
* Recursively watch directories and broadcasts file change events. It actually is a sub class of [FSWatchr](https://github.com/tomoio/fswatchr/).
* A great deal of Extensibility through [plugins](#plugins) to automate every aspect of a development cycle.
* Detailed configurations to suit every form of projects.

Installation
------------

Use [npm](https://npmjs.org/), `-g` option is recommended so you can globally use `bystander` CLI.

    sudo npm install -g bystander

Command Line Usage
------------------

    bystander <dir> [options]

> `dir` : the root directory to watch  

Bystander walks down its sub directories and watches the entire project tree. If omitted, `dir` will be set `./` which is the current working directory.

#### Options

> `--nolog` : supress the stdout log messages, useful when using the bystander module in your node scripts  
> `-c` `--config` : path to a configuration file, default to `.bystander`  
> `-i` `--ignore` : comma separeted glob patterns to ignore files, you can also use the `.bystander` config file to do the same  
> `-p` `--plugins` : comma separeted plugin names to use, you can also use the `.bystander` config file to do the same  
> `-b` `--by` : hard code json formatted options, this is only for a quick and dirty hack during Bystander itself and the plugin development, you should use the `.bystander` config file for your other project development.

Note Bystander uses [minimatch](https://github.com/isaacs/minimatch) without `matchBase` option to match glob pattern with file/dir paths.

#### Examples

Unnecesarily using all the options above.

    bystander ./ --nolog -c bystander.json -i "**/node_modules,**/.*" -p "by-coffeescript" -b '{"coffeescript":{"noCompile":["**/test/*"]}}'

> `bystander ./` : run bystander on a project that roots the current working directory.  
> `--nolog` : no outupt, not really useful when using Bystander from command line.  
> `-c bystander.json` : change the location of the configuration file from `.bystander` to `bystander.json`  
> `-i "**/node_modules,**/.*"` : ignore `node_modules` and `.*` directories (e.g. `.git`). Bystander wouldn't even watch the sub directories. So there will be no effect on anything under the ignored directories also with plugins.  
> `-p "by-coffeescript"` : use `by-coffeescript` plugin to auto-compile CoffeeScripts.  
> `-b '{"coffeescript":{"noCompile":["**/test/*"]}}'` : a dirty hack to give `by-coffeescript` plugin `noCompile` option to ignore `test` directory for compiling. Note I didn't ignore`test` directory with `-i` option, because I might want to do something on the files inside `test` directory with other plugins. I let Bystander watch and report changes on `test` directory anyway.

In reality, you don't have to use that many options, everything exept `-c` option can go into the `bystander.json` config file. A equivarent json file would be,

    {
      "nolog" : true,
      "ignore" : ["**/node_modules", "**/."],
      "plugins" : ["by-coffeescript"],
      "by" : {
	    "coffeescript" : {"noCompile" : ["**/test/*"]}
	  }
    }

then you can just do

    bystander ./ -c bystander.json

If you save the config file to the default location, which is `./.bystander`, then

    bystander ./

is fine.  
In fact, `dir` option defaults to `./`, so if you are in the root directory of the project,

    bystander
	
simply works too.

Plugins
-------

To use a plugin, you need to install it alongside with Bystander. For instance,

    sudo npm install -g by-coffeescript

will install [by-coffeescript](http://tomoio.github.com/by-coffeescript/) plugin to compile CoffeeScript when changes are found on your `.coffee` files. To enable the plugin with `bystander` command, refer to [the previous example](#command-line-usage) on how to set `-p` option or write a json config file.

> [by-coffeescript](http://tomoio.github.com/by-coffeescript/) : Auto-compiling CoffeeScript after file changes.  
> [by-write2js](http://tomoio.github.com/by-write2js/) : Auto-write compiled code to a JavaScript file after CoffeeScript compilation.  
> [by-coffeelint](http://tomoio.github.com/by-coffeelint/) : Auto-CoffeeLint  after CoffeeScript compilation.  
> [by-docco](http://tomoio.github.com/by-docco/) : Auto-generate Docco documents  after file changes.  
> [by-mocha](http://tomoio.github.com/by-mocha/) : Auto-run Mocha tests after file changes.

See each plugin pages for options.  

I use Bystander to automate the development of Bystander itself, and this is the config file for [this CoffeeScript/Node-module project](https://github.com/tomoio/bystander/).

    {
      "ignore" : ["**/node_modules","**/.", "**/assets", "**/test/tmp"],   
      "plugins" : ["by-coffeescript", "by-write2js", "by-coffeelint", "by-docco", "by-mocha"],
      "by" : {
        "coffeescript" : {"noCompile" : ["**/test/*"]
        },
        "write2js" : {
          "bin" : true,
          "mapper" : {
            "**/src/*" : ["/src/", "/lib/"]
          }
        },
        "docco" : {
          "doccoSources" : ["src/*.coffee"]
        },
        "mocha" : {
          "testPaths" : ["test/*.coffee"]
        }
      }
    }

In Your Node Scripts
--------------------

Bystander can be also used in your node scripts as a module.  

    Bystander = require('bystander')


see [annotated sorce code](http://tomoio.github.com/bystander/docs/bystander.html) for more details  

Running Tests
-------------

Run tests with [mocha](http://visionmedia.github.com/mocha/)

    make
	
License
-------
**Bystander** is released under the **MIT License**. - see the [LICENSE](https://raw.github.com/tomoio/bystander/master/LICENSE) file
