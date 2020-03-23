module mobamb.pi.expr;

private import metad.compiler;
private import metad.interp;

private import pegged.grammar;

private import mobamb.amb;
private import mobamb.pi.constant;

private import std.variant;
private import std.algorithm;
private import std.experimental.logger;
private import std.exception;
private import std.typecons;

struct TypeConstParser {
  // parser macros
  template process(alias P) {
    //enum process = processTypeConstant!(P);
	auto process = tuple!("process")(P);
  }
  auto process(TypeConstant p) {
    return processTypeConstant(p);
  }
  template voidType() {
	alias voidType = voidTypeConstant;
  }
  template errorType() {
	alias errorType = errorTypeConstant;
  }
  //template action(alias A,alias P) {
  //  enum action = actionTypeConstant!(A,P);
  //}
  auto action(TypeConstant a,TypeConstant p) {
    enforce(cast(CapTypeConstant)a !is null);
    enforce(cast(ProcessTypeConstant)p !is null);
    return actionTypeConstant(cast(CapTypeConstant)a,cast(ProcessTypeConstant)p);
  }
  //template action(alias CapTypeConstant A) {
  //  enum action = mobamb.pi.constant.actionTypeConstant!(A);
  //}
  auto action(alias A)() {
    return tuple!("action")(A);
  }
  auto action(alias A,alias P)() {
    return tuple!("action","process")(A,P);
  }
  auto action(TypeConstant a) {
    enforce(cast(CapTypeConstant)a !is null);
    return actionTypeConstant(cast(CapTypeConstant)a);
  }
  template path(alias E,alias P) {
    enum path = pathTypeConstant!(E,P);
  }
  auto path(TypeConstant e,TypeConstant p) {
    enforce(cast(ProcessTypeConstant)p !is null);
    return pathTypeConstant(e,cast(ProcessTypeConstant)p);
  }
  template name(const(string)D,const(string)N) {
    //auto name = nameTypeConstant!(D,N);
	enum name = tuple!("domain","name")(D,N);
  }
  template name(alias TypeConstant N) {
    enum name = nameTypeConstant!(N);
  }
  template name(const(string) N) {
    //enum name = mobamb.pi.constant.nameTypeConstant!(N);
	enum name = tuple!("name")(N);
  }
  auto name(TypeConstant n) {
    return nameTypeConstant(n);
  }
  auto name(const(string)n) {
    return nameTypeConstant(n);
  }
  auto name(const(string)d,const(string)n) {
    return nameTypeConstant(d,n);
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
  /*template domain(TypeConstant D) {
    enum domain = stringRefTypeConstant!(D);
  }
  auto domain(TypeConstant d) {
    return stringRefTypeConstant(d);
  }*/
  template capability(const(string) C,alias TypeConstant P) {
    enum capability = capTypeConstant!(C,P);
  }
  auto capability(const(string)cap,NameTypeConstant c,TypeConstant p=voidTypeConstant) {
    return capTypeConstant(cap,c,p);
  }
  template composition(alias TypeConstant C,alias TypeConstant P) {
    enum composition = compositionTypeConstant!(C,P);
  }
  auto composition(TypeConstant c,TypeConstant p) {
	return compositionTypeConstant(c,p);
  }
  template ambient(alias NameTypeConstant N,alias TypeConstant[] P) {
    enum ambient = ambientTypeConstant!(N,P);
  }
  template ambient(alias NameTypeConstant N) {
    enum ambient = ambientTypeConstant!(N);
  }
  auto ambient(NameTypeConstant n) {
    return ambientTypeConstant(n);
  }
  auto ambient(NameTypeConstant n,TypeConstant[] p) {
    return ambientTypeConstant(n,p);
  }
  auto ident(const(string) id) {
	return symRefTypeConstant!string(id);
  }
}

class TypeConstantInterpreter(alias CAPS) {
  //static TypeConstant delegate(ParseTree)[string] nodes;
  Variant delegate(ParseTree)[string] nodes;
	//static const(string) delegate(ParseTree)[string] strNodes;
  TypeConstParser parser;
  alias parser this;
  
