module mobamb.amb.domain;

private import mobamb.amb.tag;

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
    @property inout(Name) name() @safe nothrow pure inout;
}

/**
A Name is a Capaility that is attached to a symbolic binding within a Domain.
**/
interface Name : Capability {
    /**
    Returns:
      The domain within which the name is bound.
    **/
    @property inout(Domain) domain() @safe nothrow pure inout;
}

interface Channel {
  alias OnInput = void delegate (Capability i);
  bool void output(Capability o);
  override void input(OnInput o);
  bool inputAvailable();
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
}

/**
The computing environment available to any process.
**/
interface TypeEnvironment : Domain {
    ProcessDomain createProcessDomain(TypedProcess) const;
    /* void excercise(ProcessDomain,Capability); */
}

/**
A process with a type domain.
 **/
interface TypedProcess {
    @property inout(ProcessDomain) domain() @safe nothrow pure inout;
    /**
    An internal method called before evaluation to ensure the consistency
    of the process tree in memory.
    **/
    bool cleanup();
}

/**
A ProcessDomain represents the local domain of any particular process.
A process may have at most one process domain, and a process domain may
only be attached to a single process. This link is immutable.
**/
interface ProcessDomain : Domain {
    //@property inout(TypeEnvironment) environment() @safe nothrow pure inout;
    @property inout(ProcessDomain) parent() @safe nothrow pure inout;
    //bool capsMatch(Name n,Capability c);
    //void excercise(TypedProcess p,Capability c);
    //bool canExit(Name) const;
    //bool canEnter(Name);
    void enter(TypedProcess p);
    void exit(TypedProcess p);
    //TypedProcess[] match(Capability);
    //bool createTag(Tag.Apply f,Tag.Close c)(Capability);
    //bool createTag(T : TagPool._Tag)(Capability);
    //void input(const(Name),P);
    //Capability read(const(Name));

    /*bool output(const(Name),Capability o);
    void input(const(Name),OnInput o);
    bool inputAvailable(const(Name));*/
    Channel channel(const(Name)n);
}
