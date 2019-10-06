module mobamb.amb.types;

private import mobamb.amb.domain;
private import mobamb.amb.tag;
private import mobamb.amb.names;
private import mobamb.amb.ambient;
private import mobamb.amb.host;

private import std.algorithm;

synchronized class PIChannel : Channel {
    //Capability[ProcessName] bindings;

    bool _inputAvailable = false;
    Capability inputCap = null;
    OnInput onInput = null;

    @property {
      bool inputAvailable() @safe nothrow pure const {
        return _inputAvailable;
      }
      typeof(this) inputAvailable(bool b) @safe nothrow pure {
        _inputAvailable = b;
        return this;
      }
    }

    override bool output(Capability o) {
        if(inputAvailable) return false;
        if(onInput!=null) {
          onInput(o);
          onInput = null;
        }
        else {
          inputAvailable = true;
          inputCap = o;
        }
        return true;
    }

    override void input(OnInput o) {
        if(inputAvailable==true) {
          o(inputCap);
          inputCap=null;
          inputAvailable = false;
        } else {
          onInput = o;
        }
    }
};



/**
The type environment implementation.
**/
class TypedProcessEnvironment : TypeEnvironment {
  static TypedEnvironment _globalEnv;

  static this() {
    _globalEnv = new TypedEnvironment;
  }
  /* ProcessDomain createProcessDomain(TypedProcess p) const {
    return new
  }
  void excercise(ProcessDomain,Capability); */
}


/**
 * The ProcessDomain implementation
 **/
class TypedProcessDomain : ProcessDomain {
  MobileProcess _process;
  TypedProcessDomain _parent;
  @property {
    inout(ProcessDomain) parent() @safe nothrow pure inout {
      return _parent;
    }
    typeof(this) parent(TypedProcessDomain d) @safe nothrow pure {
      _parent = d;
      return this;
    }
    inout(TypedProcess) process() @safe nothrow pure inout {
      return _process;
    }
    typeof(this) process(MobileProcess p) @safe nothrow pure {
      _process = p;
      return this;
    }
    inout(Name) name() @safe nothrow pure inout {
      return _process.name;
    }
    void output(const(Name) n,Capability o) {
      process.getLocalAmbient.domain.output(n,o);
    }
    void input(const(Name),OnInput o) {
      process.getLocalAmbient.domain.input(n,o);
    }
}
  //bool capsMatch(Name n,Capability c);
  //void apply(TypedProcess p,Capability c) {
  //}
  /*bool canExit(Name) const {
    return true;
  }
  bool canEnter(Name) {
    return true;
  }*/

  /**
  The Process has a new parent.
  Params:
    p = the new parent.
  **/
  void enter(TypedProcess p) {
    if(process.parent !is null) {
      _parent = process.parent.domain;
    } else {
      _parent = TypedProcessDomain.topDomain;
    }
  }

  /**
  The Process has set a null parent.
  Params:
    p = the previous parent.
  **/
  void exit(TypedProcess p) {
    _parent = null;
  }

  /*TypedProcess[] match(Capability) {
    return [];
  }*/
  /*bool createTag(Tag.Apply f,Tag.Close c)(Capability cap) {
    return _typedProcess.getHostAmbient.createTag!(f,c)();
  }*/
  //bool createTag(T:Tag)(Capability cap) {
    //return _typedProcess.getHostAmbient.createTag!T(cap,_typedProcess.getLocalAmbient);
    //return false;
  //}
  this(TypedProcess p) {
    _typedProcess = p;
    //_typedProcess._domain = this;
  }

  bool isBound(const(Name) n) const {
    if(n in _inputs) {
      return true;
    } else return parent.isBound(n);
  }
  bool isRestricted(const(Name) n) const {
    if(n in _inputs) return false;
    else return parent.isRestricted(n);
  }
  bool isRestricted() const {
    return parent.isRestriced();
  }
  //Name[] restrictions() const;
  //Name[] bindings() const;
  //bool bind(const(Name) n,const(Capability) c) {
  //  return parent.bind(n,c);
  //}
  /* bool restrict(const(Name) n) {
    return parent.restrict(n,c);
  } */
  const(Capability) binding(const(Name) n) const {
    return parent.binding(n);
  }

