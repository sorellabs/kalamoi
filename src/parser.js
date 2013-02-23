(function(){
  var λ, boo, parseLine, commentLess, reTest, sanitiseRe, parse, baseSyntax, cSyntax;
  λ = require('prelude-ls');
  boo = require('boo');
  parseLine = curry$(function(syntax, line, index){
    var token;
    token = (function(){
      switch (syntax.test(line)) {
      case 'header':
        return syntax.parseHeader(line);
      case 'declaration':
        return syntax.parseDeclaration(line);
      case 'meta':
        return syntax.parseMeta(line);
      case 'signature':
        return syntax.parseSignature(line);
      case 'signature+':
        return syntax.parseSignatureContinuation(line);
      case 'text':
        return syntax.parseText(line);
      case 'code':
        return syntax.parseCode(line);
      default:
        return {
          kind: 'alien',
          text: line
        };
      }
    }());
    return import$({
      lineNo: index + 1
    }, token);
  });
  commentLess = curry$(function(f, line){
    var commentRe, depth;
    commentRe = new RegExp("^\\s*(" + sanitiseRe(this.comment) + "*)\\s?|\\s*#*$", 'g');
    depth = (line.match(commentRe) || [])[0];
    return f.call(this, line.replace(commentRe, ''), depth.length - 1);
  });
  reTest = curry$(function(x, re){
    return new RegExp(re).test(x);
  });
  sanitiseRe = function(x){
    return x.replace(/(\W)/g, '\\$1');
  };
  parse = curry$(function(syntax, code){
    var lines, tokens;
    lines = code.split(/\r\n|\r|\n/);
    return tokens = lines.map(parseLine(syntax));
  });
  baseSyntax = {
    comment: '#',
    parseHeader: commentLess(function(line, depth){
      var ref$, _, t1, t2;
      ref$ = line.match(/\s*=+([^=]+)=*|\s*-+([^\-]+)-*/), _ = ref$[0], t1 = ref$[1], t2 = ref$[2];
      return {
        kind: 'header',
        text: (t1 || t2).trim(),
        depth: depth
      };
    }),
    parseDeclaration: commentLess(function(line, depth){
      var ref$, _, type, name;
      ref$ = line.match(/\s*([^\s]+)\s*(.+)/), _ = ref$[0], type = ref$[1], name = ref$[2];
      return {
        kind: 'declaration',
        type: type.toLowerCase(),
        text: name.trim(),
        depth: depth
      };
    }),
    parseMeta: commentLess(function(line){
      var ref$, _, ks, value, keys;
      ref$ = line.match(/\s*:([^:]+):(.*)/), _ = ref$[0], ks = ref$[1], value = ref$[2];
      keys = λ.map(function(it){
        return it.trim();
      }, ks.split(','));
      value = value.trim() || true;
      return {
        kind: 'meta',
        keys: keys,
        value: value
      };
    }),
    parseSignature: commentLess(function(line){
      var ref$, _, signature;
      ref$ = line.match(/\s*::(.+)/), _ = ref$[0], signature = ref$[1];
      return {
        kind: 'signature',
        text: signature.trim()
      };
    }),
    parseSignatureContinuation: commentLess(function(line){
      var ref$, _, signature;
      ref$ = line.match(/\s*\.\.(.+)/), _ = ref$[0], signature = ref$[1];
      return {
        kind: 'signature+',
        text: signature.trim()
      };
    }),
    parseText: commentLess(function(line){
      return {
        kind: 'text',
        text: line
      };
    }),
    parseCode: function(line){
      return {
        kind: 'code',
        text: line
      };
    },
    test: function(line){
      var t;
      t = reTest(line);
      switch (false) {
      case !t("^\\s*" + sanitiseRe(this.comment) + "{2,}\\s*(=|-)+"):
        return 'header';
      case !t("^\\s*" + sanitiseRe(this.comment) + "{2,}\\s*\\S"):
        return 'declaration';
      case !t("^\\s*" + sanitiseRe(this.comment) + "\\s*:[^:]+:"):
        return 'meta';
      case !t("^\\s*" + sanitiseRe(this.comment) + "\\s*::"):
        return 'signature';
      case !t("^\\s*" + sanitiseRe(this.comment) + "\\s*\\.\\."):
        return 'signature+';
      case !t("^\\s*" + sanitiseRe(this.comment)):
        return 'text';
      default:
        return 'code';
      }
    }
  };
  cSyntax = boo.derive(baseSyntax, {
    comment: '//'
  });
  module.exports = {
    parse: parse,
    baseSyntax: baseSyntax,
    cSyntax: cSyntax
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
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
