## Module ast-resolver #################################################
#
# Folds tokens into a full AST structure.
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


λ = require 'prelude-ls'
boo = require 'boo'


# type ASTState
# :: { "context" -> Entity
# .. , "contextStack" -> [Entity]
# .. , "ast" -> [Entity]
# .. }

# Constructs an error from a Error function, name and message
# :: Function -> String -> String -> Error
make-error = (constructor, name, message) -->
  e = constructor.call {}, message
  e.name = name
  e

# Constructs a syntax error
# :: String -> SyntaxError
make-syntax-error = make-error SyntaxError, 'SyntaxError'

# Occurs when a signature continuation appears without a previous signature
# :: Token -> Error
error-continuation-without-signature = (token) ->
  make-syntax-error "Signature continuation without previous signature.\n
                     #{token.text}"

# Occurs when we try to resolve a token we don't know the type
# :: Token -> Error
error-unknown-token = (token) ->
  make-error Error, 'UnknownTokenError'
           , "Don't know how to handle tokens of the type <#{token.kind}>"

# Occurs when data tokens happen outside of an entity context
# :: Token -> Error
error-missing-context = (token) ->
  make-error Error, 'MissingContextError'
           , "The following token needs an entity context: #{JSON.stringify token}"

# Asserts there's a context for data tokens
# :: (ASTState -> Token -> a) -> ASTState -> Token -> a
assert-context = (f, ast, token) -->
  if not ast.context => throw error-missing-context token
  f ast, token

# A map of declaration names to the kinds they represent
# :: { "String" -> "String" }
declaration-map =
  λ        : \function
  function : \function
  '{}'     : \object
  object   : \object
  data     : \data
  type     : \type
  module   : \module
  class    : \class
  
  
# Constructs a state for the AST resolver.
# :: [Entity] -> ASTState
make-ast-state = (tokens) ->
  context: null
  context-stack: []
  ast: tokens or []

# Pushes a context into the stack
# :: ASTState* -> Entity -> ASTState*
push-state = (ast, entity) -->
  if ast.context => ast.context-stack.push ast.context
  ast.context = entity
  ast

# Restores the context of an AST state
# :: ASTState* -> ASTState*
pop-state = (ast) ->
  ast.context = ast.context-stack.pop!
  ast

# Saves an entity in an AST
# :: ASTState* -> Entity -> ASTState*
save-entity = (ast, entity) -->
  | not ast.context                   => push-state ast, entity
  | ast.context.depth < entity.depth  => do
                                         ast.context.add entity
                                         push-state ast, entity
  | ast.context.depth >= entity.depth => do
                                         pop-state ast
                                         save-entity ast, entity

# Creates a new entity
# :: ASTState* -> Number -> Entity
make-entity = (ast, depth) -->
  entity = Entity.make { depth }
  save-entity ast, entity
  entity

# Creates a new header entity and saves it
# :: ASTState -> Token -> ASTState
make-header = (ast, token) -->
  entity = make-entity ast, token.depth
  entity.kind = \group
  entity.name = token.text
  ast

# Creates a new declaration entity and saves it
# :: ASTState -> Token -> ASTState
make-declaration = (ast, token) -->
  entity = make-entity ast, token.depth
  entity.kind = declaration-map[token.type]
  entity.name = token.text
  ast
  
# Associates meta information with the current entity
# :: ASTState -> Token -> ASTState
associate-meta = assert-context (ast, token) -->
  token.keys.map (key) -> ast.context.associate { key, value: token.value }
  ast

# Adds a signature to the current entity
# :: ASTState -> Token -> ASTState
push-signature = assert-context (ast, token) -->
  ast.context.signatures.push token.text
  ast

# Adds a signature continuation to the last signature in current entity
# :: ASTState -> Token -> ASTState
push-signature-continuation = assert-context (ast, token) -->
  if ast.context.signatures.length is 0 => throw (error-continuation-without-signature x)
  item = ast.context.signatures.pop!
  ast.context.signatures.push item + '\n' + token.text
  ast

# Adds a piece of text to the current entity
# :: ASTState -> Token -> ASTState
push-text = assert-context (ast, token) -->
  | ast.context.text => ast.context.text += "\n#{token.text}"
  | otherwise        => ast.context.text = token.text
  ast

# Adds a piece of code to the current entity
# :: ASTState -> Token -> ASTState
push-code = assert-context (ast, token) -->
  | ast.context.code => do
                        ast.context.code += "\n#{token.text}"
                        ast.context.end-line = token.line-no
  | otherwise        => do
                        ast.context.code = token.text
                        ast.context.line = token.line-no
  ast



# Folds tokens into a full AST.
# :: [Token] -> ASTState
resolve-ast = (xs) -> 
  console.log xs
  ast-folder (make-ast-state []), xs
  
# A folder for AST resolution
# :: ASTState -> [Token] -> ASTState
ast-folder = λ.fold (ast, token) ->
  | token.kind is \meta        => associate-meta ast, token
  | token.kind is \signature   => push-signature ast, token
  | token.kind is \signature+  => push-signature-continuation ast, token
  | token.kind is \text        => push-text ast, token
  | token.kind is \code        => push-code ast, token
  | token.kind is \declaration => make-declaration ast, token
  | token.kind is \header      => make-header ast, token
  | otherwise                  => throw (error-unknown-token token)


# Returns an object representing the author
# :: String -> Author
parse-author = (x) -> x

# Represents an Entity
# :: Base <| Entity
Entity = boo.Base.derive {
  init: (x) ->
    @id         = x.id
    @name       = x.name
    @kind       = x.kind
    @depth      = x.depth
    @signatures = []
    @text       = ''
    @code       = ''
    @meta       = {}
    @parent     = null
    @children   = []

    @language   = x.language
    @line       = null
    @end-line   = null
    @file       = x.file
    @copyright  = x.copyright
    @repository = x.repository
    @authors    = x.authors
    @licence    = x.licence

  add: (child) ->
    @children.push child
    child.parent = this

  associate: (meta) -> switch meta.key
    | \language   => @language   = meta.value
    | \file       => @file       = meta.value
    | \copyright  => @copyright  = meta.value
    | \repository => @repository = meta.value
    | \licence    => @licence    = meta.value
    | \author     => @authors.push (parse-author meta.value)
    | otherwise   => @meta[meta.key] = meta.value

  to-json: ->
    { id         : @id
    , name       : @name
    , kind       : @kind
    , signatures : @signatures
    , text       : @text
    , code       : @code
    , meta       : @meta
    , parent     : @parent?id
    , language   : @language
    , file       : @file
    , copyright  : @copyright
    , repository : @repository
    , authors    : @authors
    , licence    : @licence
    , line       : @line
    , "end-line" : @end-line or @line }

}



### -- Exports ---------------------------------------------------------
module.exports = { Entity, resolve-ast }