  static TopDomain _topDomain;
  static this() {
    _topDomain = new TopDomain;
  }
}

class TopDomain : TypedProcessDomain {
  bool isBound(const(Name) n) const {
    return false;
  }
  bool isRestricted(const(Name) n) const {
    return false;
  }
  bool isRestricted() const {
    return false;
  }
  const(Capability) binding(const(Name) n) const {
    return n;
  }
}

class RestrictedProcessDomain : TypedProcessDomain {
  const(Name) _restriction;
  @property {
    inout(const(Name)) restriction() @safe nothrow pure inout {
      return _restriction;
    }
    typeof(this) restriction(const(Name) n) @safe nothrow pure {
      _restriction = n;
      return this;
    }
  }
  bool isRestricted(const(Name) n) const {
    if(n !in _inputs && restriction.matches(n)) return true;
    else return parent.isRestriced(n);
  }
  bool isRestricted() const {
    return isBound(restriction);
  }
  this(TypedProcess p,const(Name) r) {
    super(p);
    restriction = r;
  }
}
class BindingDomain : TypedProcessDomain {
  const(Name) _boundName;
  Capability _bouldValue;
  bool isBound(const(Name) n) const {
    if(boundName.matches(n)) {
      return true;
    } else {
      return parent.isBound(n);
    }
  }
  const(Capability) binding (const(Name) n) const {
    if(boundName.matches(n)) return value;
    else return parent.binding(n);
  }
  @property {
    inout(const(Name)) boundName() @safe nothrow pure inout {
      return _boundName;
    }
    typeof(this) boundName(const(Name) n) @safe nothrow pure {
      _boundName = n;
      return this;
    }
    inout(Capability) boundValue() @safe nothrow pure inout {
      return _boundValue;
    }
    typeof(this) boundValue(Capability v) @safe nothrow pure {
      _boundValue = v;
      return this;
    }
  }
  this(TypedProcesss p,const(Name) n,Capability v) {
      super(p);
      boundName = n;
      boundValue = v;
  }
}

class MobileProcessDomain : TypedProcessDomain {
  PIChannel[const(Name)] channels;

  Channel channel(const(Name)n) {
    if(n !in channels) channels[n] = new PIChannel;
    return channels[n];
  }
  bool output(const(Name)n,Capability o) {
    auto c = channel(n);
    if(c.inputAvailable)return false;
    c.output(o);
    return true;
  }
  void input(const(Name)n,OnInput o) {
    if(n !in channels) channels[n] = new PIChannel;
    channels[n].input(n,o);
  }
  bool inputAvailable(const(Name)n) {
    if(n !in channels) channels[n] = new PIChannel;
    return channels[n].inputAvailable;
  }
}

abstract class MobileProcess : TypedProcess {
    ProcessName _name;
    MobileProcess _parent;
    MobileProcess[] _children;
    //Tag[] evol;
    ProcessDomain _domain;

    this() {
      _domain = new MobileProcessDomain(this);
    }

    @property {
      inout(ProcessName) name() @safe nothrow pure inout {
        return _name;
      }
      inout(MobileProcess) parent() @safe nothrow pure inout {
        return _parent;
      }
      typeof(this) parent(MobileProcess p) @safe nothrow pure {
        _parent = p;
        return this;
      }
      inout(MobileProcess[]) children() @safe nothrow pure inout {
        return _children;
      }
      inout(Name) domain() @safe nothrow pure inout {
        return _domain;
      }
    }

    void movingOut(MobileProcess c) {
        //if(!(c in children)) return;
        if(c.parent!=this)return;
        //c.exit(p);
        exit_(c.name);
        children = children.remove!(a => a == c);
        c._exit(name);
        c.parent = null;
    }

