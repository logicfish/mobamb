module mobamb.amb.ambient;

private import std.traits,
    std.algorithm,
    std.variant;

debug {
    import std.experimental.logger,
        std.conv;
}

private import mobamb.amb.domain;
private import mobamb.amb.names;
private import mobamb.amb.types;
private import mobamb.amb.process;
private import mobamb.amb.host;


class MobileAmbient : MobileProcess!Location {
    ProcessName.Caps[] caps;

    this(Process p, ProcessName n) {
      this._domain = new Location(this);
      super(p,n);
    }
    MobileAmbient getLocalAmbient() {
      return cast(MobileAmbient)domain.getLocalAmbient;
    }
    MobileAmbient getParentAmbient() {
      return cast(MobileAmbient)domain.getParentAmbient;
    }
    HostAmbient getHostAmbient() {
      return cast(HostAmbient)domain.getHostAmbient;
    }
    alias parent = getParentAmbient;

    bool evalPIOutputs(T)(T _outputs,MobileAmbient amb) {
      debug(Ambient) {
          sharedLog.info("evaluatePIOutputs:",_outputs.empty);
      }
      if(_outputs.empty) return false;

      auto _inputs = caps.filter!(x=>cast(ProcessName.Input)x !is null);
      debug(Ambient) {
          sharedLog.info("_inputs:",_inputs.empty);
      }

      foreach(_o;_outputs) {
        auto _match = _inputs.filter!(x=>_o.matches(x.name));
        if(!_match.empty) {
          debug(Ambient) {
              sharedLog.info("match local");
          }
          if(amb.getHostAmbient.createTag!"output"(_o,amb,this)) {
            if(getHostAmbient.createTag!"input"(_match.front,this,amb))
              return true;
          }
        }

        auto _inputs_parent = parent.caps.filter!(x=>cast(ProcessName.InputChildren)x !is null
              && _o.matches(x.name));

        if(!_inputs_parent.empty) {
            debug(Ambient) {
              sharedLog.info("match parent ",parent.name);
            }
            if(amb.getHostAmbient.createTag!"output"(_o,amb,parent)) {
              if(getHostAmbient.createTag!"input"(_inputs_parent.front,parent,amb))
                return true;
            }
        }

        foreach(_c;children.filter!(x=>cast(MobileAmbient)x !is null)) {
          debug(Ambient) {
              sharedLog.info("child: ",_c.name);
          }
          auto c = cast(MobileAmbient)_c;
          auto _inputs_children = c.caps.filter!(x=>cast(ProcessName.InputParent)x !is null && _o.matches(x.name));
          if(!_inputs_children.empty) {
            debug(Ambient) {
              sharedLog.info("match child ",c.name);
            }
            if(getHostAmbient.createTag!"output"(_o,amb,c)) {
              if(c.getHostAmbient.createTag!"input"(_inputs_children.front,c,amb))
                return true;
            }
          }
        }
      }
      return false;
    }
    bool evaluatePI() {
      debug(Ambient) {
          sharedLog.info("evaluatePI");
      }

        if(evalPIOutputs(
            caps.filter!(x=>cast(ProcessName.Output)x !is null),this
          )) return true;

        /*debug(Ambient) {
            sharedLog.info("evaluatePI->parent:",parent.name);
        }*/
        if(parent !is null && evalPIOutputs(
            parent.caps.filter!(x=>cast(ProcessName.OutputChildren)x !is null),parent
          )) return true;

        foreach(_c;children.filter!(x=>cast(MobileAmbient)x !is null)) {
          auto c = cast(MobileAmbient)_c;
          //_outputs ~= c.caps.filter!(x=>cast(ProcessName.OutputParent)x !is null);
          if(evalPIOutputs(
              c.caps.filter!(x=>cast(ProcessName.OutputParent)x !is null),c
            )) return true;
        }
        return false;

    }
    /**
        Evaluate all capabilities including children.
        Return true if any match was found.
        Evaluation halts when a match is found. Children are
        evaluated first.
    **/
    override bool evaluateAll() {
      debug(Ambient) {
          sharedLog.info("evaluateAll");
      }
      assert(getHostAmbient);

      if(domain.isRestricted) return false;

      auto __d = ProcessDomain.localDomain(domain);
      scope(exit) {
        debug(Ambient) {
            sharedLog.info("restore domain ",__d);
        }
        ProcessDomain.localDomain(__d);
      }

      bool res = evaluatePI();

      debug(Ambient) {
          sharedLog.info("evaluateAll done pi:",res);
      }

      if(super.evaluateAll) return true;

      auto p = getParentAmbient;

      if(p !is null) {
        auto pa = p.getParentAmbient;
        if(pa !is null) {
          debug(Ambient) {
              sharedLog.info("evaluateAll checking out:",pa.name," ",name);
          }

          foreach(c;caps.filter!(x=>cast(ProcessName.Out)x !is null && x.matches(p.name))) {
            if(getHostAmbient.createTag!"out"(c,this,pa))
              return true;
          }
        }
        foreach(c;caps.filter!(x=>cast(ProcessName.In)x !is null)) {
          auto _a = p.domain.findMatchingChildren(c);
          foreach(a;_a) {
              debug(Ambient) {
                sharedLog.info("evaluateAll checking in: ",c.name," -> ",a.name);
              }
              auto amb = cast(MobileAmbient)a;
              if(amb !is null && amb != this) {
                  if(getHostAmbient.createTag!"in"(c,this,amb))
                    return true;
              }
          }
        }
      }

      return res;
    }

