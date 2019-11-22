module mobamb.pi.expr;

private import metad.compiler;
private import metad.interp;

private import pegged.grammar;

private import mobamb.amb;
private import mobamb.pi.constant;

private import std.experimental.logger;

struct TypeConstParser {
  // parser macros
  template process(alias P) {
    enum process = processTypeConstant!(P);
  }
  auto process(TypeConstant p) {
    return processTypeConstant(p);
  }
  template action(alias A,alias P) {
    enum action = actionTypeConstant!(A,P);
  }
  auto action(TypeConstant a,TypeConstant p) {
    assert(cast(CapTypeConstant)a !is null);
    assert(cast(ProcessTypeConstant)p !is null);
    return actionTypeConstant(cast(CapTypeConstant)a,cast(ProcessTypeConstant)p);
  }
  template action(alias A) {
    enum action = actionTypeConstant!(A);
  }
  auto action(TypeConstant a) {
    assert(cast(CapTypeConstant)a !is null);
    return actionTypeConstant(cast(CapTypeConstant)a);
  }
  template path(alias E,alias P) {
    enum path = pathTypeConstant!(E,P);
  }
  auto path(TypeConstant e,TypeConstant p) {
    assert(cast(ProcessTypeConstant)p !is null);
    return pathTypeConstant(e,cast(ProcessTypeConstant)p);
  }
  template name(alias D,alias N) {
    enum name = nameTypeConstant!(D,N);
  }
  auto name(const(string) d,TypeConstant n) {
    return new NameTypeConstant(d,n);
  }
  template name(alias TypeConstant N) {
    enum name = nameTypeConstant!(N);
  }
  auto name(TypeConstant n) {
    return new NameTypeConstant(n);
  }
  template name(alias TypeConstant D,alias TypeConstant N) {
    enum name = nameTypeConstant!(N);
  }
  auto name(TypeConstant d,TypeConstant n) {
    return new NameTypeConstant(d,n);
  }
  template domain(const(string) D) {
    enum domain = domainTypeConstant!(D);
  }
  auto domain(const(string) d) {
    return stringRefTypeConstant(d);
  }
  /* template domain(TypeConstant D) {
    enum domain = stringRefTypeConstant!(D);
  }
  auto domain(TypeConstant d) {
    return stringRefTypeConstant(d);
  }*/
  template cap(const(string) C,alias TypeConstant P) {
    enum cap = capTypeConstant!(C,P);
  }
  template composition(alias TypeConstant C,alias TypeConstant P) {
    enum composition = compositionTypeConstant!(C,P);
  }
  template ambient(alias N,P...) {
    enum ambient = ambientTypeConstant!(N,P);
  }
}

class TypeConstantInterpreter(alias CAPS) {
  static TypeConstant delegate(ParseTree)[string] nodes;
  static const(string) delegate(ParseTree)[string] strNodes;
  TypeConstParser parser;
  alias parser this;

  this() {
    //nodes["GRAMMAR.Var"] = f=>idParser(f.children[1].matches);
    nodes["ProcessGrammar"] = f=>parser.process(interpret!TypeConstant(f.children[0]));

    nodes["ProcessGrammar.CapAction"] = f=>
      (f.children.length == 1) ? parser.action(interpret!TypeConstant(f.children[0]))
      : parser.action(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));

    nodes["ProcessGrammar.CapPath"] = f=>parser.path(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));

    nodes["ProcessGrammar.Name"] = f=>
      (f.children.length == 1) ? parser.name(interpret!TypeConstant(f.children[0]))
      : parser.name(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));

    //nodes["ProcessGrammar.Domain"] = (f)=>parser.domain(interpret!TypeConstant(f.children[0]));
  }
  static auto interpret(alias T)(ParseTree data)
    if (is(T == TypeConstant)) {
    return Interpreter!(T,typeof(nodes))(nodes,data).front;
  }
  static auto interpret(alias T)(ParseTree data)
    if (is(T == const(string))) {
    return Interpreter!(T,typeof(strNodes))(strNodes,data).front;
  }
}

/* unittest {
  // Test the Interpreter

  sharedLog.info("AMB Expression interpreter tests");
  enum EXPR = "A[]";
  enum CAPS = "('in' / 'out')";

  enum ProcessGrammarFilename = "process.peg";
  mixin(grammar(import (ProcessGrammarFilename)));
  mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

  enum parser = ProcessGrammar!(_CapType)(EXPR);
  auto i = TypeConstantInterpreter!(_CapType);
  auto interp = i.interpret!(TypeConstant)(parser);

  //enum expr = parser.compile!
  //auto compiler = TypeConstantCompiler(CAPS,ParseTree T);
  //enum comp = TypeConstantInterpreter(_CapType,parser).compileNode;

  assert(is(typeof(interp) == ProcessTypeConstant));
  assert(is(typeof(interp) == AmbientTypeConstant));
  assert(interp._name == "A");

}
 */
//struct TypeConstantCompiler(ParseTree T,
//        alias Parser=TypeConstantCompiler!T) {
struct TypeConstantCompiler(ParseTree T) {

      TypeConstParser parser;
      alias parser this;

      mixin Compiler!(T,TypeConstantCompiler!T);

