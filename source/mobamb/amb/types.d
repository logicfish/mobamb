module mobamb.amb.types;

private import std.algorithm;
private import std.exception;

debug {
  import std.experimental.logger;
}

private import mobamb.amb.domain;
private import mobamb.amb.tag;
private import mobamb.amb.names;
private import mobamb.amb.channel;
private import mobamb.amb.process;
private import mobamb.amb.ambient;
private import mobamb.amb.host;

/**
The type environment implementation.
**/
class TypedProcessEnvironment : TypeEnvironment {
  static TypeEnvironment _globalEnv;
  Name _name;

  static this() {
    _globalEnv = new TypedProcessEnvironment;
  }
  /* ProcessDomain createProcessDomain(TypedProcess p) const {
    return new
  }
  void excercise(ProcessDomain,Capability); */

    @property inout(Name) name() @safe nothrow pure inout {
        return _name;
    }
    bool isBound(const(Name)) const {
        return false;
    }
    bool isRestricted(const(Name)) const {
        return false;
    }
    bool isRestricted() const {
        return false;
    }
    inout(Capability) binding(const(Name)) inout {
        return null;
    }
    typeof(this) binding(const(Name),Capability) {
      return this;
    }

}

abstract class Mobile : ProcessDomain {
  Process[] _children;
  Process _process;
  ProcessDomain _parent;

  @property {
    /* inout(Process) parent() @safe nothrow pure inout {
      return _parent;
    }
    typeof(this) parent(Process p) @safe nothrow pure {
      _parent = p;
      return this;
    } */
    inout(Process[]) children() @safe nothrow pure inout {
      return _children;
    }
    typeof(this) children(Process[] c) @safe nothrow pure {
      _children = c;
      return this;
    }
    inout(ProcessDomain) parent() @safe nothrow pure inout {
      return _parent;
    }
    typeof(this) parent(ProcessDomain d) @safe nothrow pure {
      _parent = d;
      return this;
    }
    inout(Process) process() @safe nothrow pure inout {
      return _process;
    }
    typeof(this) process(Process p) @safe nothrow pure {
      _process = p;
      return this;
    }
  }
  this(Process p) {
    _process = p;
    parent = TopDomain._topDomain;
  }

  Process getLocalAmbient() {
      auto ma = cast(MobileAmbient)process;
      if(ma !is null) return ma;
      //auto p = parent;
      //while(p.parent !is null && cast(MobileAmbient)p is null) p = p.parent;
      synchronized(this) {
        if(parent is null) return null;
        return cast(MobileAmbient)parent.getLocalAmbient;
      }
  }
  Process getParentAmbient() {
    auto a = getLocalAmbient;
    if(a is null) return null;
    auto p = a.domain.parent;
    if(p is null) return null;
    return cast(MobileAmbient)p.getLocalAmbient();
  }
  Process getHostAmbient() {
      auto ha = cast(HostAmbient)process;
      if(ha !is null) return ha;
      synchronized(this) {
        if(parent is null) return null;
        return cast(HostAmbient)parent.getHostAmbient;
      }
  }
  inout(ProcessDomain) getTypedDomain() inout {
    auto a = cast(TypedProcessDomain) this;
    if(a !is null) return cast(inout(ProcessDomain))this;
    if(parent is null) return null;
    return parent.getTypedDomain();
  }
  auto findChildByName(Name _n) {
    auto n = resolve(_n);
    synchronized(this) {
      auto c = children.filter!(x=>x.name.matches(n));
      if(!c.empty) return c.front;
    }
    return null;
  }
  auto findMatchingChildren(ProcessName.Caps c) {
    debug(Types) {
      sharedLog.info("findMatchingChildren:",c," ",children.length," ",name);
      foreach(d;children)
        sharedLog.info(" ------------> findMatchingChildren:",d.name);
    }
    synchronized(this) {
      return children.filter!(n=>c.matches(resolve(n.name)));
    }
  }
  void movingOut(ProcessDomain c) {
      enforce(process !is null);
      enforce(c !is null);
      debug(Types) {
        sharedLog.info("movingOut ",name," --> ",c.name);
      }
      //if(!(c in children)) return;
      if(c is null || c.parent!=this) {
        // throw?
        return;
      }
      //assert(c.domain !is null);
      synchronized(this) {
        debug(Types) {
          sharedLog.info("movingOut:",children);
        }
        _children = children.remove!(a => a == c.process);
        c.parent = TopDomain._topDomain;
        c.process._exit(name);
        process.exit_(c.name);
        debug(Types) {
          sharedLog.info("movingOut:",children);
        }
      }
  }

