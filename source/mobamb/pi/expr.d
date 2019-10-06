module mobamb.pi.expr;

private import metad.compiler;
private import metad.interp;

private import pegged.grammar;

private import mobamb.amb;

struct TypeConstParser(alias CAPS,ParseTree T) {
  mixin Compiler!(T,Parser);
  mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

  // parser macros
  template process(alias P) {
    enum process = processTypeConstant!P;
  }
  template action(alias A,alias P) {
    enum action = actionTypeConstant!(A,P);
  }
  template path(alias E,alias P) {
    enum path = pathTypeConstant!(E,P);
  }
  template name(alias D,alias N) {
    enum name = nameTypeConstant!(D,N);
  }
  template name(alias N) {
    enum name = nameTypeConstant!(N);
  }
  template domain(alias D) {
    enum domain = domainTypeConstant!(D);
  }
  template cap(const(string) C,alias P) {
    enum cap = capTypeConstant!(C,P);
  }
  template composition(alias C,alias P) {
    enum composition = compositionTypeConstant!(C,P);
  }
  template ambient(alias N,P...) {
    enum ambient = ambientTypeConstant!(N,P);
  }
}

struct typeConstantInterpreter(alias CAPS,ParseTree T) {
  TypeConstParser!(CAPS,T) parser;
  alias parser this;

  TypeConstant delegate(ParseTree)[string] nodes;

  this() {
    //nodes["GRAMMAR.Var"] = f=>idParser(f.children[1].matches);
    nodes["ProcessGrammar"] = f=>process!(typeConstantInterpreter(f.children[0]));
    nodes["ProcessGrammar.CapAction"] = (f)=>{
      if(f.children.length == 1) {
        return action!(typeConstantInterpreter(f.children[0]),voidTypeConstant);
      } else {
        return action!(typeConstantInterpreter(f.children[0]),typeConstantInterpreter(f.children[1]));
      }
    };
    nodes["ProcessGrammar.CapPath"] = f=>path!(typeConstantInterpreter(f.children[0]),typeConstantInterpreter(f.children[1]));
    nodes["ProcessGrammar.Name"] = (f)=> {
      if(p.children.length==0) return name!(f.matches[0]);
      else {
        return name!(f.matches[0],f.matches[1]);
      }
    };
    nodes["ProcessGrammar.Domain"] = (f)=>domain!(typeConstantInterpreter(f.children[0]));
  }
  enum interpret = Interpreter(nodes,T);
}

unittest {
  // Test the Interpreter

  //enum TEST_ {}
}

struct TypeConstantCompiler(alias CAPS,ParseTree T,
        alias Parser=TypeConstantCompiler) {
      TypeConstParser!(CAPS,T) parser;
      alias parser this;

      mixin (compilerOverride!("ProcessGrammar",
          "process!(compileNode(T.children[0]))"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 1)",
        "action!(compileNode(T.children[0]))"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 2)",
        "action!(compileNode(T.children[0]),compileNode(T.children[1]))"
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
      ));
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
