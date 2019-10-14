module mobamb.amb.domain;

/**
A Capability has a Name and can match another Capability.
**/
interface Capability {
    /**
    Params:
      name = the name to match against.
    Returns:
      true if the capabilty match passes.
    **/
    bool matches(const(Name))const;
    //@property const(Name) name() @safe nothrow pure const;
    @property inout(Name) name() @safe nothrow pure inout;
    string capType() @safe nothrow pure const;
}

/**
A Name is a Capaility that is attached to a symbolic binding within a Domain.
**/
interface Name : Capability {
    /**
    Returns:
      The domain within which the name is bound.
    **/
    @property inout(Name) domain() @safe nothrow pure inout;
}

interface Channel {
  alias OnInput = void delegate (Capability i);
  bool output(Capability o);
  bool input(OnInput o);
  bool inputAvailable();
  //@property const(Name) name() @safe nothrow pure const;
  @property const(Name) name() @safe nothrow pure const;
}

/**
A Domain is a group of bindings.
**/
interface Domain {
    @property inout(Name) name() @safe nothrow pure inout;
    bool isBound(const(Name)) const;
    bool isRestricted(const(Name)) const;
    bool isRestricted() const;
    //Name[] restrictions() const;
    //Name[] bindings() const;
    //bool bind(const(Name),const(Capability));
    //bool restrict(const(Name));
    inout(Capability) binding(const(Name)) inout;
    Domain binding(const(Name),Capability);
}

/**
The computing environment available to any process.
**/
interface TypeEnvironment : Domain {
//    ProcessDomain createProcessDomain(TypedProcess) const;
    /* void excercise(ProcessDomain,Capability); */
}

/**
Raw process.
**/

interface Process {
  @property inout(Name) name() @safe nothrow pure inout;
  @property inout(ProcessDomain) domain() @safe nothrow pure inout;
  /**
  An internal method called before evaluation to ensure the consistency
  of the process tree in memory.
  **/
  bool cleanup();
  /**
  Evaluate all capabilities including children.
  Returns:    true if a match was found. false otherwise.
  **/
  bool evaluateAll();

  void _enter(Name n);
  void _exit(Name n);
  void enter_(Name n);
  void exit_(Name n);
  void in_(Name n);
  void out_(Name n);
  void _in(Name n);
  void _out(Name n);

}

/**
A process with a type domain.
 **/
interface TypedProcess(DomainType : ProcessDomain) : Process {
    @property inout(DomainType) domain() @safe nothrow pure inout;
}

/**
A ProcessDomain represents the local domain of any particular process.
A process may have at most one process domain, and a process domain may
only be attached to a single process. This link is immutable.
**/
interface ProcessDomain : Domain {
    //@property inout(TypeEnvironment) environment() @safe nothrow pure inout;
    @property inout(ProcessDomain) parent() @safe nothrow pure inout;
    @property ProcessDomain parent(ProcessDomain d) @safe nothrow pure;
    @property inout(Process[]) children() @safe nothrow pure inout;
    @property inout(Process) process() @safe nothrow pure inout;

    //bool capsMatch(Name n,Capability c);
    //void excercise(TypedProcess p,Capability c);
    //bool canExit(Name) const;
    //bool canEnter(Name);
    //void enter(TypedProcess p);
    //void exit(TypedProcess p);

    bool output(Capability o);
    // read input from channel n using capabilty o.
    bool input(Capability o);
    bool inputAvailable(const(Name)n);

    void movingOut(ProcessDomain c);
    void movingIn(ProcessDomain c);


    Process getLocalAmbient();
    Process getParentAmbient();
    Process getHostAmbient();
    inout(ProcessDomain) getTypedDomain() inout;


    Channel channel(const(Name)n);

    inout(Capability) binding(const(Name)) inout;
    ProcessDomain binding(const(Name),Capability);

    inout(Name) resolve(inout(Name) n) inout;
    inout(Capability) resolveCaps(inout(Capability) _n) inout;

    static ProcessDomain _localDomain;

    static auto localDomain() {
      return _localDomain;
    }

    static auto localDomain(ProcessDomain d) {
      auto _d = _localDomain;
      _localDomain = d;
      return _d;
    }
}
