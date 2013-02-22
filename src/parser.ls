## Module parser #######################################################
#
# A parser for kalamoi metadata.
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



### -- Interfaces ------------------------------------------------------

#### Type Token
# Represents a line in a way the computer can understand, and adds some
# meta-data to it.
#
# :: { "kind" -> String, String -> String }


### Type TokenType
# Represents a type of token.
#
# :: String ( header
# ..        | declaration
# ..        | meta
# ..        | signature
# ..        | signature+
# ..        | text
# ..        | code
# ..        )



### -- Dependencies ----------------------------------------------------
λ   = require 'prelude-ls'
boo = require 'boo'




### -- Helpers ---------------------------------------------------------

#### λ parse-line
# Parses a single line of code, wrt the given syntax
#
# :: Syntax -> String -> Token
parse-line = (syntax, line, index) -->
  token = switch syntax.test line
  | \header      => syntax.parse-header line
  | \declaration => syntax.parse-declaration line
  | \meta        => syntax.parse-meta line
  | \signature   => syntax.parse-signature line
  | \signature+  => syntax.parse-signature-continuation line
  | \text        => syntax.parse-text line
  | \code        => syntax.parse-code line
  | otherwise    => { kind: \alien, text: line }
  (line-no: index + 1) <<< token


#### λ comment-less
# Strips comments from the beginning and end of a line
#
# :: (String, Number -> Token) -> String -> String
comment-less = (f, line) -->
  comment-re = new RegExp "^\\s*(#{sanitise-re @comment}*)\\s?|\\s*#*$", 'g'
  [ depth ] = (line.match comment-re) or []
  f.call this, (line.replace comment-re, ''), depth.length - 1
  

#### λ re-test
# Tests some regular expression
#
# :: String -> String -> Bool
re-test = (x, re) -->
  (new RegExp re).test x


#### λ sanitise-re
# Sanitises a regular expression.
#
# :: String -> String
sanitise-re = (x) ->
  x.replace /(\W)/g, '\\$1'



### -- Core implementation ---------------------------------------------

#### λ parse
# Parses a whole file.
#
# :: Syntax -> String -> [Token]
parse = (syntax, code) -->
  lines = code.split /\r\n|\r|\n/
  tokens = lines.map (parse-line syntax)


#### {} baseSyntax
# Base syntax object. Can be derived for extensibility.
#
# :: Object <| base-syntax
base-syntax = {

  ##### Data comment
  # Comment characters.
  #
  # :: String
  comment: '#'


  ##### λ parse-header
  # Parses a header line.
  #
  # :: String -> Token
  parse-header: comment-less (line, depth) ->
    [ _, t1, t2 ] = line.match /\s*=+([^=]+)=*|\s*-+([^\-]+)-*/
    { kind: \header, text: (t1 or t2).trim!, depth }


  ##### λ parse-declaration
  # Parses a declaration line
  #
  # :: String -> Token
  parse-declaration: comment-less (line, depth) ->
    [ _, type, name ] = line.match /\s*([^\s]+)\s*(.+)/
    { kind: \declaration, type: type.to-lower-case!, text: name.trim!, depth }


  ##### λ parse-meta
  # Parses a meta-declaration line.
  #
  # :: String -> Token
  parse-meta: comment-less (line) ->
    [ _, ks, value ] = line.match /\s*:([^:]+):(.*)/
    keys  = λ.map (.trim!), (ks.split ',')
    value = value.trim! or true
    { kind: \meta, keys: keys, value: value }


  ##### λ parse-signature
  # Parses a signature line.
  #
  # :: String -> Token
  parse-signature: comment-less (line) ->
    [ _, signature ] = line.match /\s*::(.+)/
    { kind: \signature, text: signature.trim! }


  ##### λ parse-signature-continuation
  # Parses a signature continuation line.
  #
  # :: String -> Token
  parse-signature-continuation: comment-less (line) ->
    [ _, signature ] = line.match /\s*\.\.(.+)/
    { kind: \signature+, text: signature.trim! }


  ##### λ parse-text
  # Parses a piece of text.
  #
  # :: String -> Token
  parse-text: comment-less (line) ->
    { kind: \text, text: line }


  ##### λ parse-code
  # Parses a piece of code.
  #
  # :: String -> Token
  parse-code: (line) ->
    { kind: \code, text: line }


  ##### λ test
  # Tests a line and determine its type.
  #
  # :: String -> TokenType
  test: (line) ->
    t = re-test line
    switch
    | t "^\\s*#{sanitise-re @comment}{2,}\\s*(=|-)+" => \header
    | t "^\\s*#{sanitise-re @comment}{2,}\\s*\\S"    => \declaration
    | t "^\\s*#{sanitise-re @comment}\\s*:[^:]+:"    => \meta
    | t "^\\s*#{sanitise-re @comment}\\s*::"         => \signature
    | t "^\\s*#{sanitise-re @comment}\\s*\\.\\."     => \signature+
    | t "^\\s*#{sanitise-re @comment}"               => \text
    | otherwise                                      => \code
}
  


### -- Exports ---------------------------------------------------------
module.exports = { parse, base-syntax }
