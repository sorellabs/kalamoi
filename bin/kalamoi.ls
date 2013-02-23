## Module kalamoi ######################################################
#
# Command line application for generating JSON doc metadata.
#
# 
# Copyright (c) 2013 Quildreen "Sorella" Motta <quildreen@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


doc = '''
      Kalamoi — CLI tool for generating JSON documentation metadata.

      Usage:
        kalamoi generate <json>
        kalamoi -h | --help
        kalamoi --version

      Options:
        -h, --help              Displays this screen and exits.
        -v, --version           Displays the version and exits.
      '''

### -- Dependencies ----------------------------------------------------
fs       = require 'fs'
path     = require 'path'
{print}  = require 'util'
glob     = require 'glob'
pkg-meta = require '../package'
{docopt} = require 'docopt'
{parse}  = require '../'


global <<< require 'prelude-ls'


### -- Helpers ---------------------------------------------------------

# Reads some file, returns its contents
# :: String -> IO String
read = (pathname) ->
  fs.read-file-sync pathname, 'utf-8'

# Reads some JSON file, returns the contents as an Object.
# :: String -> IO Object
read-as-json = (pathname) ->
  JSON.parse (read pathname)

# Writes some contents to a file.
# :: String -> String -> IO ()
write = (pathname, contents) -->
  fs.write-file-sync pathname, contents, 'utf-8'


# Expand glob patterns into file names
# :: String -> [String]
expand-file = (pattern) -> glob.sync pattern

# Expands a list of glob patterns into a list of file names
# :: [String] -> [String]
expand-files = concat-map expand-file 

# Loads and parses a particular file
# :: String -> [Entity]
load-file = (pathname) ->
  parse (path.extname pathname), { file: pathname }, (read pathname)

# Loads entities for a single package
# :: Package -> ProcessedPackage
load-package = (pkg) ->
  entities = concat-map load-file, (expand-files pkg.files)

  prefix     : pkg.prefix
  parent     : pkg.parent
  parentless : entities.filter (.parent is null)
  entities   : entities

# Builds a map of EntityID -> Entity
# :: [ProcessedPackage] -> { String -> Entity }
build-entity-map = (packages) ->
  m = {}
  packages |> each (pkg) ->
    fold (fold-entity pkg.prefix), m, pkg.entities
  m

# Folds an entity into an map
# :: String -> { String -> Entity } -> Entity -> { String -> Entity }
fold-entity = (prefix, map, entity) -->
  map["#{prefix}#{entity.make-id!}"] = entity
  map

# Resolves memberships for parent-less entities
# :: { String -> Entity } -> [ProcessedPackage] -> IO ()
resolve-entity-membership = (entity-map, packages) -->
  packages |> each (pkg) ->
    if pkg.parent
      parent = entity-map[pkg.parent]
      each (-> it.parent = parent), pkg.parentless



### -- Commands --------------------------------------------------------

# Builds a JSON with documentation metadata for Papyr°
# :: String -> IO String
build-doc-meta = (config) ->
  project  = read-as-json config
  packages = map load-package, project.packages
  entity-map = build-entity-map packages
  resolve-entity-membership entity-map, packages
  entities = concat-map (.entities), packages

  print (map (JSON.stringify . (.to-json!)), entities)

# Prints help and exit
# :: () -> IO ()
print-help = ->
  console.log doc
  process.exit 0


### -- Main ------------------------------------------------------------
args = docopt doc, version: pkg-meta.version

switch
| args.generate => build-doc-meta args['<json>']
| otherwise     => print-help!
