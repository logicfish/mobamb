module mobamb.amb.ambient;

private import std.traits,
    std.algorithm,
    std.variant;

version(unittest) {
    import std.stdio;
};

private import mobamb.amb.domain;
private import mobamb.amb.tag;
private import mobamb.amb.names;
private import mobamb.amb.types;
private import mobamb.amb.host;


class MobileAmbient : PIProcess {
    ProcessName.Caps[] caps;
    //ProcessName.Caps[] coCaps;

    this(MobileProcess p=null, ProcessName n = new ProcessName) {
        this.name = n;
        if(p !is null)p.movingIn(this);
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

    protected void eachChild(F : bool delegate (MobileAmbient a,Name n))() {
      // check each child for in caps to the process n
      foreach(a;children.filter!(x=>cast(MobileAmbient)x !is null)) {
        foreach(c ; (cast(MobileAmbient)a).caps.filter!(x=>cast(ProcessName.In)x !is null && x.matches(n))) {
            if(F(c,n)is false) return;
        }
      }
    }
    /*protected void enclosingTags() {
      foreach(c ; caps.filter!(x=>cast(ProcessName.Out)x !is null && x.matches(getLocalAmbient.getName))) {
        if(c.matches(getLocalAmbient.getName)) {
          // create the "out" tag add to our tags
          return;
        }
       }
    }
    protected void removeSiblingTags(Name n) {
      // a process has left - remove any tags in our child processes that match.
      foreach(a;children.filter!(x=>cast(MobileAmbient)x !is null)) {
        foreach(t ; a.evol.filter!(x=>cast(ProcessName.In)x.lemma !is null && x.lemma.matches(n))) {
            // remove tag t
        }
      }
    }

    void deleteTag(Tag t) {
      evol = evol.remove!(x=>x is t);
    }*/
    void moveOut(Capability _c,MobileAmbient p) {
        auto c = cast(ProcessName.Caps)_c;
        assert(p !is this);
        assert(c !is null);
        if(p is null || p !is parent || p.parent is null) return;

        caps=caps.remove!(a => a is c);
        //p.parent.out_(this);
        //p._out(this);

        p.movingOut(this);
        p.parent.movingIn(this);

        c.action()(this);
    }

    void moveIn(ProcessName.Caps c,MobileAmbient p) {
        assert(p!=this);
        if(p is null || p==parent) return;

        caps=caps.remove!(f => f is c);

        parent.movingOut(this);
        p.in_(name);
        _in(p.name);
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
/*
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
*/

    //override void enter(MobileProcess p) { processCoCaps!(Name.Enter)(p);}
    //override void exit(MobileProcess p) { processCoCaps!(Name.Exit)(p); }
    /*override void _enter(ProcessName n) {
      processCoCaps!(ProcessName._Enter)(n);
      // check if we have 'out' caps for the new parent
      foreach(c;caps.filter!(x=>cast(ProcessName.Out)x !is null)) {
        if(c.matches(n)) {
          // create the out tag...
          if(localDomain.createTag!(TagPool.OutTag!())(c)) {
            return;
          }
        }
      }
      // check if we have 'in' caps for any sibling
      foreach(c;caps.filter!(x=>cast(ProcessName.In)x !is null)) {
        auto a = parent.findMatchingChildren(c);
        if(!a.empty) {
          // create the in tag...
          localDomain.createTag!(TagPool.InTag!())(c);
        }
      }
    }*/
    /* override void _exit(ProcessName n) {
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
*/
};

//static __gshared MobileAmbient masterAmbient;

//static this() {
//	if(masterAmbient is null) masterAmbient = new MobileAmbient;
//}

//static void runMasterAmbient() {
//	masterAmbient.runProcess;
//}

/*
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
*/

unittest {

    auto x = new HostAmbient;
    auto a = new MobileAmbient(x);
    auto b = new MobileAmbient(x);
    assert(!(b.parent == a));

    auto in_a = a.name().new In;
    assert(in_a.matches(a.name));
    assert(!in_a.matches(b.name));

    b.caps ~= in_a;

    writeln("X:=A[]|B[in A]");
    x.evaluate();
    assert(b.parent == a);
}

unittest {

  auto x = new HostAmbient;
    //x.coCaps = unsafeAmbientCaps;
    auto a = new MobileAmbient(x);
    //a.coCaps = unsafeAmbientCaps;
    auto b = new MobileAmbient(a);
    //b.coCaps = unsafeAmbientCaps;
    assert(b.parent == a);

    auto out_a = a.name().new Out();
    b.caps ~= out_a;

    writeln("X:=A[B[out A]]");

    x.evaluate();
    assert(b.parent != a);
    assert(b.parent == x);
}
/*
unittest {

  auto x = new HostAmbient;
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

  auto x = new HostAmbient;
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
*/
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
