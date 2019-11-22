module mobamb.amb.names;

private import std.traits,
    std.algorithm,
    std.variant,
    std.conv;

private import mobamb.amb.domain;

alias Action = void delegate(Process);

class ProcessName : Name {
    abstract class Caps : Capability {
        Action _action;
        Action action() {
          if(_action !is null) {
            return _action;
          }
          else return (p){
          };
        }
        this(Action p) {
            if(p !is null) {
              _action = p;
            }
        }
        bool matches(const(Name) n) const {
            auto _n = (ProcessDomain.localDomain is null) ? this.name
                : ProcessDomain.localDomain.resolve(this.name);

            if(_n is null) return false;
            return _n.matches(n);
        }
        @property
        inout(Name) name() @safe nothrow pure inout {
          return this.outer;
        }
        override string toString() const {
          return "Caps:"~ capType ~ "(" ~ name.to!string ~ ")";
        }
    }
    final class In : Caps {
        this(Action p=null) {
          super(p);
        }
        string capType() @safe nothrow pure const {
          return "in";
        }
    };
    final class Out : Caps {
        this(Action p=null) {
          super(p);
        }
        string capType() @safe nothrow pure const {
          return "out";
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
    /* final class _Enter : Caps {
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
    }; */

    abstract class IOCaps : Caps {
      this(Action p=null) {
          super(p);
      }
      /*@property
      const(Name) channel() @safe nothrow pure const {
        //return _channel;
        return name;
      }*/
      alias channel = name;
    }
    // Pi caps
    abstract class InputCaps : IOCaps {
        const(Name) _binding;
        this(const(Name)b,Action p=null) {
            super(p);
            this._binding = b;
        }
        string capType() @safe nothrow pure const {
          return "input";
        }
        @property
        const(Name) binding() @safe nothrow pure const {
          return _binding;
        }
    };
    final class Input : InputCaps {
      this(const(Name)b,Action p=null) {
          super(b,p);
      }
    };
    final class InputParent : InputCaps {
      this(const(Name)b,Action p=null) {
          super(b,p);
      }
    };
    final class InputChildren : InputCaps {
      this(const(Name)b,Action p=null) {
          super(b,p);
      }
    };
    abstract class OutputCaps : IOCaps {
        Capability _value;
        this(Capability v,Action p=null) {
          super(p);
          _value = v;
        }
        string capType() @safe nothrow pure const {
          return "output";
        }
        @property
        inout(Capability) value() @safe nothrow pure inout {
          return _value;
        }
    };
    final class Output : OutputCaps {
      this(Capability v,Action p=null) {
        super(v,p);
      }
    }
    final class OutputParent : OutputCaps {
      this(Capability v,Action p=null) {
        super(v,p);
      }
    }
    final class OutputChildren : OutputCaps {
      this(Capability v,Action p=null) {
        super(v,p);
      }
    }

    bool matches(const(Name) n) const {
        return n==this;
    }

    @property
    inout(Name) name() @safe nothrow pure inout {
      return null;
    }

    Name _domain;

    @property
    inout(Name) domain() @safe nothrow pure inout {
      return _domain;
    }
    string capType() @safe nothrow pure const {
      return "name";
    }
    this(Name d=DefaultName.defaultName) {
      _domain = d;
    }
};

class NameLiteral : ProcessName {
    Variant _literal;
    this(Variant v,Name d=DefaultName.defaultName) {
      super(d);
      _literal = v;
    }
    this(T)(T t,Name d=DefaultName.defaultName) {
      this(Variant(t),d);
    }
    @property
    auto literal() nothrow inout {
      return _literal;
    }

    override bool matches(const(Name) n) const {
        if(n is this) return true;
        if(!domain.matches(n.domain))return false;
        auto l = cast(NameLiteral)n;
        if(l is null) return super.matches(n);
        return literal == l.literal ;
    }
    override string toString() const {
      return "NameLiteral:" ~ literal.get!string;
    }

    Name makeSymbolic() {
      return new SymbolicName(literal,domain);
    }
};

auto nameLiteral(T)(T t) {
  return new NameLiteral(t);
};

class SymbolicName : ProcessName {
  Variant _symbol;
  this(Variant v,Name d=DefaultName.defaultName) {
    super(d);
    _symbol = v;
  }
  this(T)(T t,Name d=DefaultName.defaultName) {
    this(Variant(t),d);
  }
  override bool matches(const(Name) n) const {
      if(n is this) return true;
      if(!domain.matches(n.domain))return false;
      auto l = cast(NameLiteral)n;
      if(l !is null) {
        return symbol == l.literal;
      }
      return super.matches(n);
  }
  override string toString() const {
    return "SymbolicName:" ~ symbol.get!string;
  }
  @property
  auto symbol() nothrow inout {
    return _symbol;
  }

};

template symbolicName(T) {
  auto symbolicName(T t,Name d=DefaultName.defaultName) {
    return new SymbolicName(t,d);
  }
}

/*
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
*/
/**
NilName matches nothing.
**/
final class NilName : ProcessName {
    override bool matches(const(Name) n) const {
      return false;
    }
    static NilName nilName;
    static this() {
        nilName=new NilName;
        nilName._domain = nilName;
    }
};

/**
DefaultName matches any DefaultName.
**/
final class DefaultName : ProcessName {
  override bool matches(const(Name) n) const {
    return cast(DefaultName)n !is null;
  }
  static DefaultName defaultName;
  static this() {
      defaultName=new DefaultName;
      defaultName._domain = defaultName;
  }
}
