module mobamb.amb.domain;

private import mobamb.amb.tag;

interface Capability {
    bool matches(const(Name))const;
    Name getName();
    const(Name) getName() const;
}

interface Name : Capability {
    Domain getDomain();
}

interface Domain {
    const(Name) getName() const;
    bool isBound(const(Name)) const;
    bool isRestricted(const(Name)) const;
    bool isRestricted() const;
    //Name[] restrictions() const;
    //Name[] bindings() const;
    bool bind(const(Name),const(Capability));
    bool restrict(const(Name));
    const(Capability) reduce(const(Name)) const;
}

interface TypeEnvironment : Domain {
    TypeDomain createTypeDomain(Name,TypeDomain parent) const;
    void apply(TypeDomain,Capability);
}

interface TypedProcess {
    Name getName();
    TypeDomain localDomain();
    bool cleanup();
    Tag[] evolutions();
}

interface TypeDomain : Domain {
    const(TypeEnvironment) getEnvironment() const;
    TypeDomain getParent() const;
    //bool capsMatch(Name n,Capability c);
    void apply(TypedProcess p,Capability c);
    bool canExit(Name) const;
    bool canEnter(Name);
    void enter(TypedProcess p);
    void exit(TypedProcess p);
    TypedProcess[] match(Capability);
    Tag createTag(Tag.Apply f,Tag.Close c)();
}