  void movingIn(ProcessDomain c) {
      enforce(process !is null);
      enforce(c !is null);
      debug(Types) {
        sharedLog.info("movingIn:",name," <-- ",c.name);
        sharedLog.info("movingIn:",name," <-- ",c);
      }
      if(c is null || c == this || c == parent) {
        // throw?
        return;
      }
      //assert(c.domain !is null);

      synchronized(this) {
        debug(Types) {
          sharedLog.info("movingIn:",children);
        }
        c.parent = this;
        _children ~= c.process;
        process.enter_(c.name);
        c.process._enter(name);
        debug(Types) {
          sharedLog.info("movingIn:",children);
        }
      }
      debug(Types) {
        sharedLog.info("done movingIn:",name," <-- ",c.name);
      }
  }
}

/**
 The ProcessDomain implementation.
 Inheriting classes are not usually made 'final', in comparison to
 the corresponding TypedProcess classes. This is to allow extensions
 to modify behaviour by overriding the typed process domain classes, rather than
 the typed process classes.
 **/
class UntypedProcessDomain : Mobile {
  @property {
    inout(Name) name() @safe nothrow pure inout {
      return _process.name;
    }
  }

  /**
  Output on channel 'n' using 'o'.
  **/
  bool output(Capability o) {
    //auto c = cast(ProcessName.Output)o;
    //return _process.getLocalAmbient.domain.output(n,o);
    return getLocalAmbient.domain.output(o);
  }
  /**
  Input from channel 'n' using capability 'o'.
  **/
  bool input(Capability o) {
    /* auto c = cast(ProcessName.Input)o;
    return _process.getLocalAmbient.domain.input(c.name,c.binding); */
    return getLocalAmbient.domain.input(o);
  }
  bool inputAvailable(const(Name) n) {
    return getLocalAmbient.domain.inputAvailable(n);
  }
  Channel channel(const(Name)n) {
    return getLocalAmbient.domain.channel(n);
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
  /*
  void enter(TypedProcess _p) {
    auto p = cast(MobileProcess)_p;
    if(p !is null) {
        _parent = p.domain;
    } else {
        _parent = TypedProcessDomain._topDomain;
    }
    //if(process.parent !is null) {
    //  _parent = process.parent.domain;
    //} else {
    //  _parent = TypedProcessDomain.topDomain;
    //}
  }*/

  /**
  The Process has set a null parent.
  Params:
    p = the previous parent.
  **/
  /*
  void exit(TypedProcess p) {
    _parent = TypedProcessDomain._topDomain;
  }*/

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
  this(Process p) {
    super(p);
  }

  //Name[] restrictions() const;
  //Name[] bindings() const;

  bool isBound(const(Name) n) const {
//    if(n in _inputs && _inputs[Name].inputAvailable) {
//      return true;
//    } else return parent.isBound(n);
    return parent.isBound(n);
  }
  bool isRestricted(const(Name) n) const {
    //if(n in _inputs && _inputs[Name].inputAvailable) return false;
    //else return parent.isRestricted(n);
    return parent.isRestricted(n);
  }
  bool isRestricted() const {
    return parent.isRestricted();
  }
  //bool bind(const(Name) n,const(Capability) c) {
  //  return parent.bind(n,c);
  //}
  /* bool restrict(const(Name) n) {
    return parent.restrict(n,c);
  } */
  inout(Capability) binding(const(Name) n) inout {
    return parent.binding(n);
  }
  ProcessDomain binding(const(Name)n,Capability c) {
    parent.binding(n,c);
    return this;
  }
  /*bool output(const(Name)n,Capability o) {
    return parent.output(n,o);
  }
  bool input(const(Name)n,Channel.OnInput o) {
    return parent.input(n,o);
  }
  bool inputAvailable(const(Name)n) {
    return parent.inputAvailable(n);
  }
  Channel channel(const(Name)n) {
    return parent.channel(n);
  }*/
  inout(Name) resolve(inout(Name) n) inout {
    debug(Types) {
      sharedLog.info("resolve ",n);
    }
    if(!isBound(n)) return n;
    auto b = binding(n);
    auto a = cast(inout(Name))b;
    if(a is null) return n;
    if(a !is n) return resolve(a);
    //if(isRestricted(a)) return null;
    debug(Types) {
      sharedLog.info("resolved ",n," - ",a);
    }
    return a;
  }
  inout(Capability) resolveCaps(inout(Capability) _n) inout {
    debug(Types) {
      sharedLog.info("resolve ",_n);
    }
    auto n = cast(inout(Name))_n;
    if(n is null) return _n;
    if(!isBound(n)) {
      if(isRestricted(n)) return null;
      return n;
    }
    auto b = binding(n);
    auto _b = cast(inout(Name))b;
    //if(_b !is null && isRestricted(_b)) return null;
    if(b !is _n) return resolveCaps(b);
    debug(Types) {
      sharedLog.info("resolved ",_n," - ",b);
    }
    return b;
  }

}

abstract class VoidProcessDomain : UntypedProcessDomain {
  override bool isBound(const(Name) n) const {
    return false;
  }
  override bool isRestricted(const(Name) n) const {
    return false;
  }
  override bool isRestricted() const {
    return false;
  }
  override inout(Capability) binding(const(Name) n) inout {
    return null;
  }
  override ProcessDomain binding(const(Name),Capability) {
    // throw..?
    return this;
  }

