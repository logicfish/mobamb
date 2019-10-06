module mobamb.amb.names;

private import std.traits,
    std.algorithm,
    std.variant;

private import mobamb.amb.domain;
private import mobamb.amb.tag;

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
        bool matches(const(Name) n) const {
            return this.name.matches(n);
        }
        @property
        inout(Name) name() @safe nothrow pure inout {
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
    bool matches(const(Name) n) const {
        //return id == n.getId();
        return n==this;
    }

    @property
    inout(Name) name() @safe nothrow pure inout {
      return null;
    }

    Domain _domain;
    @property
    inout(Domain) domain() @safe nothrow pure inout {
      return _domain;
    }
};

class NameLiteral : ProcessName {
    Variant lit;
    this(Variant v) { lit = v; }
    this(T)(T t) { this(Variant(t)); }
    override bool matches(const(Name) n) const {
        auto l = cast(NameLiteral)n;
        if(l is null) return super.matches(n);
        return lit == l.lit;
    }
};

class NameBinding : ProcessName {
    Name boundName;
    override bool matches(const(Name) n) const {
        //if(boundName is null) return false;
        return n.matches(boundName);
        //return boundName == n;
    }
    this(Name bind) {
      this.boundName = bind;
    }
};

class TypedName : ProcessName {
    ProcessName[] types;
    override bool matches(const(Name) n) const {
        if(super.matches(n)) return true;
        foreach(t;types) {
            if(t.matches(n)) return true;
        }
        return false;
    }
};

final class WildcardName : ProcessName {
    override bool matches(const(Name) n) const {
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
    override bool matches(const(Name) n) const {
      return false;
    }
    static NilName nilName;
    static this() {
        if(nilName is null) {
            nilName=new NilName;
        }
    }
};
