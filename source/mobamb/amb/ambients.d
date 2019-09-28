module mobamb.amb.ambients;

private import std.traits,
    std.algorithm,
    std.variant;

version(unittest) {
    import std.stdio;
};

private import mobamb.amb.domain;
private import mobamb.amb.names;
private import mobamb.amb.tag;
private import mobamb.amb.host;

class MobileProcess : TypedProcess {
    ProcessName name;
    MobileProcess parent;
    MobileProcess[] children;
    Tag[] evol;

    ProcessName getName() { return name; }

    void movingOut(MobileProcess c) {
        //if(!(c in children)) return;
        if(c.parent!=this)return;
        //c.exit(p);
        exit_(c.getName);
        children = children.remove!(a => a == c);
        c._exit(getName);
        c.parent = null;
    }

    void movingIn(MobileProcess c) {
        if(c is null || c == this || c == parent) return;
        this.enter_(c.getName);
        children ~= c;
        c._enter(getName);
        c.parent = this;
        //c.enter(this);
    }

    override Tag[] evolutions() {
        if(localDomain.isRestricted) return [];
        Tag[] a = evol.dup;
        foreach(p;children) a~=p.evolutions().dup;
        return a;
    }

    override bool cleanup() {
        foreach(c;children) if(c.cleanup==false) return false;
        return true;
    }
    protected ProcessName findChildByName(ProcessName n) {
        n = cast(ProcessName)resolve(n);
        foreach(c;children) {
            if (c.getName.matches(n)) {
              return c.getName;
            }
        }
        return null;
    }
    protected auto findMatchingChildren(ProcessName.Caps c) {
        return children.filter!(n=>c.matches(n.name));
    }

    protected MobileAmbient getLocalAmbient() {
        auto ma = cast(MobileAmbient)this;
        if(ma !is null) return ma;
        auto p = parent;
        while(p.parent !is null && cast(MobileAmbient)p is null) p = p.parent;
        return cast(MobileAmbient)p;
    }
    protected MobileAmbient getParentAmbient() {
      return getLocalAmbient().parent.getLocalAmbient();
    }
    protected HostAmbient getHostAmbient() {
        auto ha = cast(HostAmbient)this;
        if(ha !is null) return ha;
        auto p = parent;
        while(p.parent !is null && cast(HostAmbient)p is null) p = p.parent;
        return cast(HostAmbient)p;
    }
    //void enter(MobileProcess) { }
    //void exit(MobileProcess) { }
    void _enter(ProcessName n) { }
    void _exit(ProcessName n) { }
    void enter_(ProcessName n) { }
    void exit_(ProcessName n) { }

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
                foreach(b;q.bindings) {
                    if (b.matches(n)) {
                        return new NameBinding(b);
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
    }
};

class NamedProcess : MobileProcess {
    Capability[ProcessName] bindings;

    alias OnInput = void delegate (Capability i);
    bool inputAvailable = false;
    Capability inputCap = null;
    OnInput onInput = null;

    void output(Capability o) {
        //if(inputAvailable) return ;
        if(onInput!=null) {
          onInput(o);
          onInput = null;
        }
        else {
          inputAvailable = true;
          inputCap = o;
        }
    }