  auto voidType(ParseTree f) {
	auto n = parser.voidType();
	n.parseTree = f;
	return n;
  }
  auto errorType(ParseTree f) {
	auto n = parser.errorType();
	n.parseTree = f;
	return n;
  }
  auto name(ParseTree f) {
	/*if(f.matches.length == 0 || f.matches.length > 2) {
		return errorType(f);
	}*/
	auto n = (f.matches.length == 1) ? parser.name(f.matches[0])
		: parser.name(f.matches[0],f.matches[1]);
	n.parseTree = f;
	return n;
  }
  auto domain(ParseTree f) {
	/*if(f.matches.length == 0 || f.matches.length > 1) {
		//return errorType(f);
	}*/
    auto n = parser.domain(f.matches[0]);
	n.parseTree = f;
	return n;
  }
  TypeConstant action(ParseTree f) {
	if(f.children.length == 0 || f.children.length > 2) {
		return voidType(f);
	}
	auto n = (f.children.length == 1) ? parser.action(interpret!TypeConstant(f.children[0]))
		: parser.action(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));
	n.parseTree = f;
	return n;
  }
  TypeConstant path(ParseTree f) {
	if(f.children.length != 2) {
		return voidType(f);
	}
	auto n = parser.path(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));
	n.parseTree = f;
	return n;
  }
  TypeConstant composition(ParseTree f) {
	if(f.children.length != 2) {
		return voidType(f);
	}
	auto n = parser.composition(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]));
	n.parseTree = f;
	return n;
  }
  auto ambient(ParseTree f) {
	/*if(f.children.length == 0) {
		return voidType(f);
	}*/
	auto amb = (f.children.length == 1) ? 
		parser.ambient(cast(NameTypeConstant)interpret!TypeConstant(f.children[0]))
		: parser.ambient(cast(NameTypeConstant)interpret!TypeConstant(f.children[0]),f.children[1..$].map!(x=>interpret!TypeConstant(x)).array);
	amb.parseTree = f;
	return amb;
  }
  TypeConstant capability(ParseTree f) {
	//auto n = parser.capability(interp!TypeConstant(f.children[0]),interp!TypeConstant(f.children[0]));
	/*auto cap = (f.children.length == 1) ? 
			parser.capability(f.matches[0],cast(NameTypeConstant)interpret!TypeConstant(f.children[0]))
		: parser.capability(f.matches[0],cast(NameTypeConstant)interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]))
	;*/
	TypeConstant cap;
	if(f.matches.length == 0) {
		cap = (f.children.length == 1) ? 
			parser.capability("name",cast(NameTypeConstant)interpret!TypeConstant(f.children[0]))
			: parser.capability("name",cast(NameTypeConstant)interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]))
			;
	} else {
		cap = (f.children.length == 1) ? 
			parser.capability(f.matches[0],cast(NameTypeConstant)interpret!TypeConstant(f.children[0]))
			: parser.capability(f.matches[0],cast(NameTypeConstant)interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1]))
			;
	}
	cap.parseTree = f;
	return cap;
	//return voidType(f);
  }

  this() {
    //nodes["GRAMMAR.Var"] = f=>idParser(f.children[1].matches);
    //nodes["ProcessGrammar"] = f=>Variant(parser.process(interpret!TypeConstant(f.children[0])));

    /*nodes["ProcessGrammar.CapAction"] = f=>
      (f.children.length == 1) ? Variant(parser.action(interpret!TypeConstant(f.children[0])))
      : Variant(parser.action(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1])));*/
	nodes["ProcessGrammar.CapAction"] = f=>Variant(action(f));
    //nodes["ProcessGrammar.CapPath"] = f=>Variant(parser.path(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1])));
	nodes["ProcessGrammar.CapPath"] = f=>Variant(path(f));
	nodes["ProcessGrammar.Capability"] = f=>Variant(capability(f));
/*    nodes["ProcessGrammar.Name"] = f=>
      //(f.children.length == 1) ? Variant(parser.name(f.matches[0]))
      //: Variant(parser.name(interpret!TypeConstant(f.children[0]),interpret!TypeConstant(f.children[1])));
		(f.matches.length == 1) ? Variant(parser.name(f.matches[0]))
		: Variant(parser.name(f.matches[0],f.matches[1]));
*/
	/*nodes["ProcessGrammar.Name"] = delegate Variant(f) {
		//debug(Expressions) {
			sharedLog.info("ProcessGrammar.Name ",f);
		//}

		return (f.matches.length == 1) ? Variant(parser.name(f.matches[0]))
		: Variant(parser.name(f.matches[0],f.matches[1]));
	};*/
	nodes["ProcessGrammar.Name"] = f=>Variant(name(f));
    nodes["ProcessGrammar.Domain"] = f=>Variant(domain(f));

    //nodes["ProcessGrammar.Domain"] = (f)=>parser.domain(interpret!TypeConstant(f.children[0]));
    /*nodes["ProcessGrammar.Ambient"] = f=> (f.children.length == 1) ? 
		Variant(parser.ambient(interpret!NameTypeConstant(f.children[0])))
		: Variant(parser.ambient(interpret!NameTypeConstant(f.children[0]),f.children[1..$].map!(x=>interpret!TypeConstant(x)).array));
	*/
	nodes["ProcessGrammar.Ambient"] = f=>Variant(ambient(f));
/*    nodes["ProcessGrammar.Ambient"] = delegate Variant(f) {
		//debug(Expressions) {
			sharedLog.info("ProcessGrammar.Ambient ",f);
		//}
		return (f.children.length == 1) ? 
			Variant(parser.ambient(interpret!NameTypeConstant(f.children[0])))
			: Variant(parser.ambient(interpret!NameTypeConstant(f.children[0]),f.children[1..$].map!(x=>interpret!TypeConstant(x)).array));
	};*/
	//nodes["ProcessGrammar.CapEntry"] = f=>Variant(capability(f));
	nodes["ProcessGrammar.Composition"] = f=>Variant(composition(f));

  }
  /*static auto interpret(alias T)(ParseTree data)
    if (is(T == TypeConstant)) {
    return Interpreter!(T)(nodes,data).front;
  }*/
  /*static auto interpret(alias T)(ParseTree data)
    if (is(T == const(string))) {
    return Interpreter!(T)(strNodes,data).front;
  }*/
  T interpret(alias T)(ParseTree data) {
	debug(Expressions) {
		sharedLog.info("interpret ",data);
	}
	return Interpreter(nodes,data).front.get!T;
  }
  T[] interpretArray(alias T)(ParseTree data) {
	debug(Expressions) {
		sharedLog.info("interpretArray ",data);
	}
	return Interpreter(nodes,data).map!(x=>x.get!T).array;
  }
}