    //bool matchesCoCaps(AmbientName.Caps c) {
    //	return true;
    //}

    /* //protected void eachChild(F : bool delegate (MobileAmbient a,Name n))() {
    protected void eachChild(alias F)(Name n) {
      // check each child for in caps to the process n
      foreach(a;children.filter!(x=>cast(MobileAmbient)x !is null)) {
        foreach(c ; (cast(MobileAmbient)a).caps.filter!(x=>cast(ProcessName.In)x !is null && x.matches(n))) {
            if(F(c,n)is false) return;
        }
      }
    } */

    /**
    Exerting capability _c (`out n`) the process is moving out of it's parent
    to a new parent p, either the parent's parent, or the master ambient.
    **/
    /* void moveOut(Capability _c,MobileAmbient p) {
        debug(Ambient) {
            sharedLog.info("moveOut:",name," ",_c," >> ",p.name.to!string);
        }
        auto c = cast(ProcessName.Caps)_c;
        assert(p !is this);
        assert(c !is null);
        assert(p !is null);

        //assert(p is parent);
        assert(p is parent || p is getMasterAmbient);

        //if(p is null || p !is parent || p.parent is null) return;
        //if(p is null || p !is parent) return;

        caps=caps.remove!(a => a is c);

        auto __d = ProcessDomain.localDomain(domain);
        scope(exit) {
          debug(Ambient) {
              sharedLog.info("restore domain ",__d);
          }
          ProcessDomain.localDomain(__d);
        }

        //p.domain.movingOut(this);
        //p.domain.parent.movingIn(this);
        domain.parent.movingOut(domain);
        p.domain.movingIn(domain);

//        c.action()(this);

        p.out_(this.name);
        _out(this.name);
    }

    void moveIn(ProcessName.Caps c,MobileAmbient p) {
        debug(Ambient) {
            sharedLog.info("moveIn:",name," >> ",p.name.to!string);
        }
        assert(p!=this);
        //auto parent = cast(MobileAmbient)domain.getParentAmbient;

        if(p is null || p==parent) return;

        auto __d = ProcessDomain.localDomain(domain);
        scope(exit) {
          debug(Ambient) {
              sharedLog.info("restore domain ",__d);
          }
          ProcessDomain.localDomain(__d);
        }

        //parent.domain.movingOut(this);
        //p.domain.movingIn(this);
        domain.parent.movingOut(domain);
        p.domain.movingIn(domain);

        caps = caps.remove!(f => f is c);
//        c.action()(this);

        p.in_(name);
        _in(p.name);
    } */

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
    /*
    Entering a new parent
    */
    override void _enter(Name n) {
      /* debug(Ambient) {
        sharedLog.info("_enter:",n," ",caps.length);
      }*/
    }
    override void _exit(Name n) {
      //processCoCaps!(ProcessName._Exit)(n);
    }
    override void enter_(Name n) {
      //processCoCaps!(ProcessName.Enter_)(n);
    }