  override bool output(Capability o) {
    return false;
  }
  override bool input(Capability o) {
    return false;
  }
  override bool inputAvailable(const(Name)n) {
    return false;
  }
  override Channel channel(const(Name)n) {
    return null;
  }
  this(Process p) {
    super(p);
  }
}

final class TopDomain : VoidProcessDomain {
  this() {
    super(null);
  }
  static TopDomain _topDomain;

  static this() {
    _topDomain = new TopDomain;
    if(localDomain is null) localDomain = _topDomain;
  }
}
class NullProcessDomain : VoidProcessDomain {
  this(Process p) {
    super(p);
  }
}

class ComposedProcessDomain : UntypedProcessDomain {
  this(Process p) {
    super(p);
  }
}
class RestrictedProcessDomain : UntypedProcessDomain {
  const(Name) _restriction;
  @property {
    inout(const(Name)) restriction() @safe nothrow pure inout {
      return _restriction;
    }
  }
  override bool isRestricted(const(Name) n) const {
    if(restriction.matches(n) && !isBound(n)) return true;
    else return parent.isRestricted(n);
  }
  override bool isRestricted() const {
    if(isBound(restriction)) return false;
    else return true;
  }
  /*override bool isBound(const(Name) n) const {
    if(
      ProcessDomain.localDomain !is null &&
      ProcessDomain.localDomain !is this &&
      ProcessDomain.localDomain.isBound(n)
      ) {
        return true;
    } else {
      return super.isBound(n);
    }
  }
  override inout(Capability) binding(const(Name) n) inout {
    if(
      ProcessDomain.localDomain !is null &&
      ProcessDomain.localDomain !is this &&
      ProcessDomain.localDomain.isBound(n)
      ) {
        return cast(inout(Capability))ProcessDomain.localDomain.binding(n);
    } else {
      return super.binding(n);
    }
  }*/
  this(Process p,const(Name) r) {
    super(p);
    _restriction = r;
  }
}
class ReplicationProcessDomain : UntypedProcessDomain {
  this(Process p) {
    super(p);
  }
}
class BindingProcessDomain : UntypedProcessDomain {
  const(Name) _boundName;
  Capability _boundValue;

  override bool isBound(const(Name) n) const {
    if(boundName.matches(n)) {
      return true;
    } else {
      return parent.isBound(n);
    }
  }
  override inout(Capability) binding(const(Name) n) inout {
    if(boundName.matches(n)) return boundValue;
    else return parent.binding(n);
  }
  override ProcessDomain binding(const(Name)n,Capability c) {
    parent.binding(n,c);
    return this;
  }

  @property {
    inout(const(Name)) boundName() @safe nothrow pure inout {
      return _boundName;
    }
    inout(Capability) boundValue() @safe nothrow pure inout {
      return _boundValue;
    }
  }
  this(Process p,const(Name) n,Capability v) {
      super(p);
      _boundName = n;
      _boundValue = v;
  }
}

class TypedProcessDomain : UntypedProcessDomain {

  Capability[const(Name)] _bindings;

