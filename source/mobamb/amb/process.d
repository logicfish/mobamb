module mobamb.amb.process;

private import std.algorithm;

debug {
  import std.experimental.logger;
}

private import mobamb.amb.domain;
private import mobamb.amb.tag;
private import mobamb.amb.names;
private import mobamb.amb.types;
private import mobamb.amb.ambient;
private import mobamb.amb.host;

abstract class MobileProcess : TypedProcess {
    ProcessName _name;
    MobileProcess _parent;
    MobileProcess[] _children;
    //Tag[] evol;
    ProcessDomain _domain;
    bool mobilityLocked = false;

    //this() {
    //  _domain = new MobileProcessDomain(this);
    //}

    this(TypedProcess p) {
      if(cast(MobileProcess)p !is null) {
          (cast(MobileProcess)p).movingIn(this);
      }
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
      typeof(this) children(MobileProcess[] c) @safe nothrow pure {
        _children = c;
        return this;
      }
      inout(ProcessDomain) domain() @safe nothrow pure inout {
        return _domain;
      }
    }

    void movingOut(MobileProcess c) {
        debug(Process) {
          sharedLog.info("movingOut ",c.name);
        }
        //if(!(c in children)) return;
        if(c is null || c.parent!=this || mobilityLocked || c.mobilityLocked) {
          // throw?
          return;
        }
        synchronized(this) {
          exit_(c.name);
          _children = children.remove!(a => a == c);
          c.parent = null;
          c.domain.parent = TopDomain._topDomain;
          c._exit(name);
        }
    }

    void movingIn(MobileProcess c) {
        debug(Process) {
          sharedLog.info("movingIn ",c.name);
          sharedLog.info("movingIn -- ",domain);
        }
        if(c is null || c == this || c == parent || mobilityLocked || c.mobilityLocked) {
          // throw?
          return;
        }
        synchronized(this) {
          this.enter_(c.name);
          _children ~= c;
          c.parent = this;
          c.domain.parent = domain;
          c._enter(name);
        }
    }

    override bool cleanup() {
      synchronized(this) {
        foreach(c;children) if(c.cleanup==false) return false;
      }
      return true;
    }
    override bool evaluateAll() {
        if(domain.isRestricted) return false;
        synchronized(this) {
          foreach(c;children) {
            if(c.evaluateAll) return true;
          }
        }
        return false;
    }

    /*ProcessName findChildByName(ProcessName n) {
        n = cast(ProcessName)resolve(n);
        foreach(c;children) {
            if (c.name.matches(n)) {
              return c.name;
            }
        }
        return null;
    }*/
    auto findChildByName(ProcessName n) {
        //n = cast(ProcessName)resolve(n);
        /*foreach(c;children) {
            if (c.name.matches(n)) {
              return c;
            }
        }*/
      synchronized(this) {
        auto c = children.filter!(x=>x.name.matches(n));
        if(!c.empty) return c.front;
      }
      return null;
    }
    auto findMatchingChildren(ProcessName.Caps c) {
      synchronized(this) {
        return children.filter!(n=>c.matches(n.name));
      }
    }

    MobileAmbient getLocalAmbient() {
        auto ma = cast(MobileAmbient)this;
        if(ma !is null) return ma;
        //auto p = parent;
        //while(p.parent !is null && cast(MobileAmbient)p is null) p = p.parent;
        synchronized(this) {
          if(parent is null) return null;
          return parent.getLocalAmbient;
        }
    }
    MobileAmbient getParentAmbient() {
      auto a = getLocalAmbient;
      if(a is null) return null;
      auto p = a.parent;
      if(p is null) return null;
      return p.getLocalAmbient();
    }
    HostAmbient getHostAmbient() {
        auto ha = cast(HostAmbient)this;
        if(ha !is null) return ha;
        synchronized(this) {
          if(parent is null) return null;
          return parent.getHostAmbient;
        }
    }

    //void enter(MobileProcess) { }
    //void exit(MobileProcess) { }
    void _enter(ProcessName n) { }
    void _exit(ProcessName n) { }
    void enter_(ProcessName n) { }
    void exit_(ProcessName n) { }
    void in_(ProcessName n) { }
    void out_(ProcessName n) { }
    void _in(ProcessName n) { }
    void _out(ProcessName n) { }

};

class NullProcess : MobileProcess {
    override bool cleanup() {
        parent.movingOut(this);
        return false;
    }
    /* override Tag[] evolutions() {
        return [];
    } */
    this(TypedProcess p) {
      _domain = new NullProcessDomain(this);
      super(p);
    }
};

class ComposedProcess : MobileProcess {
    override bool cleanup() {
        auto p = parent;
        if(p !is null) {
            p.movingOut(this);
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
    this(TypedProcess p) {
      _domain = new ComposedProcessDomain(this);
      super(p);
    }
};

/*
class CapsProcess : MobileProcess {
    ProcessName.Caps cap;
    this(ProcessName.Caps c) { cap=c; }
    override bool cleanup() {
        auto p = getParentAmbient();
        if(p !is null) {
            parent.movingOut(this);
            getLocalAmbient.caps ~= cap;
            return false;
        }
        return true;
    }
};
*/
/*class MatchParentNameProcess (T : ProcessName.Caps) : MobileProcess {
    ProcessName match;
    Action action;
    this(ProcessName n,Action a) { match=n; action=a; }
    override bool cleanup() {
        /* evol = []; * /
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
};*/

class RestrictionProcess : MobileProcess {
    //bool restricted;
    //Capability restrictedName;
    override bool cleanup() {
        if(domain.isRestricted) return true;
        if(super.cleanup == false) return false;
        //localDomain.restrict();
        debug(Process) {
          sharedLog.info("removing restriction");
        }

        auto p = parent;
        if(p !is null) {
            p.movingOut(this);
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
    this(TypedProcess p,const(Name) r) {
      _domain = new RestrictedProcessDomain(this,r);
      super(p);
    }
};
class BindingProcess : MobileProcess {
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.bind();
        //parent.movingOut(this);
        return true;
    }
    this(TypedProcess p,const(Name) n,Capability v) {
      _domain = new BindingProcessDomain(this,n,v);
      super(p);
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

class ReplicationProcess : MobileProcess {
  this(TypedProcess p) {
    _domain = new ReplicationProcessDomain(this);
    super(p);
  }
}

class NestedProcess : MobileProcess {
  this(TypedProcess p) {
    _domain = new TypedProcessDomain(this);
    super(p);
  }
}


class CapProcess : MobileProcess {
  ProcessName.Caps cap;
  this(TypedProcess p,ProcessName.Caps o) {
    _domain = new UntypedProcessDomain(this);
    this.cap = o;
    super(p);
  }
  override bool cleanup() {
    if(domain.isRestricted) return true;
    if(super.cleanup == false) return false;

    auto p = parent;
    if(p !is null) {
        getLocalAmbient.caps ~= cap;

        p.movingOut(this);
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