    override void exit_(Name n) {
      //processCoCaps!(ProcessName.Exit_)(n);
      // remove matching "in" caps from child ambients
    }
    /**
    A new ambient has entered.
    **/
    override void in_(Name n) {
      debug(Ambient) {
        sharedLog.info("in_:",n," ",caps.length);
      }
      // check children for matching "in" caps...
        //processCoCaps!(ProcessName.In_)(n);
        auto _ta = domain.findChildByName(n);
        if(_ta is null) return;

        auto ta = cast(MobileAmbient)_ta.domain.getLocalAmbient();
        if(ta is null) return;

        foreach(_a;children.filter!(x=>cast(MobileAmbient)x !is null)) {
          auto a = cast(MobileAmbient) _a;
          debug(Ambient) {
            sharedLog.info("in_:.....................",ta.name);
            sharedLog.info(ta.caps);
          }

          foreach(c;a.caps.filter!(x=>cast(ProcessName.In)x !is null && x.matches(ta.name))) {
            debug(Ambient) {
              sharedLog.info("in_:-> ",ta.name," ",caps.length);
            }
            //a.getHostAmbient.createTag!(TagPool.InTag!())(c,a);
            if(ta.getHostAmbient.createTag!("in")(c,ta,a))return;
          }
        }
    }
    /**
    A new ambient has left.
    **/
    override void out_(Name n) {
        //processCoCaps!(ProcessName.Out_)(n);
    }
    /**
    Entered a new parent.
    **/
    override void _in(Name n) {
        //processCoCaps!(ProcessName._In)(n);
        debug(Ambient) {
          sharedLog.info("_in:",name," <-- ",n);
        }
        // check if we have 'out' caps for the new parent
        foreach(c;caps.filter!(x=>cast(ProcessName.Out)x !is null && x.matches(n))) {
            debug(Ambient) {
              sharedLog.info("_in -> out:",n);
            }
            // create the out tag...
            //if(getHostAmbient.createTag!(TagPool.OutTag!())(c,this)) {
            assert(getParentAmbient);
            auto p = getParentAmbient.getParentAmbient;
            assert(p);
            if(getHostAmbient.createTag!("out")(c,this,p)) {
              return;
            }
        }
        // check if we have 'in' caps for any sibling
        foreach(c;caps.filter!(x=>cast(ProcessName.In)x !is null)) {
          auto a = getParentAmbient.domain.findMatchingChildren(c);
          //auto a = getParentAmbient.domain.children.filter!(x=>c.matches(x.name));
            // create the in tag...
            //getHostAmbient.createTag!(TagPool.InTag!())(c,this);
          foreach(_amb;a) {
              auto amb = cast(MobileAmbient)_amb;
              debug(Ambient) {
                  sharedLog.info("_in -> in: ",amb.name," ",c);
              }
              amb.getHostAmbient.createTag!("in")(c,this,amb);
          }
        }
    }
    /**
    Left a parent.
    **/
    override void _out(Name n) {
        //processCoCaps!(ProcessName._Out)(n);
    }
    //void _open(MobileProcess p) { processCoCaps!Name._Open(p);}
    //void open_(MobileProcess p) { processCoCaps!Name.Open_(p); }

};

template mobileAmbient() {
  auto mobileAmbient(Process p, ProcessName n) {
    return new MobileAmbient(p,n);
  }
}

private static __gshared MobileAmbient _masterAmbient;
private static bool masterAmbInstantiated = false;

