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

abstract class MobileProcess(DomainType : ProcessDomain)
: TypedProcess!DomainType {
    ProcessName _name;
    //Tag[] evol;
    DomainType _domain;

    alias domain this;

    //this() {
    //  _domain = new MobileProcessDomain(this);
    //}

    this(Process p,ProcessName n) {
      _name = n;
      if(p !is null) {
          debug(Process) {
            sharedLog.info("MobileProcess:",n," << ",p.name);
          }
          assert(p.domain);
          p.domain.movingIn(domain);
      }
    }

    @property {
      inout(ProcessName) name() @safe nothrow pure inout {
        return _name;
      }
      inout(DomainType) domain() @safe nothrow pure inout {
        return _domain;
      }
      inout(Process[]) children() @safe nothrow pure inout {
        return domain.children;
      }
      auto children(Process[] c) @safe nothrow pure {
        domain.children = c;
        return this;
      }
    }

    override bool cleanup() {
      synchronized(domain) {
        foreach(c;children) if(c.cleanup==false) return false;
      }
      return true;
    }

    override bool evaluateAll() {
        debug(Process) {
          sharedLog.info("evaluateAll");
        }
        if(domain.isRestricted) return false;
        synchronized(domain) {
          foreach(c;children) {
            debug(Process) {
              sharedLog.info("evaluateAll:",c.name);
            }
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

    //void enter(MobileProcess) { }
    //void exit(MobileProcess) { }
    void _enter(Name n) { }
    void _exit(Name n) { }
    void enter_(Name n) { }
    void exit_(Name n) { }
    void in_(Name n) { }
    void out_(Name n) { }
    void _in(Name n) { }
    void _out(Name n) { }

};

final class NullProcess : MobileProcess!NullProcessDomain {
    override bool cleanup() {
        domain.parent.movingOut(domain);
        return false;
    }
    /* override Tag[] evolutions() {
        return [];
    } */
    this(Process p) {
      _domain = new NullProcessDomain(this);
      super(p,NilName.nilName);
    }
};

final class ComposedProcess : MobileProcess!ComposedProcessDomain {
    override bool cleanup() {
        auto p = domain.parent;
        if(p !is null) {
            foreach(c;children) {
                domain.movingOut(c.domain);
                p.movingIn(c.domain);
            }
            p.movingOut(domain);
            return false;
        }
        return true;
    }
    this(Process p) {
      _domain = new ComposedProcessDomain(this);
      super(p,NilName.nilName);
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

final class RestrictionProcess : MobileProcess!RestrictedProcessDomain {
    override bool cleanup() {
        debug(Process) {
          sharedLog.info("restriction cleanup");
        }
        if(super.cleanup == false) return false;
        //auto r = (cast(RestrictedProcessDomain)domain).restriction;
        auto r = domain.restriction;

        //if(domain.isRestricted) return true;
        if(!domain.getLocalAmbient.domain.isBound(r)) return true;

        //localDomain.restrict();
        debug(Process) {
          sharedLog.info("removing restriction");
        }

        auto p = domain.parent;
        if(p !is null) {
            p.movingOut(domain);
            foreach(c;children) {
                if(p !is null) {
                    domain.movingOut(c.domain);
                    p.movingIn(c.domain);
                }
            }
            return false;
        }
        return true;
    }
    this(Process p,const(Name) r) {
      _domain = new RestrictedProcessDomain(this,r);
      super(p,NilName.nilName);
    }
};
final class BindingProcess : MobileProcess!BindingProcessDomain {
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.bind();
        //parent.movingOut(this);
        return true;
    }
    this(Process p,const(Name) n,Capability v) {
      _domain = new BindingProcessDomain(this,n,v);
      super(p,NilName.nilName);
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

final class ReplicationProcess : MobileProcess!ReplicationProcessDomain {
  this(Process p) {
    _domain = new ReplicationProcessDomain(this);
    super(p,NilName.nilName);
  }
}

final class NestedProcess : MobileProcess!TypedProcessDomain {
  this(Process p) {
    _domain = new TypedProcessDomain(this);
    super(p,NilName.nilName);
  }
}


final class CapProcess : MobileProcess!UntypedProcessDomain {
  ProcessName.Caps cap;
  this(Process p,ProcessName.Caps o) {
    _domain = new UntypedProcessDomain(this);
    this.cap = o;
    super(p,NilName.nilName);
  }
  override bool cleanup() {
    if(domain.isRestricted) return true;
    if(super.cleanup == false) return false;

    auto p = domain.parent;
    if(p !is null) {
        auto amb = cast(MobileAmbient)domain.getLocalAmbient;
        amb.caps ~= cap;

        p.movingOut(domain);
        foreach(c;children) {
            domain.movingOut(c.domain);
            p.movingIn(c.domain);
        }
        return false;
    }
    return true;
  }
};