      mixin (compilerOverride!("ProcessGrammar",
          "parser.process!(TypeConstantCompiler!(T.children[0]).compile())"
      ));
      /*mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 1)",
        "TypeConstParser.action!(Parser!(T.children[0]).compileNode())"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 2)",
        "TypeConstParser.action!(Parser!(T.children[0]).compileNode,Parser!(T.children[1]).compileNode)"
      ));
      mixin (compilerOverride!("ProcessGrammar.CapPath",
        "path!(compileNode(T.children[0]),comppileNode(T.children[1]))"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Name\") && (T.children.length == 1)",
        "name!(compileNode(T.matches[0]))"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Name\") && (T.children.length == 2)",
        "name!(compileNode(T.children[0]),compileNode(T.children[1]))"
      ));
      mixin (compilerOverride!("ProcessGrammar.Domain",
          "domain!(T.matches[0])"
      ));
      mixin (compilerOverride!("ProcessGrammar.CapEntry",
          "cap!(T.matches[0],compileNode(T.children[0]))"
      ));
      mixin (compilerOverride!("ProcessGrammar.Composition",
          "composition!(compileNode(T.children[0]),compileNode(T.children[1]))"
      ));*/
      /* mixin (nodeOverride!("(T.name == \"ProcessGrammar.Ambient\") && (T.children.length == 1)",
        "ambient!(compileNode(T.children[0]))"
      )); */

}



/*
class TypeConstantCompiler(alias CT) : IParser!TypeConstant {
    enum ProcessGrammarFilename = "grammar/process.peg";
    mixin(grammar(import (ProcessGrammarFilename)));
    //mixin(grammar("_CapType : CapType <- " ~ CT)));
    //    pragma(msg,grammar("_CapType : CapPattern <- " ~ CT));
    mixin(grammar("_CapType : CapPattern <- " ~ CT));

    static TypeConstant parse(const(string) expr)() {
        return compileCode!(ProcessGrammar!(_CapType.CapPattern)(expr))();
    }
    static auto parseFile(const(string)fname)() {
        return parse(import(fname));
    }

    static auto generateCode(alias expr)() {
        return generateCode(ProcessGrammar!(_CapType.CapPattern)(expr));
    }
    template compileCode(alias expr) {
        enum compileCode = mixin(generateCode!expr());
    }
    static const(string) generateCode(ParseTree p) {
        import pegged.tohtml;
        string result = "";
        switch(p.name) {
            case "ProcessGrammar":
                result ~= "process!(" ~ generateCode(p.children[0]) ~ ");";
                toHTML(p.children[0],"process.html");
                break;
            case "ProcessGrammar.CapAction":
                if(p.children.length == 1) result ~= generateCode(p.children[0]);
                else {
                    result ~= "action!(" ~ generateCode(p.children[0]) ~ "," ~ generateCode(p.children[1])  ~ ")";
                }
                break;
            case "ProcessGrammar.CapPath":
                result ~= "path!(" ~ generateCode(p.children[0]) ~ "," ~ generateCode(p.children[1])  ~ ")";
                break;
            case "ProcessGrammar.Name":
                if(p.children.length==0)result ~= "name!\"" ~ p.matches[0] ~ "\"";
                else {
                    result ~= "name!("~ generateCode(p.children[0]) ~"\"" ~ p.matches[0] ~ "\")";
                }
                break;
            case "ProcessGrammar.Domain":
                result ~= "domain!\"" ~ p.matches[0] ~ "\"";
                break;
            case "ProcessGrammar.CapEntry":
                result ~= "cap!(\"" ~ p.matches[0] ~ "\"," ~ generateCode(p.children[0]) ~ ")";
                break;
            case "ProcessGrammar.Composition":
                result ~= "composition!(" ~ generateCode(p.children[0]) ~ "," ~ generateCode(p.children[1]) ~ ")";
                break;
            case "ProcessGrammar.Ambient":
                result ~= "ambient!";
                if(p.children.length == 1) result ~= generateCode(p.children[0]);
                else {
                    result ~= "(" ~ generateCode(p.children[0]) ~ "," ~ generateCode(p.children[1]) ~ ")";
                }
                break;
            case "ProcessGrammar.CapName":
            case "ProcessGrammar.Capability":
            case "ProcessGrammar.ComposedProcess":
            case "ProcessGrammar.BoundProcess":
            case "ProcessGrammar.RestrictedProcess":
            case "ProcessGrammar.InputProcess":
            case "ProcessGrammar.NestedProcess":
            case "ProcessGrammar.OutputProcess":
            case "ProcessGrammar.AmbientProcess":
            case "ProcessGrammar.Process":
                if(p.children.length > 0) result ~= generateCode(p.children[0]);
                goto default;
            default:
                break;
        }
        return result;
    }
*/
/*
unittest {
  sharedLog.info("Expression compiler tests");
  enum EXPR = "A[]";
  enum CAPS = "('in' / 'out')";

  enum ProcessGrammarFilename = "process.peg";
  mixin(grammar(import (ProcessGrammarFilename)));
  mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

  enum parser = ProcessGrammar!(_CapType)(EXPR);
  //enum expr = parser.compile!
  //auto compiler = TypeConstantCompiler(CAPS,ParseTree T);
  enum comp = TypeConstantCompiler!(parser).compileNode;
  enum compiled = mixin(comp);
  //enum compiled = TypeConstantCompiler!(parser).compile;

  assert(is(typeof(compiled) == ProcessTypeConstant));
  assert(is(typeof(compiled) == AmbientTypeConstant));
  assert(compiled._name == "A");
}
*/
