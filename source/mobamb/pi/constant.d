module mobamb.pi.constant;

private import pegged.grammar;

class TypeConstant {
	ParseTree _parseTree;
	public {
		@property
		ParseTree parseTree() {
			return _parseTree;
		}
		@property
		void parseTree(ParseTree t) {
			_parseTree = t;
		}
	}
}

class ProcessTypeConstant : TypeConstant {
    TypeConstant _process;
    this(TypeConstant p=null) {
        this._process = p;
    }
}
template processTypeConstant(alias TypeConstant P) {
    auto processTypeConstant() {
        return new ProcessTypeConstant(P);
    }
}

auto processTypeConstant(ref TypeConstant P) {
  return new ProcessTypeConstant(P);
}

class VoidTypeConstant : ProcessTypeConstant {
}

template voidTypeConstant() {
    auto voidTypeConstant() {
        return new VoidTypeConstant();
    }
}

class ErrorTypeConstant : ProcessTypeConstant {
}

template errorTypeConstant() {
    auto errorTypeConstant() {
        return new ErrorTypeConstant();
    }
}

// A symbolic reference

class SymRefTypeConstant(alias SYM) : ProcessTypeConstant {
    SYM _symRef;
    this(SYM r) {
        _symRef = r;
    }
    @property
    auto ref symRef() pure nothrow @safe {
        return _symRef;
    }
}

template symRefTypeConstant(alias SYM) {
    auto symRefTypeConstant(SYM s) {
        return new SymRefTypeConstant!SYM(s);
    }
}

class StringRefTypeConstant : SymRefTypeConstant!string {
  this(string r) {
    super(r);
  }
}

template stringRefTypeConstant(string s) {
    auto stringRefTypeConstant() {
        return new StringRefTypeConstant(s);
    }
}
auto stringRefTypeConstant(string s) {
    return new StringRefTypeConstant(s);
}

/* auto stringRefTypeConstant(string s) {
    return new StringRefTypeConstant(s);
} */

class ActionTypeConstant : ProcessTypeConstant {
    CapTypeConstant _cap;
    this(CapTypeConstant c,ProcessTypeConstant p) {
        this._cap = c;
        super(p);
    }
}

template actionTypeConstant(alias CapTypeConstant A,alias ProcessTypeConstant P) {
    auto actionTypeConstant() {
        return new ActionTypeConstant(A,P);
    }
}
template actionTypeConstant(string A) {
    auto actionTypeConstant() {
        return new ActionTypeConstant(A,P);
    }
}
auto actionTypeConstant(CapTypeConstant a,ProcessTypeConstant p) {
  return actionTypeConstant!(a,p);
}
template actionTypeConstant(alias CapTypeConstant A) {
    auto actionTypeConstant() {
        return new ActionTypeConstant(A,voidTypeConstant);
    }
}
auto actionTypeConstant(CapTypeConstant a) {
  return actionTypeConstant(a,voidTypeConstant);
}

class PathTypeConstant : ProcessTypeConstant {
    TypeConstant _path;
    this(TypeConstant path,ProcessTypeConstant p) {
        this._path = path;
        super(p);
    }
}
template pathTypeConstant(alias TypeConstant E,alias ProcessTypeConstant P) {
    auto pathTypeConstant() {
        return new PathTypeConstant(E,P);
    }
}
auto pathTypeConstant(TypeConstant e,ProcessTypeConstant p) {
  return new PathTypeConstant(e,p);
}

class CapTypeConstant : TypeConstant {
    const(string) _cap;
    NameTypeConstant _name;
	TypeConstant _process;
    this(const(string) c,NameTypeConstant n,TypeConstant p=voidTypeConstant) {
        this._cap = c;
		this._name = n;
		this._process = p;
    }
}
class _CapTypeConstant(const(string) C) : CapTypeConstant {
    this(NameTypeConstant n,TypeConstant p=voidTypeConstant) {
        super(C,n,p);
    }
}

template capTypeConstant(const(string) C) {
    auto capTypeConstant(NameTypeConstant n,TypeConstant p=voidTypeConstant) {
        return new _CapTypeConstant!C(n,p);
    }
}
auto capTypeConstant(const(string) c,NameTypeConstant n,TypeConstant p=voidTypeConstant) {
    return new CapTypeConstant(c,n,p);
}
class NameTypeConstant : TypeConstant {
    TypeConstant _domain;
    TypeConstant _name;
    this(T)(T d,TypeConstant n) {
        this._domain = symRefTypeConstant!T(d);
        this._name = n;
    }
    this(T)(T n) {
        this._domain = alphaDomain;
        this._name = symRefTypeConstant!T(n);
    }
    this(T)(T d,T n) {
        this._domain = symRefTypeConstant!T(d);
        this._name = symRefTypeConstant!T(n);
    }
    this(TypeConstant d,TypeConstant n) {
        this._domain = d;
        this._name = n;
    }
    this(TypeConstant n) {
        this._domain = alphaDomain;
        this._name = n;
    }
}
template nameTypeConstant(const(string) N) {
    auto nameTypeConstant() {
        return new NameTypeConstant(N);
    }
}
template nameTypeConstant(const(string)D,const(string) N) {
    auto nameTypeConstant() {
        return new NameTypeConstant(D,N);
    }
}
template nameTypeConstant(const(string) D,alias TypeConstant N) {
    auto nameTypeConstant() {
        return new NameTypeConstant(D,N);
    }
}

auto nameTypeConstant(const(string) d,TypeConstant n) {
    return new NameTypeConstant(d,n);
}
auto nameTypeConstant(const(string) d,const(string) n) {
	return new NameTypeConstant(d,n);
}
auto nameTypeConstant(const(string) n) {
	return new NameTypeConstant(n);
}

template nameTypeConstant(alias TypeConstant N) {
    auto nameTypeConstant() {
        return new NameTypeConstant(N);
    }
}
auto nameTypeConstant(TypeConstant n) {
    return new NameTypeConstant(n);
}

class CompositionTypeConstant : TypeConstant {
    TypeConstant _composed;
    TypeConstant _process;
    this(TypeConstant c,TypeConstant p) {
        this._composed = c;
        this._process = p;
    }
}
template compositionTypeConstant(alias TypeConstant C,alias TypeConstant P) {
    auto compositionTypeConstant() {
        return new CompositionTypeConstant(C,P);
    }
}
auto compositionTypeConstant(TypeConstant c,TypeConstant p) {
    return new CompositionTypeConstant(c,p);
}

class AmbientTypeConstant : TypeConstant {
    NameTypeConstant _name;
    TypeConstant[] _process;
    this(NameTypeConstant n,TypeConstant[] p=[]) {
        this._name = n;
        this._process = p;
    }
}
template ambientTypeConstant(alias NameTypeConstant N,alias TypeConstant[] P=[]) {
    auto ambientTypeConstant() {
        return new AmbientTypeConstant(N,P);
    }
}
auto ambientTypeConstant(NameTypeConstant n,TypeConstant[] p = []) {
    return new AmbientTypeConstant(n,p);
}

class HostAmbientTypeConstant : AmbientTypeConstant {
    this(NameTypeConstant n,TypeConstant[] p) {
        super(n,p);
    }
}

// domains

template alphaDomain() {
  auto alphaDomain() {
    return symRefTypeConstant!string("α");
  }
}