    void movingIn(MobileProcess c) {
        if(c is null || c == this || c == parent) return;
        //this.enter_(c.name);
        children ~= c;
        //c._enter(name);
        c.parent = this;
        //c.enter(this);
    }

    override bool cleanup() {
        foreach(c;children) if(c.cleanup==false) return false;
        return true;
    }
    ProcessName findChildByName(ProcessName n) {
        n = cast(ProcessName)resolve(n);
        foreach(c;children) {
            if (c.name.matches(n)) {
              return c.name;
            }
        }
        return null;
    }
    auto findMatchingChildren(ProcessName.Caps c) {
        return children.filter!(n=>c.matches(n.name));
    }


    MobileAmbient getLocalAmbient() {
        auto ma = cast(MobileAmbient)this;
        if(ma !is null) return ma;
        auto p = parent;
        while(p.parent !is null && cast(MobileAmbient)p is null) p = p.parent;
        return cast(MobileAmbient)p;
    }
    MobileAmbient getParentAmbient() {
      auto p = getLocalAmbient().parent;
      if(p is null) return null;
      return p.getLocalAmbient();
    }
    HostAmbient getHostAmbient() {
        auto ha = cast(HostAmbient)this;
        if(ha !is null) return ha;
        auto p = parent;
        while(p.parent !is null && cast(HostAmbient)p is null) {
          p = p.parent;
        }
        return cast(HostAmbient)p;
    }

    //void enter(MobileProcess) { }
    //void exit(MobileProcess) { }
    /*void _enter(ProcessName n) { }
    void _exit(ProcessName n) { }
    void enter_(ProcessName n) { }
    void exit_(ProcessName n) { }*/

/*
    Capability resolve(Capability o) {
        if(cast(ProcessName)o is null) return o;
        if(cast(NameBinding)o !is null) return o;
        auto n = cast(ProcessName)o;
        // does it match siblings?
        //foreach(c;parent.children) {
        //	if(c.getName.matches(o)) return new NameBinding(c.getName);
        //}
        // does the name match our parent?
        // does the name match a local binding?
        MobileProcess p = this;
        while(p !is null) {
            if(cast(NamedProcess)p !is null) {
                auto q = cast(NamedProcess)p;
                if(q.name.matches(n)) {
                    return new NameBinding(q.name);
                }
                //if(n in q.bindings)return q.bindings[n];
                foreach(cap,name;q.bindings) {
                    if (name.matches(n)) {
                        return new NameBinding(cap);
                    }
                }
                // does the name match a restriction?
                //} else if(isAssignable!(Restriction,typeid(p))) {
                //	auto q = cast(Restriction)parent;
            }
            // ...
            p = p.parent;
        }
        return o;
    }*/
};

class NullProcess : MobileProcess {
    override bool cleanup() {
        parent.movingOut(this);
        return false;
    }
    /* override Tag[] evolutions() {
        return [];
    } */
};

class ComposedProcess : MobileProcess {
    override bool cleanup() {
        /* evol = []; */
        auto p = parent;
        //if(p is null) return this;
        if(parent !is null) {
            parent.movingOut(this);
            foreach(c;children) {
                if(p !is null) {
                    movingOut(c);
                    p.movingIn(c);
                }
            }
            return false;
        }
        return true;
    }

};