final class MasterAmbientName : ProcessName {
  override {
    /* @property
    inout(Name) name() @safe nothrow pure inout {
      return null;
    } */
    /* @property
    inout(Domain) domain() @safe nothrow pure inout {
      return _domain;
    } */
    @property
    string capType() @safe nothrow pure const {
      return "master";
    }
    bool matches(const(Name) n) const {
      return false;
    }
  }
  Domain _domain;
}

public static auto getMasterAmbient() {
  synchronized(MobileAmbient.classinfo) {
    if(!masterAmbInstantiated) {
      if(_masterAmbient is null) {
        auto n = new MasterAmbientName;
        _masterAmbient = new MobileAmbient(null,n);
        masterAmbInstantiated = true;
      }
    }
    return _masterAmbient;
  }
}

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
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto comp = new ComposedProcess(x);

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");

    auto a = new MobileAmbient(comp,A);
    auto b = new MobileAmbient(comp,B);
    assert(!(b.parent == a));

    auto in_a = A.new In;
    assert(in_a.matches(a.name));
    assert(!in_a.matches(b.name));

    b.caps ~= in_a;

    sharedLog.info("X:=A[]|B[in A]");

    x.evaluate();
    assert(b.parent == a);
}

unittest {
    sharedLog.info("X:=A[]|(v n)B[in n]{n/A}");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto a = new MobileAmbient(x,A);

    auto B = new NameLiteral("B");
    auto n = new NameLiteral("n");

    auto n_a = new BindingProcess(x,n,A);
    auto r_n = new RestrictionProcess(n_a,n);

    auto b = new MobileAmbient(n_a,B);

    auto in_n = n.new In;
    b.caps ~= in_n;

    x.evaluate();
    assert(b.parent == a);
}

unittest {
  // mobility does not happen because n is restricted, even when bound
  // in a sub-process.
    sharedLog.info("X:=A[]|(v n)(B[in n]{n/A})");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto comp = new ComposedProcess(x);

    auto A = new NameLiteral("A");
    auto a = new MobileAmbient(comp,A);

    auto B = new NameLiteral("B");
    auto n = new NameLiteral("n");

    auto r_n = new RestrictionProcess(comp,n);
    auto n_a = new BindingProcess(r_n,n,A);

    auto b = new MobileAmbient(n_a,B);

    auto in_n = n.new In;
    b.caps ~= in_n;

    x.evaluate();
    sharedLog.info("Eval done.");
    assert(r_n.domain.isRestricted);
    assert(n_a.domain.isRestricted);
    assert(b.parent != a);
}

unittest {
  // create a restriction and remove it by a pi input.
  // also rebind the input m/n to match the ambient name A.
  // mobility does happen because n is unrestricted, and bound
  // in a sub-process to A.
    sharedLog.info("X:=A[]|(n).(v n)(B[in n]{m/A})|<m>");

    auto X = new NameLiteral("X");
    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");
    auto n = new NameLiteral("n");
    auto m = new NameLiteral("m");

    //auto _a = new NameLiteral("a");

    auto x = new HostAmbient(getMasterAmbient,X);
    scope(exit)x.close;

    auto a = new MobileAmbient(x,A);

    auto output_m = DefaultName.defaultName.new Output(m);
    //auto out_a = A.new Out(output_n);
    //a.caps ~= out_a;
    x.caps ~= output_m;

    auto r_n = new RestrictionProcess(getMasterAmbient,n);
    auto n_a = new BindingProcess(r_n,m,A);

    auto b = new MobileAmbient(n_a,B);
    auto input_n = DefaultName.defaultName.new Input(n,makeAction(r_n));
    //auto p_input_m = new CapProcess(x,input_m);
    x.caps ~= input_n;

    auto in_n = n.new In;
    b.caps ~= in_n;

    x.evaluate();
    //assert(r_n.domain.isRestricted);
    //assert(n_a.domain.isRestricted);
    //assert(!b.domain.isRestricted);
    assert(b.parent == a);
}

