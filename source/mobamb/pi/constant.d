
module mobamb.amb.constant;

class TypeConstant {
}

class ProcessTypeConstant : TypeConstant {
    TypeConstant _process;
    this(TypeConstant p=null) {
        this._process = p;
    }
}
template processTypeConstant(alias P : TypeConstant) {
    auto processTypeConstant() {
        return new ProcessTypeConstant(P);
    }
}

class VoidTypeConstant : ProcessTypeConstant {
}

template voidTypeConstant() {
    auto voidTypeConstant() {
        return new VoidTypeConstant();
    }
}

// A symbolic reference

class SymRefTypeConstant(alias SYM) : ProcessTypeConstant {
    SYM _symRef;
    this(SYM r) {
        _symRef = r;
    }
    ref SYM symRef() {
        return _symRef;
    }
}

template symRefTypeConstant(alias SYM) {
    auto symRefTypeConstant(SYM s) {
        return new SymRefTypeConstant!SYM(s);
    }
}

class ActionTypeConstant : ProcessTypeConstant {
    CapTypeConstant _cap;
    this(CapTypeConstant c,ProcessTypeConstant p) {
        this._cap = c;
        super(p);
    }
}

template actionTypeConstant(alias A : TypeConstant,alias P  : TypeConstant) {
    auto actionTypeConstant() {
        return new ActionTypeConstant(A,P);
    }
}

class PathTypeConstant : ProcessTypeConstant {
    TypeConstant _path;
    this(TypeConstant path,ProcessTypeConstant p) {
        this._path = path;
        super(p);
    }
}
template pathTypeConstant(alias E : TypeConstant ,alias P : TypeConstant) {
    auto pathTypeConstant() {
        return new PathTypeConstant(E,P);
    }
}

class CapTypeConstant : TypeConstant {
    const(string) _cap;
    this(const(string) c) {
        this._cap = c;
    }
}
class _CapTypeConstant(const(string) C) : CapTypeConstant {
    this() {
        super(C);
    }
}
template capTypeConstant(C : const(string)) {
    auto capTypeConstant(alias P : TypeConstant)() {
        return new _CapTypeConstant!C(P);
    }
}
template capTypeConstant(alias C,alias P : TypeConstant) {
    auto capTypeConstant() {
        return new CapTypeConstant(C,P);
    }
}
class NameTypeConstant : _CapTypeConstant!"name" {
    SymRefTypeConstant!string _domain;
    TypeConstant _name;
    this(const(string) d,TypeConstant n) {
        super();
        this._domain = symRefTypeConstant!string(d);
        this._name = n;
    }
}
template nameTypeConstant(alias D : const(string),alias N : TypeConstant) {
    auto nameTypeConstant() {
        return new NameTypeConstant(D,N);
    }
}

template nameTypeConstant(alias N : TypeConstant) {
    auto nameTypeConstant() {
        return new NameTypeConstant(alphaDomain,N);
    }
}

class CompositionTypeConstant : TypeConstant {
    TypeConstant _composed;
    TypeConstant _process;
    this(TypeConstant c,TypeConstant p) {
        this._composed = c;
        this._process = p;
    }
}
template compositionTypeConstant(alias C : TypeConstant,alias P : TypeConstant) {
    auto compositionTypeConstant() {
        return new CompositionTypeConstant(C,P);
    }
}

class AmbientTypeConstant : TypeConstant {
    NameTypeConstant _name;
    TypeConstant _process;
    this(NameTypeConstant n,TypeConstant p) {
        this._name = n;
        this._process = p;
    }
}
template ambientTypeConstant(alias P : TypeConstant) {
    auto ambientTypeConstant() {
        return new AmbientTypeConstantExpression(P);
    }
}

class HostAmbientTypeConstant : AmbientTypeConstant {
    this(NameTypeConstant n,TypeConstant p) {
        super(n,p);
    }
}

// domains

const alphaDomain = symRefTypeConstant!string("α");