class CapsProcess : MobileProcess {
    ProcessName.Caps cap;
    this(ProcessName.Caps c) { cap=c; }
    override bool cleanup() {
        /* evol = []; */
        auto p = getParentAmbient();
        if(p !is null) {
            parent.movingOut(this);
            getLocalAmbient.caps ~= cap;
            return false;
        }
        return true;
    }
};
class MatchParentNameProcess (T : ProcessName.Caps) : MobileProcess {
    ProcessName match;
    Action action;
    this(ProcessName n,Action a) { match=n; action=a; }
    override bool cleanup() {
        /* evol = []; */
        auto p = getParentAmbient();
        if(p !is null) {
            ProcessName n = cast(ProcessName)resolve(match);
            if(p.name.matches(n)) {
                auto c = m.new T(action);
                parent.movingOut(this);
                getLocalAmbient.caps ~= c;
                return false;
            }
        }
        return true;
    }
};
class MatchSiblingNameProcess (T : ProcessName.Caps) : MobileProcess {
    ProcessName match;
    Action action;
    this(ProcessName n,Action a) { match=n; action=a; }
    override bool cleanup() {
        evol = [];
        auto p = getParentAmbient();
        if(p !is null) {
            //auto m = cast(MobileAmbient)p;
            //Name n = p.resolve(match);
            auto m = p.findChildByName(match);
            if(m) {
                auto c = m.new T(action);
                parent.movingOut(this);
                getLocalAmbient.caps ~= c;
                return false;
            }
        }
        return true;
    }
};

class Restriction : MobileProcess {
    //bool restricted;
    //Capability restrictedName;
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.restrict();
        parent.movingOut(this);
        return false;
    }
    this(const(Name) r) {
      _domain = new RestrictedProcessDomain(this,r);
    }
};
class Binding : MobileProcess {
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.bind();
        parent.movingOut(this);
        return false;
    }
    this(const(Name) n,Capability v) {
      _domain = new RestrictedProcessDomain(this,n,v);
    }
};

/*class Constructor : MobileProcess {
  MobileProcess newProcess;

  this(MobileProcess p) {
    newProcess = p;
  }
  override bool cleanup() {
      if(super.cleanup == false) return false;
      evol = [localDomain.createTag({
        parent.movingOut(this);
        parent.movingIn(newProcess);
        return true;
      },delegate void(bool){})];

      return true;
  }
  override Tag[] evolutions() {
    return evol;
  }
}*/

class Replication : MobileProcess {

}

/*
abstract class IOProcess : MobileProcess {
    /*override bool cleanup() {
        bool delta=true;
        //while(!(parent is null) && !isAssignable!(NamedProcess,typeid(parent))) {
        while(!(parent is null) && cast(NamedProcess)parent !is null) {
            parent.movingOut(this);
            if(!(parent.parent is null)) parent.parent.movingIn(this);
            delta=false;
        }
        if(delta)delta=super.cleanup;
        return delta;
    }* /
};

class OutputProcess : IOProcess {
    Capability outputCap;
    this(Capability o) { this.outputCap = o; }
    override bool cleanup() {
        this.outputCap = resolve(this.outputCap);
        return super.cleanup;
    }
    /* override Tag[] evolutions() {
        if(cast(NamedProcess)parent is null) return [];
        auto p = cast(NamedProcess)parent;
        if(p.inputAvailable == true) return [];
        /* return [localDomain.createTag!((){
            p.movingOut(this);
            p.output(outputCap);
            return true;
        },delegate void(bool f){})()]; * /
        return [];
    } * /
};

class InputProcess : IOProcess {
    ProcessName inputName;
    MobileProcess action;
    this(ProcessName i,MobileProcess a) {
        this.inputName = i;
        this.action = a;
    }

    /* override Tag[] evolutions() {
        auto p = cast(NamedProcess)parent;
        //if(p.inputAvailable == false) return [];
        /* return [localDomain.createTag!({
            p.movingOut(this);
            p.input((i) {
                p.bindings[inputName]=i;
                p.movingIn(action);
            });
            return true;
        },delegate void(bool){})()]; * /
        return [];
    } * /
};
*/

/**
This action adds a new child to an ambient.
**/
static Action makeAction(MobileProcess child) {
    return (p){
        auto a = cast(MobileAmbient)p;
        if(a !is null) a.movingIn(child);
    };
}
/**
This action adds a new capabilty to an ambient.
**/
static Action makeAction(ProcessName.Caps c) {
    return (p){
        auto a = cast(MobileAmbient)p;
        if(a !is null) a.caps ~= c;
    };
}
