(function(){
  var ast, parser, sanitisedName, languageFor, syntaxFor, parse;
  ast = require('./src/ast-resolver');
  parser = require('./src/parser');
  sanitisedName = function(it){
    return it.toLowerCase();
  };
  languageFor = function(extension){
    switch (sanitisedName(extension)) {
    case '.ls':
      return 'LiveScript';
    case '.coffee':
      return 'CoffeeScript';
    case '.js':
      return 'JavaScript';
    }
  };
  syntaxFor = function(language){
    switch (sanitisedName(language)) {
    case 'livescript':
      return parser.baseSyntax;
    case 'coffeescript':
      return parser.baseSyntax;
    case 'javascript':
      return parser.cSyntax;
    }
  };
  parse = curry$(function(extension, meta, contents){
    var language, tree;
    language = languageFor(extension);
    meta['language'] = language;
    tree = ast.resolveAst(parser.parse(syntaxFor(language), contents));
    return tree.entities.map(function(x){
      each(function(key){
        return x.associate({
          key: key,
          value: meta[key]
        });
      })(
      keys(meta));
      return x;
    });
  });
  module.exports = {
    parse: parse
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