unittest {
	enum EXPR = "P";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	auto i = new TypeConstantInterpreter!(_CapType);
	auto interp = i.interpret!(TypeConstant)(parser);
	//sharedLog.info("interp is: ",typeid(interp));
	auto act = cast(ActionTypeConstant)interp;
	assert(act !is null);
	auto cap = act._cap;
	assert(cap !is null);
	auto name = cast(SymRefTypeConstant!string)cap._name._name;
	assert(name !is null);
	assert(name.symRef == "P");
}

unittest {
	enum EXPR = "P|Q";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	auto i = new TypeConstantInterpreter!(_CapType);
	auto interp = cast(CompositionTypeConstant)i.interpret!(TypeConstant)(parser);
	assert(interp !is null);
	//auto comp = cast(NameTypeConstant)interp._composed;
	auto comp = cast(ActionTypeConstant)interp._composed;
	assert(comp !is null);
	//auto name = cast(SymRefTypeConstant!string)comp._name;
	//assert(name !is null);
	//assert(name.symRef == "P");
	auto proc = cast(ActionTypeConstant)interp._process;
	assert(proc !is null);
}

unittest {
  enum EXPR = "A[]";
  sharedLog.info("AMB Expression interpreter tests:",EXPR);
  enum CAPS = "('in' / 'out' / 'open')";

  enum ProcessGrammarFilename = "process.peg";
  mixin(grammar(import (ProcessGrammarFilename)));
  mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

  enum parser = ProcessGrammar!(_CapType)(EXPR);
  auto i = new TypeConstantInterpreter!(_CapType);
  auto interp = cast(AmbientTypeConstant)i.interpret!(TypeConstant)(parser);
  assert(interp !is null);

  auto name = cast(SymRefTypeConstant!string)interp._name._name;
  assert(name.symRef == "A");

}

