module mobamb.amb.names;

private import std.traits,
    std.algorithm,
    std.variant;

version(unittest) {
    import std.stdio;
};

private import mobamb.amb.domain;

alias Action = void delegate(TypedProcess);

class ProcessName : Name {
    abstract class Caps : Capability {
        Action _action;
        Action action() {
          if(_action !is null) {
            return _action;
          }
          else return (p){};
        }
        this(Action p) {
            if(p !is null) {
              _action = p;
            }
        }
        bool matches(Name n) {
            return this.getName.matches(n);
        }
        Name getName() {
          return this.outer;
        }
    }
    final class In : Caps {
        this(Action p=null) {
          super(p);
        }
    };
    final class Out : Caps {
        this(Action p=null) {
          super(p);
        }
    };
    //class Open : Caps {
    //	this(Action p) { super(p); }
    //};
    //class Enter : Caps {
    //	this(Action p=null) { super(p); }
    //};
    //class Exit : Caps {
    //	this(Action p=null) { super(p); }
    //};
    final class _Enter : Caps {
        this(Action p=null) { super(p); }
    };
    final class _Exit : Caps {
        this(Action p=null) { super(p); }
    };
    final class Enter_ : Caps {
        this(Action p=null) { super(p); }
    };
    final class Exit_ : Caps {
        this(Action p=null) { super(p); }
    };
    final class _In : Caps {
        this(Action p=null) { super(p); }
    };
    final class _Out : Caps {
        this(Action p=null) { super(p); }
    };
    final class In_ : Caps {
        this(Action p=null) { super(p); }
    };
    final class Out_ : Caps {
        this(Action p=null) { super(p); }
    };

    // Pi caps
    final class Input : Caps {
        this(Action p=null) { super(p); }
    };
    final class Output : Caps {
        this(Action p=null) { super(p); }
    };

    //string id;
    //string getId() { return id; }
    bool matches(Capability n) {
        //return id == n.getId();
        return n==this;
    }
    override Name getName() {
        return null;
    }
};

class NameLiteral : ProcessName {
    Variant lit;
    this(Variant v) { lit = v; }
    this(T)(T t) { this(Variant(t)); }
    override bool matches(Capability n) {
        auto l = cast(NameLiteral)n;
        if(l is null) return super.matches(n);
        return lit == l.lit;
    }
};

class NameBinding : ProcessName {
    Capability boundName;
    override bool matches(Capability n) {
        //if(boundName is null) return false;
        return n.matches(boundName);
        //return boundName == n;
    }
    this(Capability bind) {
      this.boundName = bind;
    }
};

class TypedName : ProcessName {
    ProcessName[] types;
    override bool matches(Capability n) {
        if(super.matches(n)) return true;
        foreach(t;types) {
            if(t.matches(n)) return true;
        }
        return false;
    }
};

final class WildcardName : ProcessName {
    override bool matches(Capability n) {
        return true;
    }

    static WildcardName wildcardName;

    static this() {
        if(wildcardName is null) {
            wildcardName=new WildcardName;
        }
    }
};

final class NilName : ProcessName {
    override bool matches(Capability n) { return false; }
    static NilName nilName;
    static this() {
        if(nilName is null) {
            nilName=new NilName;
        }
    }
};