    void input(OnInput o) {
        if(inputAvailable==true) {
          o(inputCap);
          inputCap=null;
          inputAvailable = false;
        } else {
          onInput = o;
        }
    }
};

class NullProcess : MobileProcess {
    override bool cleanup() {
        parent.movingOut(this);
        return false;
    }
    override Tag[] evolutions() {
        return [];
    }
};

class ComposedProcess : MobileProcess {
    override bool cleanup() {
        evol = [];
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
        evol = [];
        auto p = getParentAmbient();
        if(p !is null) {
            parent.movingOut(this);
            p.caps ~= cap;
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
        evol = [];
        auto p = getParentAmbient();
        if(p !is null) {
            ProcessName n = cast(ProcessName)resolve(match);
            if(p.getName.matches(n)) {
                auto c = m.new T(action);
                parent.movingOut(this);
                p.caps ~= c;
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
    bool restricted;
    Capability restrictedName;
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.restrict();
        parent.movingOut(this);
        return false;
    }
};
class Binding : MobileProcess {
    Capability boundName;
    Capability binding;
    override bool cleanup() {
        if(super.cleanup == false) return false;
        //localDomain.bind();
        parent.movingOut(this);
        return false;
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

class Replication : NamedProcess {

}

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
    }*/
};

class OutputProcess : IOProcess {
    Capability outputCap;
    this(Capability o) { this.outputCap = o; }
    override bool cleanup() {
        this.outputCap = resolve(this.outputCap);
        return super.cleanup;
    }
    override Tag[] evolutions() {
        if(cast(NamedProcess)parent is null) return [];
        auto p = cast(NamedProcess)parent;
        if(p.inputAvailable == true) return [];
        return [localDomain.createTag!((){
            p.movingOut(this);
            p.output(outputCap);
            return true;
        },delegate void(bool f){})()];
    }
};

class InputProcess : IOProcess {
    ProcessName inputName;
    MobileProcess action;
    this(ProcessName i,MobileProcess a) {
        this.inputName = i;
        this.action = a;
    }

    override Tag[] evolutions() {
        auto p = cast(NamedProcess)parent;
        //if(p.inputAvailable == false) return [];
        return [localDomain.createTag!({
            p.movingOut(this);
            p.input((i) {
                p.bindings[inputName]=i;
                p.movingIn(action);
            });
            return true;
        },delegate void(bool){})()];
    }
};

class MobileAmbient : NamedProcess {
    ProcessName.Caps[] caps;
    ProcessName.Caps[] coCaps;

    this(MobileProcess p=null, ProcessName n = new ProcessName) {
        if(p !is null)p.movingIn(this);
        this.name = n;
    }

/*
    override bool cleanup() {
        this.evol = [];
        //foreach(c;children)c.cleanup;
        if(super.cleanup==false)return false;
        auto source = this;
        auto target = cast(MobileAmbient)parent;
        //if(target is null) return this;
        foreach(c ; caps) {
            //if(cast(Name.Out)c !is null && c.matches(parent.name) && this.match_OutCaps(parent.name) && target.matchOut_Caps(name)) {
            if(target !is null && cast(ProcessName.Out)c !is null && c.matches(parent.getName)) {
                evol ~= localDomain.createTag({
                    source.moveOut(c,target);
                    return true;
                },delegate void(bool){});
            } else if(cast(ProcessName.In)c !is null) {
                auto _a = parent.findMatchingChildren(c);
                foreach(a;_a) {
                    //if(this.match_InCaps(a.name) && a.matchIn_Caps(name)) evol ~= { source.moveIn(c,a); };
                    auto amb = cast(MobileAmbient)a;
                    if(amb !is null && amb != this) {
                      evol ~= localDomain.createTag({
                        source.moveIn(c,amb);
                        return true;
                      },delegate void(bool){});
                    }
                }
            /*} else if(typeid(c) is typeid(Name.Open)) {
                auto _a = parent.findMatchingChildren(c,this);
                foreach(a;_a) {
                    evol ~= { a.open(c,this); };
                }* /
            }
        }
        return true;
    }*/

    //bool matchesCoCaps(AmbientName.Caps c) {
    //	return true;
    //}

    protected void siblingTags(Name n) {
      // check each child for in caps to the process n
      foreach(a;children) {
        foreach(c ; a.caps.filter!(x=>cast(ProcessName.In)x !is null && x.matches(n))) {
            // create the "in" tag... and add to the child...
        }
      }
    }
    protected void enclosingTags() {
      foreach(c ; caps.filter!(x=>cast(ProcessName.Out)x !is null && x.matches(localAmbient.getName)) {
        if(c.matches(getLocalAmbient.getName)) {
          // create the "out" tag add to our tags
          return;
        }
       }
    }
    protected void removeSiblingTags(Name n) {
      // a process has left - remove any tags in our child processes that match.
      foreach(a;children) {
        foreach(t ; a.tags.filter!(x=>cast(ProcessName.In)x.lemma !is null && x.lemma.matches(n))) {
            // remove tag t
        }
      }

    }
    protected void moveOut(ProcessName.Caps c,MobileAmbient p) {
        assert(p !is this);
        if(p is null || p !is parent || p.parent is null) return;

        caps=caps.remove!(a => a is c);
        //p.parent.out_(this);
        //p._out(this);

        p.movingOut(this);
        p.parent.movingIn(this);

        c.action()(this);
    }

    protected void moveIn(ProcessName.Caps c,MobileAmbient p) {
        assert(p!=this);
        if(p is null || p==parent) return;

        caps=caps.remove!(f => f is c);

        parent.movingOut(this);
        p.in_(getName);
        _in(p.getName);
        p.movingIn(this);

        c.action()(this);
    }

/*	protected void open(AmbientName.Caps c,MobileAmbient a) {
        assert(a!=this);
        auto p = parent;
        p.movingOut(this);
        p.caps ~= this.caps;
        p.children ~= this.children;
        //this.capabilities = [];
        //this.content = new Composition;
        a.caps=a.caps.remove!(f => f == c);
        c.action()(this);
    }*/

    protected bool match_OutCaps(ProcessName n) { return matchCoCaps!(ProcessName._Out)(n); }
    protected bool matchOut_Caps(ProcessName n) { return matchCoCaps!(ProcessName.Out_)(n);	}
    protected bool match_InCaps(ProcessName n) { return matchCoCaps!(ProcessName._In)(n);	}
    protected bool matchIn_Caps(ProcessName n) { return matchCoCaps!(ProcessName.In_)(n);	}
    protected bool matchCoCaps(C)(ProcessName n) {
        foreach(c;coCaps.filter!(f=>cast(C)f !is null)) if (c.matches(n)) return true;
        return false;
    }

    protected void processCoCaps(C)(ProcessName n) {
        foreach(c;coCaps.filter!(f=>cast(C)f !is null)) {
            //if(c.matches(n)) {
            //	//coCaps.remove(f => f == c);
            //	c.action()(this);
            //}
        }
    }


    //override void enter(MobileProcess p) { processCoCaps!(Name.Enter)(p);}
    //override void exit(MobileProcess p) { processCoCaps!(Name.Exit)(p); }
    override void _enter(ProcessName n) {
      processCoCaps!(ProcessName._Enter)(n);
      // check if we have 'out' caps for the new parent
      // check if we have 'in' caps for any sibling
    }
    override void _exit(ProcessName n) {
      processCoCaps!(ProcessName._Exit)(n);
      // remove all 'in' caps
    }
    override void enter_(ProcessName n) {
      processCoCaps!(ProcessName.Enter_)(n);
      // check children for matching "in" caps...
    }

    override void exit_(ProcessName n) {
      processCoCaps!(ProcessName.Exit_)(n);
      // remove matching "in" caps from child ambients
    }
    void in_(ProcessName n) { processCoCaps!(ProcessName.In_)(n); }
    void out_(ProcessName n) { processCoCaps!(ProcessName.Out_)(n); }
    void _in(ProcessName n) { processCoCaps!(ProcessName._In)(n); }
    void _out(ProcessName n) { processCoCaps!(ProcessName._Out)(n); }
    //void _open(MobileProcess p) { processCoCaps!Name._Open(p);}
    //void open_(MobileProcess p) { processCoCaps!Name.Open_(p); }

};

//static __gshared MobileAmbient masterAmbient;

//static this() {
//	if(masterAmbient is null) masterAmbient = new MobileAmbient;
//}

//static void runMasterAmbient() {
//	masterAmbient.runProcess;
//}

static Action makeAction(MobileProcess child) {
    return (p){ p.movingIn(child); };
}

static Action makeAction(ProcessName.Caps c) {
    return (p){ auto a = cast(MobileAmbient)p; if(a !is null) a.caps ~= c; };
}

static auto unsafeAmbientCaps() {
    static ProcessName.Caps[] unsafeDefaults = [
        WildcardName.wildcardName.new ProcessName._In(),
        WildcardName.wildcardName.new ProcessName.In_(),
        WildcardName.wildcardName.new ProcessName._Out(),
        WildcardName.wildcardName.new ProcessName.Out_(),
        WildcardName.wildcardName.new ProcessName._Enter(),
        WildcardName.wildcardName.new ProcessName.Enter_(),
        WildcardName.wildcardName.new ProcessName._Exit(),
        WildcardName.wildcardName.new ProcessName.Exit_(),
    ];
    return unsafeDefaults;
};


unittest {

    auto x = new MobileProcess;
    auto a = new MobileAmbient(x);
    auto b = new MobileAmbient(x);
    assert(!(b.parent == a));

    auto in_a = a.getName().new In;
    assert(in_a.matches(a.getName));
    assert(!in_a.matches(b.getName));

    b.caps ~= in_a;

    writeln("X:=A[]|B[in A]");
    x.runProcess();
    assert(b.parent == a);
}

unittest {

    auto x = new MobileProcess;
    //x.coCaps = unsafeAmbientCaps;
    auto a = new MobileAmbient(x);
    //a.coCaps = unsafeAmbientCaps;
    auto b = new MobileAmbient(a);
    //b.coCaps = unsafeAmbientCaps;
    assert(b.parent == a);

    auto out_a = a.getName().new Out();
    b.caps ~= out_a;

    writeln("X:=A[B[out A]]");

    x.runProcess();
    assert(b.parent != a);
    assert(b.parent == x);
}

unittest {

    auto x = new MobileProcess;
    auto a = new MobileAmbient(x);
    auto b = new MobileAmbient(x);
    assert(!(b.parent == a));

    auto out_a = a.getName().new Out;
    assert(out_a.matches(a.getName));
    assert(!out_a.matches(b.getName));

    b.caps ~= out_a;

    auto in_a = a.getName().new In;
    assert(in_a.matches(a.getName));
    assert(!in_a.matches(b.getName));

    b.caps ~= in_a;

    writeln("X:=A[]|B[in A|out A]");

    x.runProcess();
    assert(b.parent != a);
}

unittest {

    auto x = new MobileProcess;
    auto a = new MobileAmbient(x);
    auto b = new MobileAmbient(x);
    assert(!(b.parent == a));

    auto out_a = a.getName().new Out;
    assert(out_a.matches(a.getName));
    assert(!out_a.matches(b.getName));

    auto in_a = a.getName().new In(makeAction(out_a));
    assert(in_a.matches(a.getName));
    assert(!in_a.matches(b.getName));

    b.caps ~= in_a;

    x.runProcess();
    //assert(b.parent == a);
    assert(b.parent != a);
}

/*
unittest {

    auto x = new MobileAmbient;
    auto a = new MobileAmbient(x);
    auto b = new MobileAmbient(x);
    assert(b.parent != a);

    auto open_a = a.getName().new Open({});
    b.caps ~= open_a;

    x.runProcess();
    assert(b.parent == x);
    assert(a.parent is null);
}
*/
