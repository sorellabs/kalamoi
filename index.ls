## Module kalamoi ######################################################
#
# The entry-point for kalamoi documentation parsing.
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

ast    = require './src/ast-resolver'
parser = require './src/parser'

# Sanitises a language's name
# :: String -> String
sanitised-name = (.to-lower-case!)

# Resolves the language name from the extension.
# :: String -> String
language-for = (extension) -> switch sanitised-name extension
  | \.ls     => 'LiveScript'
  | \.coffee => 'CoffeeScript'
  | \.js     => 'JavaScript'

# Resolves the syntax to use for the given language.
# :: String -> Syntax
syntax-for = (language) -> switch sanitised-name language
  | \livescript   => parser.base-syntax
  | \coffeescript => parser.base-syntax
  | \javascript   => parser.c-syntax

# Parses contents for the specified language.
# :: String -> { String -> String } -> String -> [Entity]
parse = (extension, meta, contents) -->
  language = language-for extension
  meta['language'] = language
  tree = (ast.resolve-ast (parser.parse (syntax-for language), contents))
  tree.entities.map (x) ->
    (keys meta) |> each (key) -> do
                                 x.associate { key, value: meta[key] }
    x



### -- Exports ---------------------------------------------------------
module.exports = { parse }