  this(Process p) {
      super(p);
  }
  override bool isBound(const(Name) n) const {
    debug(Types) {
      sharedLog.info("isBound ",n);
    }
    //if(n in channels && channels[n].inputAvailable) {
    if(n in _bindings) {
      return true;
    } else {
        /* if(parent !is null)return parent.isBound(n);
        return false; */
        return parent.isBound(n);
    }
  }
  override bool isRestricted(const(Name) n) const {
    if(n in _bindings) {
        return false;
    } else {
        return parent.isRestricted(n);
    }
  }
  override bool isRestricted() const {
    return parent.isRestricted();
  }
  override inout(Capability) binding(const(Name) n) inout {
    if(n in _bindings) return _bindings[n];
    return parent.binding(n);
  }
  override ProcessDomain binding(const(Name)n,Capability c) {
    //parent.binding(n,c);
    debug(Types) {
      sharedLog.info("binding ",n," -- ",c);
    }
    _bindings[n]=c;
    return this;
  }
}

class MobileProcessDomain : TypedProcessDomain {
  PIChannel[] channels;
  bool hasChannel(const(Name)_n) {
    auto n = resolve(_n);
    synchronized(this) {
      return !(channels.filter!(x=>x.name.matches(n)).empty);
    }
  }
  override Channel channel(const(Name)n) {
    debug(Types) {
      sharedLog.info("channel ",n);
    }
    if(!hasChannel(n)) {
        // search parents...
        auto q = parent;
        auto p = cast(MobileProcessDomain)parent;
        while((p is null || !p.hasChannel(n)) && q !is null) {
            q = q.parent;
            p = cast(MobileProcessDomain)q;
        }
        if(p !is null && p.hasChannel(n)) {
            return p.channel(n);
        }
        return null;
    }
    else {
      synchronized(this) {
        return channels.filter!(x=>x.name.matches(n)).front;
      }
    }
  }
  override bool output(Capability _o) {
    auto o = cast(ProcessName.Output)_o;
    enforce(o !is null);
    auto n = resolve(o.name);
    auto c = channel(n);
    debug(Types) {
      sharedLog.info("domain output ",_o.name,"(",n,")"," ",o.value);
    }
    if(c is null) {
        debug(Types) {
          sharedLog.info("new channel ",n);
        }
        auto _c = new PIChannel(n);
        synchronized(this) {
          channels ~= _c;
        }
        c = _c;
    }
    if(c.inputAvailable)return false;
    //return c.output(v);
    if(c.output(o.value)) {
      debug(Types) {
        sharedLog.info("done output ",o.value);
      }
      //auto _o = cast(ProcessName.Caps)o;
      //if(_o !is null)_o.action();
      o.action()(process);
      return true;
    }
    return false;
  }
  override bool input(Capability _o) {
    debug(Types) {
      sharedLog.info("domain input ",_o);
    }
    auto o = cast(ProcessName.Input)_o;
    auto n = resolve(o.name);
    auto b = resolve(o.binding);
    debug(Types) {
      sharedLog.info("domain input binding ",b);
    }
    if(isBound(b)) {
      debug(Types) {
        sharedLog.info("domain input already bound ",b);
      }
      return false;
    }
    auto c = channel(n);
    if(c is null) {
      debug(Types) {
        sharedLog.info("new channel ",n);
      }
      auto _c = new PIChannel(n);
      synchronized(this) {
        channels ~= _c;
      }
      c = _c;
    }
    return c.input((i){
        debug(Types) {
          sharedLog.info("channel input ",i);
        }
      // add the bound value to the local domain.
        binding(b,resolveCaps(i));
        //if(o.action !is null)
        synchronized(this) {
          channels = channels.remove!(x=>x is c);
        }
        o.action()(process);
        debug(Types) {
          sharedLog.info("done channel input ",i);
        }
      });
  }
  override bool inputAvailable(const(Name)n) {
    auto a = channel(resolve(n));
    if(a is null) return false;
    return a.inputAvailable;
  }
  this(Process p) {
      super(p);
  }
}

alias Location = MobileProcessDomain;


/**
This action adds a new child to an ambient.
**/
static Action makeAction(Process child) {
    return (p){
        debug(Types) {
          sharedLog.info("process action ",child);
        }
        p.domain.movingIn(child.domain);
    };
}
/**
This action adds a new child to an ambient.
**/
static Action makeAction(T : Process)(ProcessName n) {
    return (p){
      debug(Types) {
        sharedLog.info("process name action ",typeid(T)," ",n);
      }
      new T(p,n);
    };
}
/**
This action adds a new capabilty to an ambient.
**/
static Action makeAction(ProcessName.Caps c) {
    return (p){
      auto a = cast(MobileAmbient)p.domain.getLocalAmbient;
        debug(Types) {
          sharedLog.info("Caps action ",c," ",a.name);
        }
        if(a !is null) a.caps ~= c;
    };
}
