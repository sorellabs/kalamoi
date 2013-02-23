(function(){
  var λ, boo, makeError, makeSyntaxError, errorContinuationWithoutSignature, errorUnknownToken, errorMissingContext, assertContext, declarationMap, makeAstState, pushState, popState, saveEntity, makeEntity, makeHeader, makeDeclaration, associateMeta, pushSignature, pushSignatureContinuation, pushText, pushCode, resolveAst, astFolder, parseAuthor, kindPrefix, sanitisedIdFor, joinId, Entity;
  λ = require('prelude-ls');
  boo = require('boo');
  makeError = curry$(function(constructor, name, message){
    var e;
    e = constructor.call({}, message);
    e.name = name;
    return e;
  });
  makeSyntaxError = makeError(SyntaxError, 'SyntaxError');
  errorContinuationWithoutSignature = function(token){
    return makeSyntaxError("Signature continuation without previous signature.\n" + token.text);
  };
  errorUnknownToken = function(token){
    return makeError(Error, 'UnknownTokenError', "Don't know how to handle tokens of the type <" + token.kind + ">");
  };
  errorMissingContext = function(token){
    return makeError(Error, 'MissingContextError', "The following token needs an entity context: " + JSON.stringify(token));
  };
  assertContext = curry$(function(f, ast, token){
    if (!ast.context) {
      throw errorMissingContext(token);
    }
    return f(ast, token);
  });
  declarationMap = {
    λ: 'function',
    'function': 'function',
    '{}': 'object',
    object: 'object',
    data: 'data',
    type: 'type',
    module: 'module',
    'class': 'class'
  };
  makeAstState = function(tokens){
    return {
      context: null,
      contextStack: [],
      entities: tokens || []
    };
  };
  pushState = curry$(function(ast, entity){
    if (ast.context) {
      ast.contextStack.push(ast.context);
    }
    ast.context = entity;
    return ast;
  });
  popState = function(ast){
    ast.context = ast.contextStack.pop();
    return ast;
  };
  saveEntity = curry$(function(ast, entity){
    switch (false) {
    case !!ast.context:
      return pushState(ast, entity);
    case !(ast.context.depth < entity.depth):
      ast.context.add(entity);
      return pushState(ast, entity);
    case !(ast.context.depth >= entity.depth):
      popState(ast);
      return saveEntity(ast, entity);
    }
  });
  makeEntity = curry$(function(ast, depth){
    var entity;
    entity = Entity.make({
      depth: depth
    });
    saveEntity(ast, entity);
    ast.entities.push(entity);
    return entity;
  });
  makeHeader = curry$(function(ast, token){
    var entity;
    entity = makeEntity(ast, token.depth);
    entity.kind = 'group';
    entity.name = token.text;
    return ast;
  });
  makeDeclaration = curry$(function(ast, token){
    var entity;
    entity = makeEntity(ast, token.depth);
    entity.kind = declarationMap[token.type];
    entity.name = token.text;
    return ast;
  });
  associateMeta = assertContext(curry$(function(ast, token){
    token.keys.map(function(key){
      return ast.context.associate({
        key: key,
        value: token.value
      });
    });
    return ast;
  }));
  pushSignature = assertContext(curry$(function(ast, token){
    ast.context.signatures.push(token.text);
    return ast;
  }));
  pushSignatureContinuation = assertContext(curry$(function(ast, token){
    var item;
    if (ast.context.signatures.length === 0) {
      throw errorContinuationWithoutSignature(x);
    }
    item = ast.context.signatures.pop();
    ast.context.signatures.push(item + '\n' + token.text);
    return ast;
  }));
  pushText = assertContext(curry$(function(ast, token){
    switch (false) {
    case !ast.context.text:
      ast.context.text += "\n" + token.text;
      break;
    default:
      ast.context.text = token.text;
    }
    return ast;
  }));
  pushCode = assertContext(curry$(function(ast, token){
    switch (false) {
    case !ast.context.code:
      ast.context.code += "\n" + token.text;
      ast.context.endLine = token.lineNo;
      break;
    default:
      ast.context.code = token.text;
      ast.context.line = token.lineNo;
    }
    return ast;
  }));
  resolveAst = function(xs){
    return astFolder(makeAstState([]), xs);
  };
  astFolder = λ.fold(function(ast, token){
    switch (false) {
    case token.kind !== 'meta':
      return associateMeta(ast, token);
    case token.kind !== 'signature':
      return pushSignature(ast, token);
    case token.kind !== 'signature+':
      return pushSignatureContinuation(ast, token);
    case token.kind !== 'text':
      return pushText(ast, token);
    case token.kind !== 'code':
      return pushCode(ast, token);
    case token.kind !== 'declaration':
      return makeDeclaration(ast, token);
    case token.kind !== 'header':
      return makeHeader(ast, token);
    default:
      throw errorUnknownToken(token);
    }
  });
  parseAuthor = function(x){
    return x;
  };
  kindPrefix = function(entity){
    switch (entity.kind) {
    case 'type':
      return 't:';
    case 'class':
      return 'c:';
    case 'group':
      return 'g:';
    default:
      return '';
    }
  };
  sanitisedIdFor = function(entity){
    return kindPrefix(entity) + "" + entity.name.trim().replace(/\s+/g, '-');
  };
  joinId = curry$(function(x, y){
    switch (false) {
    case !x:
      return x + "/" + y;
    default:
      return y;
    }
  });
  Entity = boo.Base.derive({
    init: function(x){
      this.id = x.id;
      this.name = x.name;
      this.kind = x.kind;
      this.depth = x.depth;
      this.signatures = [];
      this.text = '';
      this.code = '';
      this.meta = {};
      this.parent = null;
      this.children = [];
      this.language = x.language;
      this.line = null;
      this.endLine = null;
      this.file = x.file;
      this.copyright = x.copyright;
      this.repository = x.repository;
      this.authors = x.authors;
      return this.licence = x.licence;
    },
    makeId: function(){
      var ref$;
      switch (false) {
      case !this.id:
        return this.id;
      default:
        return joinId((ref$ = this.parent) != null ? ref$.makeId() : void 8, sanitisedIdFor(this));
      }
    },
    add: function(child){
      this.children.push(child);
      return child.parent = this;
    },
    associate: function(meta){
      switch (meta.key) {
      case 'language':
        return this.language = meta.value;
      case 'file':
        return this.file = meta.value;
      case 'copyright':
        return this.copyright = meta.value;
      case 'repository':
        return this.repository = meta.value;
      case 'licence':
        return this.licence = meta.value;
      case 'author':
        return this.authors.push(parseAuthor(meta.value));
      default:
        return this.meta[meta.key] = meta.value;
      }
    },
    toJson: function(){
      var ref$;
      return {
        id: this.makeId(),
        name: this.name,
        kind: this.kind,
        signatures: this.signatures,
        text: this.text,
        code: this.code,
        meta: this.meta,
        parent: (ref$ = this.parent) != null ? ref$.makeId() : void 8,
        language: this.language,
        file: this.file,
        copyright: this.copyright,
        repository: this.repository,
        authors: this.authors,
        licence: this.licence,
        line: this.line,
        "end-line": this.endLine || this.line
      };
    }
  });
  module.exports = {
    Entity: Entity,
    resolveAst: resolveAst
  };
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
}).call(this);