unittest {
  // create a restriction and remove it by a pi input.
  // also rebind the input m/n to match the ambient name A.
  // mobility does happen because n is unrestricted, and bound
  // in a sub-process to A.
    sharedLog.info("X:=A[]|(n)|(v n)(B[in n]{m/A})|<m>");

    auto X = new NameLiteral("X");
    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");
    auto n = new NameLiteral("n");
    auto m = new NameLiteral("m");

    auto x = new HostAmbient(getMasterAmbient,X);
    scope(exit)x.close;

    auto a = new MobileAmbient(x,A);

    auto output_m = DefaultName.defaultName.new Output(m);
    x.caps ~= output_m;

    auto r_n = new RestrictionProcess(x,n);
    auto n_a = new BindingProcess(r_n,m,A);

    auto b = new MobileAmbient(n_a,B);
    auto input_n = DefaultName.defaultName.new Input(n);
    x.caps ~= input_n;

    auto in_n = n.new In;
    b.caps ~= in_n;

    x.evaluate();
    //assert(r_n.domain.isRestricted);
    //assert(n_a.domain.isRestricted);
    //assert(!b.domain.isRestricted);
    assert(b.parent == a);
}

unittest {
  sharedLog.info("X:=A[B[out A]]  <---------------");

  auto X = new NameLiteral("X");
  auto x = new HostAmbient(null,X);
  scope(exit)x.close;

  auto A = new NameLiteral("A");
  auto B = new NameLiteral("B");

    //x.coCaps = unsafeAmbientCaps;
    auto a = new MobileAmbient(x,A);
    //a.coCaps = unsafeAmbientCaps;
    auto b = new MobileAmbient(a,B);
    //b.coCaps = unsafeAmbientCaps;
    assert(b.parent == a);

    auto out_a = A.new Out();
    b.caps ~= out_a;


    x.evaluate();
    assert(b.parent != a);
    assert(b.parent == x);
}
unittest {
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");

    auto a = new MobileAmbient(x,A);
    auto b = new MobileAmbient(x,B);
    assert(!(b.parent == a));

    auto in_a = A.new In;
    assert(in_a.matches(a.name));
    assert(!in_a.matches(b.name));

    b.caps ~= in_a;

    auto out_a = A.new Out;
    assert(out_a.matches(a.name));

    b.caps ~= out_a;

    sharedLog.info("X:=A[]|B[in A|out A]");
    x.evaluate();
    assert(b.parent == x);
}
unittest {
  sharedLog.info("X:=A[]|B[in A.out A]");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");

    auto a = new MobileAmbient(x,A);
    auto b = new MobileAmbient(x,B);
    assert(!(b.parent == a));

    auto out_a = A.new Out;
    assert(out_a.matches(a.name));

    auto in_a = A.new In(makeAction(out_a));
    assert(in_a.matches(a.name));
    assert(!in_a.matches(b.name));

    b.caps ~= in_a;

    x.evaluate();
    sharedLog.info("b.parent: ",b.parent.name);

    assert(b.parent.name == x.name);
    //assert(b.caps.length == 0);
}
unittest {
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");
    auto C = new NameLiteral("C");

    auto a = new MobileAmbient(x,A);
    auto b = new MobileAmbient(a,B);
    auto c = new MobileAmbient(x,C);

    auto in_c = C.new In;
    auto out_a = A.new Out(makeAction(in_c));

    b.caps ~= out_a;
    sharedLog.info("=======================================================");
    sharedLog.info(b.caps);

    sharedLog.info("X:=A[B[out A.in C]]|C[]");
    x.evaluate();
    //assert(b.caps.length == 0);
    sharedLog.info(b.parent.name);
    sharedLog.info(b.caps);
    //assert(b.getParentAmbient is x);
    //assert(b.getParentAmbient is c);

    assert(b.parent.name == C);
}