unittest {
	enum EXPR = "A[]|B[]";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	auto i = new TypeConstantInterpreter!(_CapType);
	//auto interp = i.interpretArray!(TypeConstant)(parser).map!(x=>cast(AmbientTypeConstant)x).array;
	auto interp = cast(CompositionTypeConstant)i.interpret!TypeConstant(parser);
	
	/*assert(interp.length = 2);
	auto name0 = (cast(SymRefTypeConstant!string)interp[0]._name._name).symRef;
	auto name1 = (cast(SymRefTypeConstant!string)interp[1]._name._name).symRef;
	assert(name0 == "A");
	assert(name1 == "B");*/

	sharedLog.info("Done AMB Expression interpreter tests:",EXPR);

}
unittest {
	enum EXPR = "A[in B]|B[]";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	auto i = new TypeConstantInterpreter!(_CapType);
	auto interp = i.interpret!(TypeConstant)(parser);
	/*auto interp = i.interpretArray!(TypeConstant)(parser).map!(x=>cast(AmbientTypeConstant)x).array;

	assert(interp.length = 2);
	auto name0 = (cast(SymRefTypeConstant!string)interp[0]._name._name).symRef;
	auto name1 = (cast(SymRefTypeConstant!string)interp[1]._name._name).symRef;
	assert(name0 == "A");
	assert(name1 == "B");*/

	sharedLog.info("Done AMB Expression interpreter tests ",EXPR);
}


//struct TypeConstantCompiler(ParseTree T,
//        alias Parser=TypeConstantCompiler!T) {
struct TypeConstantCompiler(ParseTree T) {

      TypeConstParser parser;
      alias parser this;

      mixin Compiler!(T,TypeConstantCompiler!T);

      mixin (compilerOverride!("ProcessGrammar",
          "\"TypeConstParser.process!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\")\""
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 1)",
        "return \"TypeConstParser.action!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\")\""
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.CapAction\") && (T.children.length == 2)",
        "return \"TypeConstParser.action!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\",\"~TypeConstantCompiler!(T.children[1]).compileNode~\")\""
      ));
      mixin (compilerOverride!("ProcessGrammar.CapPath",
        "\"TypeConstParser.path!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\",\"~TypeConstantCompiler!(T.children[1]).compileNode~\")\""
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Name\") && (T.matches.length == 1)",
		"return \"TypeConstParser.name!(\\\"\"~T.matches[0]~\"\\\")\""
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Name\") && (T.matches.length == 2)",
		"return \"TypeConstParser.name!(\\\"\"~T.matches[0]~\"\\\",\\\"\"~T.matches[1]~\"\\\")\""
						   ));
      mixin (compilerOverride!("ProcessGrammar.Domain",
        "\"TypeConstParser.domain!(\"~T.matches[0]~\")\""
      ));
      /*mixin (compilerOverride!("ProcessGrammar.CapEntry",
          "TypeConstParser.capability!(T.matches[0],TypeConstantCompiler!(T.children[0]).compile!())"
      ));*/
      mixin (compilerOverride!("ProcessGrammar.Composition",
          "\"TypeConstParser.composition!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\",\"~TypeConstantCompiler!(T.children[1]).compileNode~\")\""
      ));
      /*mixin (nodeOverride!("(T.name == \"ProcessGrammar.Ambient\") && (T.children.length == 1)",
        "return parser.ambient!(compile(T.children[0]))"
      ));
      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Ambient\") && (T.children.length == 2)",
        "return parser.ambient!(compile(T.children[0]),compile(T.children[1]))"
	  ));*/

      mixin (nodeOverride!("(T.name == \"ProcessGrammar.Capability\") && (T.children.length == 1)",
		  "return \"parser.capability!(\"~TypeConstantCompiler!(T.children[0]).compileNode~\")\""
      ));
}


unittest {
	enum EXPR = "P";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	//auto i = new TypeConstantInterpreter!(_CapType);
	//interp = i.interpret!(TypeConstant)(parser);
	enum compiler = TypeConstantCompiler!(parser).compileNode;
	sharedLog.info("compiled: ",compiler);
}

unittest {
	enum EXPR = "P|Q";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	//auto i = new TypeConstantInterpreter!(_CapType);
	//interp = i.interpret!(TypeConstant)(parser);
	enum compiler = TypeConstantCompiler!(parser).compileNode;
	sharedLog.info("compiled: ",compiler);
}

unittest {
	enum EXPR = "A[in B]|B[]";
	sharedLog.info("AMB Expression interpreter tests:",EXPR);
	enum CAPS = "('in' / 'out' / 'open')";

	enum ProcessGrammarFilename = "process.peg";
	mixin(grammar(import (ProcessGrammarFilename)));
	mixin(grammar("_CapType : CapPattern <- " ~ CAPS));

	enum parser = ProcessGrammar!(_CapType)(EXPR);
	//auto i = new TypeConstantInterpreter!(_CapType);
	//interp = i.interpret!(TypeConstant)(parser);
	enum compiler = TypeConstantCompiler!(parser).compileNode;
	sharedLog.info("compiled: ",compiler);
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