unittest {
  sharedLog.info("X:=A[B[out A.in C]|C[out A]]");

  auto X = new NameLiteral("X");
  auto x = new HostAmbient(null,X);
  scope(exit)x.close;

  auto A = new NameLiteral("A");
  auto B = new NameLiteral("B");
  auto C = new NameLiteral("C");

  auto a = new MobileAmbient(x,A);
  auto b = new MobileAmbient(a,B);
  auto c = new MobileAmbient(a,C);

  auto in_c = C.new In;
  auto b_out_a = A.new Out(makeAction(in_c));
  b.caps ~= b_out_a;

  auto c_out_a = A.new Out();
  c.caps ~= c_out_a;

  x.evaluate();

  sharedLog.info(b.parent.name);
  sharedLog.info(b.caps);
  //assert(b.parent.name == C);
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

// IO Tests

unittest {
  sharedLog.info("X:=A[(n)|<m>]");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    //auto B = new NameLiteral("B");

    auto a = new MobileAmbient(x,A);
    //auto b = new MobileAmbient(x,B);
    //assert(!(b.parent == a));

    auto n = new NameLiteral("n");
    auto input_a = A.new Input(n); // A(n) input on channel A to name n.
    assert(input_a.matches(A));
    //assert(!in_a.matches(b.name));

    a.caps ~= input_a;

    auto m = new NameLiteral("m");
    auto output_a = A.new Output(m); // A<n> output m on channel A.
    a.caps ~= output_a;

    x.evaluate();
    //writeln(b.parent.name);
    //assert(b.parent == a);
    assert(a.domain.isBound(n));
    assert(a.domain.binding(n) == m);
}

unittest {
  sharedLog.info("X:=A[<n>|(m)]");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    //auto B = new NameLiteral("B");

    auto a = new MobileAmbient(x,A);
    //auto b = new MobileAmbient(x,B);
    //assert(!(b.parent == a));

    auto n = new NameLiteral("n");
    auto output_a = A.new Output(n); // A(n) input on channel A to name n.
    assert(output_a.matches(A));
    //assert(!in_a.matches(b.name));

    a.caps ~= output_a;

    auto m = new NameLiteral("m");
    auto input_a = A.new Input(m); // A<n> output m on channel A.
    a.caps ~= input_a;

    x.evaluate();
    //writeln(b.parent.name);
    //assert(b.parent == a);
    assert(a.domain.isBound(m));
    assert(a.domain.binding(m) == n);
}

unittest {
  sharedLog.info("X:=A[<B>|(m).in m]|B[]");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");

    auto a = new MobileAmbient(x,A);
    auto b = new MobileAmbient(x,B);
    //assert(!(b.parent == a));

    //auto n = new NameLiteral("n");
    auto output_a = A.new Output(B); // A<B> output on channel A name B.
    assert(output_a.matches(A));
    //assert(!in_a.matches(b.name));

    a.caps ~= output_a;

    auto m = new NameLiteral("m");
    auto in_m = m.new In;
    auto input_a = A.new Input(m,makeAction(in_m)); // A(m) input m from channel A.
    a.caps ~= input_a;

    x.evaluate();
    //writeln(b.parent.name);
    //assert(b.parent == a);
    //assert(a.domain.isBound(m));
    //assert(a.domain.binding(m) == n);
    assert(a.parent == b);
}
unittest {
    sharedLog.info("X:=A[C[<B>.out A|(m).in m]]|B[]");
    auto X = new NameLiteral("X");
    auto x = new HostAmbient(null,X);
    scope(exit)x.close;

    auto A = new NameLiteral("A");
    auto B = new NameLiteral("B");
    auto C = new NameLiteral("C");

    auto a = new MobileAmbient(x,A);
    auto b = new MobileAmbient(x,B);
    auto c = new MobileAmbient(a,C);

    //auto n = new NameLiteral("n");
    auto out_a = makeAction(A.new Out);
    auto output_c = DefaultName.defaultName.new Output(B,out_a); // A<B> output on channel A name B.

    c.caps ~= output_c;

    auto m = new NameLiteral("m");
    auto in_m = makeAction(m.new In);
    auto input_c = DefaultName.defaultName.new Input(m,in_m); // A(m) input m from channel A.
    c.caps ~= input_c;

    x.evaluate();

    sharedLog.info("a.parent " ,a.parent.name);
    sharedLog.info("b.parent " ,b.parent.name);
    sharedLog.info("c.parent " ,c.parent.name);

    assert(c.parent == b);
}
